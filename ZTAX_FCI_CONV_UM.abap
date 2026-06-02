*&---------------------------------------------------------------------*
*& Report ZTAX_FCI_CONV_UM
*&---------------------------------------------------------------------*
*& Pré-processamento FCI – Conversão de Unidade de Medida
*& Pacote: ZTAX_FCI_CONV | Request: TDDK901617
*&---------------------------------------------------------------------*
REPORT ztax_fci_conv_um.

*----------------------------------------------------------------------*
* Tipos
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_cons_espc,
    mandt         TYPE mandt,
    empresa       TYPE c LENGTH 4,
    filial        TYPE c LENGTH 4,
    centro        TYPE c LENGTH 4,
    cod_item      TYPE c LENGTH 60,
    cod_item_comp TYPE c LENGTH 60,
    dt_ini        TYPE c LENGTH 8,
    dt_fin        TYPE c LENGTH 8,
    qtd_comp      TYPE /tmf/de_dec_25_6,
    perda         TYPE /tmf/de_dec_25_6,
  END OF ty_cons_espc,

  BEGIN OF ty_item_unid,
    cod_item TYPE c LENGTH 60,
    unid_inv TYPE c LENGTH 6,
  END OF ty_item_unid,

  BEGIN OF ty_stpo_meins,
    cod_item_comp TYPE c LENGTH 60,
    meins         TYPE c LENGTH 6,
  END OF ty_stpo_meins,

  BEGIN OF ty_cfop,
    cfop_4 TYPE c LENGTH 4,
  END OF ty_cfop,

  BEGIN OF ty_cod_item,
    cod_item TYPE c LENGTH 60,
  END OF ty_cod_item,

  BEGIN OF ty_prod_saida,
    cod_item TYPE c LENGTH 60,
    centro   TYPE c LENGTH 4,
  END OF ty_prod_saida,

  BEGIN OF ty_alv,
    icon          TYPE icon_d,
    status        TYPE c LENGTH 30,
    empresa       TYPE c LENGTH 4,
    filial        TYPE c LENGTH 4,
    centro        TYPE c LENGTH 4,
    cod_item      TYPE c LENGTH 60,
    cod_item_comp TYPE c LENGTH 60,
    meins_stpo    TYPE c LENGTH 6,
    unid_inv_item TYPE c LENGTH 6,
    qtd_comp_orig TYPE /tmf/de_dec_25_6,
    qtd_comp_conv TYPE /tmf/de_dec_25_6,
    perda_orig    TYPE /tmf/de_dec_25_6,
    perda_conv    TYPE /tmf/de_dec_25_6,
    dt_ini        TYPE c LENGTH 8,
    dt_fin        TYPE c LENGTH 8,
  END OF ty_alv.

*----------------------------------------------------------------------*
* Dados Globais
*----------------------------------------------------------------------*
DATA:
  gt_cons_espc      TYPE STANDARD TABLE OF ty_cons_espc,
  gt_item_unid      TYPE SORTED TABLE OF ty_item_unid
                         WITH NON-UNIQUE KEY cod_item,
  gt_stpo_meins     TYPE SORTED TABLE OF ty_stpo_meins
                         WITH NON-UNIQUE KEY cod_item_comp,
  gt_cfop_sai       TYPE STANDARD TABLE OF ty_cfop,
  gt_cfop_ent       TYPE STANDARD TABLE OF ty_cfop,
  gt_prod_saida     TYPE STANDARD TABLE OF ty_prod_saida,
  gt_prod_entrada   TYPE STANDARD TABLE OF ty_cod_item,
  gt_alv            TYPE STANDARD TABLE OF ty_alv,
  gv_periodo_de     TYPE c LENGTH 8,
  gv_periodo_ate    TYPE c LENGTH 8,
  gv_cod_item       TYPE c LENGTH 60,
  gv_cod_item_comp  TYPE c LENGTH 60.

*----------------------------------------------------------------------*
* Tela de Seleção
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_empres TYPE /tmf/de_empresa OBLIGATORY,
    p_filial TYPE /tmf/de_filial  OBLIGATORY,
    p_period TYPE char6           OBLIGATORY.
  SELECT-OPTIONS:
    s_coditm FOR gv_cod_item     NO INTERVALS,
    s_codcmp FOR gv_cod_item_comp NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_simul RADIOBUTTON GROUP rb1 DEFAULT 'X',
    p_exec  RADIOBUTTON GROUP rb1.
SELECTION-SCREEN END OF BLOCK b02.

*----------------------------------------------------------------------*
INITIALIZATION.
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
START-OF-SELECTION.
*----------------------------------------------------------------------*

  IF p_exec = abap_true.
    DATA lv_answer TYPE c LENGTH 1.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Confirmação de Execução'
        text_question         = 'O modo EXECUÇÃO irá gravar dados na tabela shadow. Deseja continuar?'
        text_button_1         = 'Sim'
        icon_button_1         = 'ICON_OKAY'
        text_button_2         = 'Não'
        icon_button_2         = 'ICON_CANCEL'
        default_button        = '2'
        display_cancel_button = abap_false
      IMPORTING
        answer                = lv_answer.

    IF lv_answer <> '1'.
      MESSAGE 'Execução cancelada pelo usuário' TYPE 'S' DISPLAY LIKE 'W'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

  PERFORM f_montar_periodo.

  " 1) Buscar produtos com NF de saída no período (COD_ITEM + CENTRO)
  PERFORM f_buscar_cfop_saida.
  PERFORM f_buscar_produtos_saida.

  CHECK gt_prod_saida IS NOT INITIAL.

  " 2) Buscar nível 1 da CONSUMO_ESPECIFICO (somente por produtos de saída)
  PERFORM f_buscar_consumo_especifico.

  CHECK gt_cons_espc IS NOT INITIAL.

  " 3) Explosão da lista técnica - BOM (até 20 níveis)
  PERFORM f_explodir_bom.

  " 4) Filtro de notas de entrada
  PERFORM f_buscar_cfop_entrada.
  PERFORM f_buscar_produtos_entrada.

  CHECK gt_prod_entrada IS NOT INITIAL.

  PERFORM f_filtrar_por_notas_entrada.

  CHECK gt_cons_espc IS NOT INITIAL.

  " 5) Filtro MTORG: manter apenas insumos com origem importada
  PERFORM f_filtrar_por_mtorg_importado.

  CHECK gt_cons_espc IS NOT INITIAL.

  " 6) Conversão de unidade e gravação
  PERFORM f_buscar_unid_item.
  PERFORM f_buscar_meins_stpo.
  PERFORM f_processar_conversao.

  " 7) Verificar conversões anteriores na ZENG_PRE_FCI
  PERFORM f_verificar_conversao_anterior.

  IF p_exec = abap_true AND gt_alv IS NOT INITIAL.
    PERFORM f_gravar_shadow.
    PERFORM f_gravar_controle.
  ENDIF.

  PERFORM f_exibir_alv.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Form f_montar_periodo
*& Mesma lógica de /TAX/CL_CALCULO_FCI: retorna 2 meses e ambos
*& DE e ATE ficam no mesmo mês (mês-2).
*&---------------------------------------------------------------------*
FORM f_montar_periodo.

  DATA: lv_ano      TYPE n LENGTH 4,
        lv_mes      TYPE n LENGTH 2,
        lv_mes_i    TYPE i,
        lv_last_day TYPE sy-datum.

  lv_ano = p_period(4).
  lv_mes = p_period+4(2).

  lv_mes_i = lv_mes - 2.
  IF lv_mes_i <= 0.
    lv_mes_i = lv_mes_i + 12.
    lv_ano   = lv_ano - 1.
  ENDIF.
  lv_mes = lv_mes_i.

  gv_periodo_de = |{ lv_ano }{ lv_mes }01|.

  CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
    EXPORTING
      day_in       = CONV sy-datum( |{ lv_ano }{ lv_mes }01| )
    IMPORTING
      end_of_month = lv_last_day.

  gv_periodo_ate = lv_last_day.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_cfop_saida
*&---------------------------------------------------------------------*
FORM f_buscar_cfop_saida.

  DATA: lo_sql    TYPE REF TO cl_sql_statement,
        lo_result TYPE REF TO cl_sql_result_set,
        lv_query  TYPE string.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT DISTINCT LEFT("CFOP",4) AS "CFOP_4" | &&
        |FROM "_SYS_BIC"."engbr.smarttax.solutions.fci/CV_FCI_CES" | &&
        |WHERE "DIRECT" = '2'|.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( gt_cfop_sai ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_cfop_entrada
*&---------------------------------------------------------------------*
FORM f_buscar_cfop_entrada.

  DATA: lo_sql    TYPE REF TO cl_sql_statement,
        lo_result TYPE REF TO cl_sql_result_set,
        lv_query  TYPE string.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT DISTINCT LEFT("CFOP",4) AS "CFOP_4" | &&
        |FROM "_SYS_BIC"."engbr.smarttax.solutions.fci/CV_FCI_CES" | &&
        |WHERE "DIRECT" = '1'|.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( gt_cfop_ent ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_produtos_saida
*& Busca COD_ITEM + CENTRO dos produtos com NF de saída no período.
*& Mesma lógica de call_produtos_saida / FILTRO_PRODUTOS_SAIDA.
*&---------------------------------------------------------------------*
FORM f_buscar_produtos_saida.

  DATA: lo_sql     TYPE REF TO cl_sql_statement,
        lo_result  TYPE REF TO cl_sql_result_set,
        lv_query   TYPE string,
        lv_in_cfop TYPE string.

  LOOP AT gt_cfop_sai ASSIGNING FIELD-SYMBOL(<fs_cfop>).
    IF lv_in_cfop IS NOT INITIAL. lv_in_cfop = lv_in_cfop && |,|. ENDIF.
    lv_in_cfop = lv_in_cfop && |'{ <fs_cfop>-cfop_4 }'|.
  ENDLOOP.

  IF lv_in_cfop IS INITIAL.
    MESSAGE 'Nenhum CFOP de saída encontrado em /TAX/D_FCI_CES'
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT DISTINCT I."COD_ITEM", I."CENTRO" | &&
        |FROM "_SYS_BIC"."sap.glo.tmflocbr.ctr/NF_ITEM" AS I | &&
        |INNER JOIN "_SYS_BIC"."sap.glo.tmflocbr.ctr/NF_DOCUMENTO" AS N | &&
        |  ON  N."MANDT"   = I."MANDT" | &&
        |  AND N."EMPRESA" = I."EMPRESA" | &&
        |  AND N."FILIAL"  = I."FILIAL" | &&
        |  AND N."NF_ID"   = I."NF_ID" | &&
        |  AND N."DT_DOC"  = I."DT_DOC" | &&
        |  AND N."COD_MOD" = I."COD_MOD" | &&
        |  AND N."DT_E_S"  = I."DT_E_S" | &&
        |WHERE I."MANDT"    = '{ sy-mandt }' | &&
        |  AND I."EMPRESA"  = '{ p_empres }' | &&
        |  AND I."FILIAL"   = '{ p_filial }' | &&
        |  AND I."DIRECT"   = '2' | &&
        |  AND N."DT_DOC"   BETWEEN '{ gv_periodo_de }' AND '{ gv_periodo_ate }' | &&
        |  AND I."QTD"      > 0 | &&
        |  AND N."CANCELADO" = '' | &&
        |  AND N."SYS_TIPO_NF" NOT IN ('NFS','E2','J2','M2','N2','V2','V6') | &&
        |  AND LEFT(I."CFOP",4) IN ({ lv_in_cfop })|.

      IF s_coditm[] IS NOT INITIAL.
        DATA lv_in_coditm TYPE string.
        LOOP AT s_coditm ASSIGNING FIELD-SYMBOL(<fs_coditm>).
          IF lv_in_coditm IS NOT INITIAL.
            lv_in_coditm = lv_in_coditm && |,|.
          ENDIF.
          lv_in_coditm = lv_in_coditm && |'{ <fs_coditm>-low }'|.
        ENDLOOP.
        lv_query = lv_query && | AND I."COD_ITEM" IN ({ lv_in_coditm })|.
      ENDIF.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( gt_prod_saida ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

  IF gt_prod_saida IS INITIAL.
    MESSAGE 'Nenhum produto com nota de saída no período'
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ELSE.
    MESSAGE |{ lines( gt_prod_saida ) } produtos com nota de saída no período|
      TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_produtos_entrada
*& Busca COD_ITEM (insumos) com NF de entrada no período.
*&---------------------------------------------------------------------*
FORM f_buscar_produtos_entrada.

  DATA: lo_sql     TYPE REF TO cl_sql_statement,
        lo_result  TYPE REF TO cl_sql_result_set,
        lv_query   TYPE string,
        lv_in_cfop TYPE string.

  LOOP AT gt_cfop_ent ASSIGNING FIELD-SYMBOL(<fs_cfop>).
    IF lv_in_cfop IS NOT INITIAL. lv_in_cfop = lv_in_cfop && |,|. ENDIF.
    lv_in_cfop = lv_in_cfop && |'{ <fs_cfop>-cfop_4 }'|.
  ENDLOOP.

  IF lv_in_cfop IS INITIAL.
    MESSAGE 'Nenhum CFOP de entrada encontrado em /TAX/D_FCI_CES'
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT DISTINCT I."COD_ITEM" | &&
        |FROM "_SYS_BIC"."sap.glo.tmflocbr.ctr/NF_ITEM" AS I | &&
        |INNER JOIN "_SYS_BIC"."sap.glo.tmflocbr.ctr/NF_DOCUMENTO" AS N | &&
        |  ON  N."MANDT"   = I."MANDT" | &&
        |  AND N."EMPRESA" = I."EMPRESA" | &&
        |  AND N."FILIAL"  = I."FILIAL" | &&
        |  AND N."NF_ID"   = I."NF_ID" | &&
        |  AND N."DT_DOC"  = I."DT_DOC" | &&
        |  AND N."COD_MOD" = I."COD_MOD" | &&
        |  AND N."DT_E_S"  = I."DT_E_S" | &&
        |WHERE I."MANDT"    = '{ sy-mandt }' | &&
        |  AND I."EMPRESA"  = '{ p_empres }' | &&
        |  AND I."FILIAL"   = '{ p_filial }' | &&
        |  AND I."DIRECT"   = '1' | &&
        |  AND I."DT_E_S"   BETWEEN '{ gv_periodo_de }' AND '{ gv_periodo_ate }' | &&
        |  AND I."QTD"      > 0 | &&
        |  AND N."CANCELADO" = '' | &&
        |  AND N."SYS_TIPO_NF" NOT IN ('NFS','E2','J2','M2','N2','V2','V6') | &&
        |  AND LEFT(I."CFOP",4) IN ({ lv_in_cfop })|.

      IF s_codcmp[] IS NOT INITIAL.
        DATA lv_in_codcmp TYPE string.
        LOOP AT s_codcmp ASSIGNING FIELD-SYMBOL(<fs_codcmp>).
          IF lv_in_codcmp IS NOT INITIAL.
            lv_in_codcmp = lv_in_codcmp && |,|.
          ENDIF.
          lv_in_codcmp = lv_in_codcmp && |'{ <fs_codcmp>-low }'|.
        ENDLOOP.
        lv_query = lv_query && | AND I."COD_ITEM" IN ({ lv_in_codcmp })|.
      ENDIF.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( gt_prod_entrada ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

  IF gt_prod_entrada IS INITIAL.
    MESSAGE 'Nenhum insumo com nota de entrada no período'
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ELSE.
    MESSAGE |{ lines( gt_prod_entrada ) } insumos com nota de entrada no período|
      TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_consumo_especifico
*& Nível 1: busca CONSUMO_ESPECIFICO filtrado pelos produtos de saída
*& (COD_ITEM + CENTRO). Sem filtro de entrada - será aplicado após
*& a explosão da BOM.
*&---------------------------------------------------------------------*
FORM f_buscar_consumo_especifico.

  DATA: lo_sql    TYPE REF TO cl_sql_statement,
        lo_result TYPE REF TO cl_sql_result_set,
        lv_query  TYPE string.

  DATA lv_in_saida TYPE string.
  LOOP AT gt_prod_saida ASSIGNING FIELD-SYMBOL(<fs_sai>).
    IF lv_in_saida IS NOT INITIAL. lv_in_saida = lv_in_saida && |,|. ENDIF.
    lv_in_saida = lv_in_saida && |('{ <fs_sai>-cod_item }','{ <fs_sai>-centro }')|.
  ENDLOOP.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT "MANDT","EMPRESA","FILIAL","CENTRO",| &&
        |"COD_ITEM","COD_ITEM_COMP",| &&
        |"DT_INI","DT_FIN",| &&
        |"QTD_COMP","PERDA" | &&
        |FROM "_SYS_BIC"."sap.glo.tmflocbr.ctr/CONSUMO_ESPECIFICO" | &&
        |WHERE "MANDT"  = '{ sy-mandt }' | &&
        |AND "EMPRESA"  = '{ p_empres }' | &&
        |AND "FILIAL"   = '{ p_filial }' | &&
*        |AND "DT_INI"  <= '{ gv_periodo_ate }' | &&
*        |AND "DT_FIN"  >= '{ gv_periodo_de }' | &&
        |AND "PERDA"   >= 0 | &&
        |AND ("COD_ITEM","CENTRO") IN ({ lv_in_saida })|.

      IF s_codcmp[] IS NOT INITIAL.
        DATA(lv_in_codcmp) = VALUE string( ).
        LOOP AT s_codcmp ASSIGNING FIELD-SYMBOL(<fs_codcmp>).
          IF lv_in_codcmp IS NOT INITIAL.
            lv_in_codcmp = lv_in_codcmp && |,|.
          ENDIF.
          lv_in_codcmp = lv_in_codcmp && |'{ <fs_codcmp>-low }'|.
        ENDLOOP.
        lv_query = lv_query && | AND "COD_ITEM_COMP" IN ({ lv_in_codcmp })|.
      ENDIF.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( gt_cons_espc ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

  IF gt_cons_espc IS INITIAL.
    MESSAGE 'Nenhum registro na CONSUMO_ESPECIFICO para os produtos encontrados'
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ELSE.
    MESSAGE |Nível 1: { lines( gt_cons_espc ) } registros na CONSUMO_ESPECIFICO|
      TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_explodir_bom
*& Explosão recursiva da lista técnica (BOM) até 20 níveis.
*& Mesma lógica de /TAX/CL_CALCULO_FCI=>call_cons_especifico_avaliacao:
*&  - COD_ITEM_COMP do nível atual vira COD_ITEM do próximo nível
*&  - Mantém CENTRO na cadeia de busca
*&  - Protege contra referências circulares
*&---------------------------------------------------------------------*
FORM f_explodir_bom.

  DATA: lo_sql         TYPE REF TO cl_sql_statement,
        lo_result      TYPE REF TO cl_sql_result_set,
        lv_query       TYPE string,
        lt_nivel_novo  TYPE STANDARD TABLE OF ty_cons_espc,
        lt_nivel_atual TYPE STANDARD TABLE OF ty_cons_espc,
        lv_index       TYPE i VALUE 1,
        lv_in_pairs    TYPE string,
        lv_nivel1      TYPE i.

  lv_nivel1 = lines( gt_cons_espc ).
  lt_nivel_atual = gt_cons_espc.

  DATA lt_visitados TYPE HASHED TABLE OF ty_prod_saida
                    WITH UNIQUE KEY cod_item centro.

  LOOP AT gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs_v>).
    INSERT VALUE ty_prod_saida(
      cod_item = <fs_v>-cod_item
      centro   = <fs_v>-centro
    ) INTO TABLE lt_visitados.
  ENDLOOP.

  WHILE lv_index <= 20.
    lv_index = lv_index + 1.

    DATA lt_filtro TYPE HASHED TABLE OF ty_prod_saida
                   WITH UNIQUE KEY cod_item centro.
    CLEAR lt_filtro.

    LOOP AT lt_nivel_atual ASSIGNING FIELD-SYMBOL(<fs_n>).
      DATA(ls_par) = VALUE ty_prod_saida(
        cod_item = <fs_n>-cod_item_comp
        centro   = <fs_n>-centro
      ).
      READ TABLE lt_visitados WITH KEY cod_item = ls_par-cod_item
                                       centro   = ls_par-centro
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        INSERT ls_par INTO TABLE lt_filtro.
      ENDIF.
    ENDLOOP.

    IF lt_filtro IS INITIAL.
      EXIT.
    ENDIF.

    LOOP AT lt_filtro ASSIGNING FIELD-SYMBOL(<fs_f>).
      INSERT <fs_f> INTO TABLE lt_visitados.
    ENDLOOP.

    CLEAR lv_in_pairs.
    LOOP AT lt_filtro ASSIGNING FIELD-SYMBOL(<fs_p>).
      IF lv_in_pairs IS NOT INITIAL. lv_in_pairs = lv_in_pairs && |,|. ENDIF.
      lv_in_pairs = lv_in_pairs && |('{ <fs_p>-cod_item }','{ <fs_p>-centro }')|.
    ENDLOOP.

    TRY.
        lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

        lv_query =
          |SELECT "MANDT","EMPRESA","FILIAL","CENTRO",| &&
          |"COD_ITEM","COD_ITEM_COMP",| &&
          |"DT_INI","DT_FIN",| &&
          |"QTD_COMP","PERDA" | &&
          |FROM "_SYS_BIC"."sap.glo.tmflocbr.ctr/CONSUMO_ESPECIFICO" | &&
          |WHERE "MANDT"  = '{ sy-mandt }' | &&
          |AND "EMPRESA"  = '{ p_empres }' | &&
          |AND "FILIAL"   = '{ p_filial }' | &&
*          |AND "DT_INI"  <= '{ gv_periodo_ate }' | &&
*          |AND "DT_FIN"  >= '{ gv_periodo_de }' | &&
          |AND "PERDA"   >= 0 | &&
          |AND ("COD_ITEM","CENTRO") IN ({ lv_in_pairs })|.

        CLEAR lt_nivel_novo.
        lo_result = lo_sql->execute_query( lv_query ).
        lo_result->set_param_table( REF #( lt_nivel_novo ) ).
        lo_result->next_package( ).
        lo_result->close( ).

      CATCH cx_sql_exception INTO DATA(lx_sql).
        MESSAGE lx_sql->get_text( ) TYPE 'W'.
        EXIT.
    ENDTRY.

    IF lt_nivel_novo IS INITIAL.
      EXIT.
    ENDIF.

    APPEND LINES OF lt_nivel_novo TO gt_cons_espc.
    lt_nivel_atual = lt_nivel_novo.

  ENDWHILE.

  DATA(lv_niveis) = lv_index - 1.
  DATA(lv_bom)    = lines( gt_cons_espc ) - lv_nivel1.

  IF lv_bom > 0.
    MESSAGE |Explosão BOM: { lv_niveis } níveis, +{ lv_bom } registros ({ lines( gt_cons_espc ) } total)|
      TYPE 'S'.
  ELSE.
    MESSAGE |BOM: sem sub-níveis encontrados ({ lines( gt_cons_espc ) } registros)|
      TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_filtrar_por_notas_entrada
*& Após a explosão da BOM, filtra gt_cons_espc mantendo apenas
*& COD_ITEM_COMP que possuem notas de entrada no período.
*&---------------------------------------------------------------------*
FORM f_filtrar_por_notas_entrada.

  TYPES ty_cod TYPE c LENGTH 60.
  DATA lt_hash TYPE HASHED TABLE OF ty_cod WITH UNIQUE KEY table_line.

  LOOP AT gt_prod_entrada ASSIGNING FIELD-SYMBOL(<fs_ent>).
    INSERT <fs_ent>-cod_item INTO TABLE lt_hash.
  ENDLOOP.

  DATA(lv_antes) = lines( gt_cons_espc ).

  DATA lt_filtrado LIKE gt_cons_espc.
  LOOP AT gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs_ce>).
    READ TABLE lt_hash WITH KEY table_line = <fs_ce>-cod_item_comp
      TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      APPEND <fs_ce> TO lt_filtrado.
    ENDIF.
  ENDLOOP.
  gt_cons_espc = lt_filtrado.

  DATA(lv_removidos) = lv_antes - lines( gt_cons_espc ).

  IF gt_cons_espc IS INITIAL.
    MESSAGE |Nenhum insumo possui nota de entrada no período. { lv_removidos } descartados|
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ELSE.
    MESSAGE |Filtro entrada: { lv_removidos } descartados, { lines( gt_cons_espc ) } mantidos|
      TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_filtrar_por_mtorg_importado
*& Filtro MTORG: mantém apenas COD_ITEM_COMP com origem importada
*& na MBEW (MTORG IN '1','2','3','8').
*&---------------------------------------------------------------------*
FORM f_filtrar_por_mtorg_importado.

  DATA: lo_sql      TYPE REF TO cl_sql_statement,
        lo_result   TYPE REF TO cl_sql_result_set,
        lv_query    TYPE string,
        lt_cod_imp  TYPE STANDARD TABLE OF ty_cod_item,
        lv_in_comp  TYPE string,
        lv_antes    TYPE i.

  TYPES ty_cod TYPE c LENGTH 60.
  DATA lt_set TYPE HASHED TABLE OF ty_cod WITH UNIQUE KEY table_line.

  LOOP AT gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs>).
    INSERT <fs>-cod_item_comp INTO TABLE lt_set.
  ENDLOOP.

  LOOP AT lt_set ASSIGNING FIELD-SYMBOL(<c>).
    IF lv_in_comp IS NOT INITIAL. lv_in_comp = lv_in_comp && |,|. ENDIF.
    lv_in_comp = lv_in_comp && |'{ <c> }'|.
  ENDLOOP.

  CHECK lv_in_comp IS NOT INITIAL.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT DISTINCT M."MATNR" AS "COD_ITEM" | &&
        |FROM "_SYS_BIC"."engbr.smarttax.solutions.fci/CV_MBEW" AS M | &&
        |WHERE M."MANDT" = '{ sy-mandt }' | &&
        |  AND M."MTORG" IN ('1','2','3','8') | &&
        |  AND M."MATNR" IN ({ lv_in_comp })|.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( lt_cod_imp ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

  DATA lt_hash TYPE HASHED TABLE OF ty_cod WITH UNIQUE KEY table_line.
  LOOP AT lt_cod_imp ASSIGNING FIELD-SYMBOL(<fs_imp>).
    INSERT <fs_imp>-cod_item INTO TABLE lt_hash.
  ENDLOOP.

  lv_antes = lines( gt_cons_espc ).

  DATA lt_filtrado LIKE gt_cons_espc.
  LOOP AT gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs_ce>).
    READ TABLE lt_hash WITH KEY table_line = <fs_ce>-cod_item_comp
      TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      APPEND <fs_ce> TO lt_filtrado.
    ENDIF.
  ENDLOOP.
  gt_cons_espc = lt_filtrado.

  DATA(lv_removidos) = lv_antes - lines( gt_cons_espc ).

  IF gt_cons_espc IS INITIAL.
    MESSAGE |Nenhum insumo com origem importada. { lv_removidos } registros descartados|
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ELSE.
    MESSAGE |Filtro MTORG: { lv_removidos } descartados (nacionais), { lines( gt_cons_espc ) } mantidos|
      TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_unid_item
*&---------------------------------------------------------------------*
FORM f_buscar_unid_item.

  DATA: lo_sql    TYPE REF TO cl_sql_statement,
        lo_result TYPE REF TO cl_sql_result_set,
        lv_query  TYPE string,
        lt_tmp    TYPE STANDARD TABLE OF ty_item_unid,
        lv_in     TYPE string.

  TYPES ty_cod TYPE c LENGTH 60.
  DATA lt_set TYPE HASHED TABLE OF ty_cod WITH UNIQUE KEY table_line.

  LOOP AT gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs>).
    INSERT <fs>-cod_item_comp INTO TABLE lt_set.
  ENDLOOP.

  LOOP AT lt_set ASSIGNING FIELD-SYMBOL(<c>).
    IF lv_in IS NOT INITIAL.
      lv_in = lv_in && |,|.
    ENDIF.
    lv_in = lv_in && |'{ <c> }'|.
  ENDLOOP.

  CHECK lv_in IS NOT INITIAL.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT DISTINCT "COD_ITEM","UNID_INV" | &&
        |FROM "_SYS_BIC"."sap.glo.tmflocbr.ctr/ITEM" | &&
        |WHERE "COD_ITEM" IN ({ lv_in }) | &&
        |AND "EMPRESA" = '{ p_empres }' | &&
        |AND "UNID_INV" IN ('G','KG') | &&
        |AND "FILIAL"  = '{ p_filial }'|.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( lt_tmp ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

  gt_item_unid = lt_tmp.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_meins_stpo
*& Conforme EF: COD_ITEM_COMP = STPO-IDNRK → recuperar MEINS
*&---------------------------------------------------------------------*
FORM f_buscar_meins_stpo.

  DATA: lo_sql    TYPE REF TO cl_sql_statement,
        lo_result TYPE REF TO cl_sql_result_set,
        lv_query  TYPE string,
        lt_tmp    TYPE STANDARD TABLE OF ty_stpo_meins.

  TYPES ty_cod TYPE c LENGTH 60.
  DATA: lt_comps   TYPE HASHED TABLE OF ty_cod WITH UNIQUE KEY table_line,
        lv_in_comp TYPE string.

  LOOP AT gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs>).
    INSERT <fs>-cod_item_comp INTO TABLE lt_comps.
  ENDLOOP.

  LOOP AT lt_comps ASSIGNING FIELD-SYMBOL(<c>).
    IF lv_in_comp IS NOT INITIAL. lv_in_comp = lv_in_comp && |,|. ENDIF.
    lv_in_comp = lv_in_comp && |'{ <c> }'|.
  ENDLOOP.

  CHECK lv_in_comp IS NOT INITIAL.

  TRY.
      lo_sql = cl_sql_connection=>get_connection( )->create_statement( ).

      lv_query =
        |SELECT DISTINCT | &&
        |  S."IDNRK" AS "COD_ITEM_COMP", | &&
        |  S."MEINS" | &&
        |FROM "R20"."STPO" AS S | &&
        |WHERE S."MANDT"  = '{ sy-mandt }' | &&
        |  AND S."STLTY"  = 'M' | &&
        |  AND S."MEINS"  IN ('G','KG') | &&
        |  AND S."IDNRK" IN ({ lv_in_comp })|.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( lt_tmp ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'W'.
  ENDTRY.

  gt_stpo_meins = lt_tmp.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_processar_conversao
*&---------------------------------------------------------------------*
FORM f_processar_conversao.

  DATA: ls_alv       TYPE ty_alv,
        lv_meins     TYPE c LENGTH 6,
        lv_unid      TYPE c LENGTH 6.

  LOOP AT gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs_ce>).
    CLEAR ls_alv.

    READ TABLE gt_stpo_meins ASSIGNING FIELD-SYMBOL(<fs_stpo>)
      WITH KEY cod_item_comp = <fs_ce>-cod_item_comp.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    READ TABLE gt_item_unid ASSIGNING FIELD-SYMBOL(<fs_item>)
      WITH KEY cod_item = <fs_ce>-cod_item_comp.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_meins = condense( val = <fs_stpo>-meins ).
    lv_unid  = condense( val = <fs_item>-unid_inv ).

    IF lv_meins = lv_unid.
      CONTINUE.
    ENDIF.

    ls_alv-empresa       = <fs_ce>-empresa.
    ls_alv-filial        = <fs_ce>-filial.
    ls_alv-centro        = <fs_ce>-centro.
    ls_alv-cod_item      = <fs_ce>-cod_item.
    ls_alv-cod_item_comp = <fs_ce>-cod_item_comp.
    ls_alv-dt_ini        = <fs_ce>-dt_ini.
    ls_alv-dt_fin        = <fs_ce>-dt_fin.
    ls_alv-qtd_comp_orig = <fs_ce>-qtd_comp.
    ls_alv-perda_orig    = <fs_ce>-perda.
    ls_alv-meins_stpo    = lv_meins.
    ls_alv-unid_inv_item = lv_unid.

    CASE lv_meins.
      WHEN 'G'.
        IF lv_unid = 'KG'.
          ls_alv-qtd_comp_conv = <fs_ce>-qtd_comp / 1000.
          ls_alv-perda_conv    = COND #( WHEN <fs_ce>-perda > 0
                                         THEN <fs_ce>-perda / 1000
                                         ELSE 0 ).
          ls_alv-status = 'Convertido G → KG'.
          ls_alv-icon   = icon_led_green.
        ENDIF.

      WHEN 'KG'.
        IF lv_unid = 'G'.
          ls_alv-qtd_comp_conv = <fs_ce>-qtd_comp * 1000.
          ls_alv-perda_conv    = COND #( WHEN <fs_ce>-perda > 0
                                         THEN <fs_ce>-perda * 1000
                                         ELSE 0 ).
          ls_alv-status = 'Convertido KG → G'.
          ls_alv-icon   = icon_led_green.
        ENDIF.

      WHEN OTHERS.
        CALL FUNCTION 'UNIT_CONVERSION_SIMPLE'
          EXPORTING
            input    = <fs_ce>-qtd_comp
            unit_in  = CONV msehi( lv_meins )
            unit_out = CONV msehi( lv_unid )
          IMPORTING
            output   = ls_alv-qtd_comp_conv
          EXCEPTIONS
            conversion_not_found = 1
            division_by_zero     = 2
            input_invalid        = 3
            output_invalid       = 4
            overflow             = 5
            type_invalid         = 6
            units_missing        = 7
            unit_in_not_found    = 8
            unit_out_not_found   = 9
            OTHERS               = 10.

        IF sy-subrc = 0.
          IF <fs_ce>-perda > 0.
            CALL FUNCTION 'UNIT_CONVERSION_SIMPLE'
              EXPORTING
                input  = <fs_ce>-perda
                unit_in  = CONV msehi( lv_meins )
                unit_out = CONV msehi( lv_unid )
              IMPORTING
                output = ls_alv-perda_conv
              EXCEPTIONS
                OTHERS = 10.
          ENDIF.
          ls_alv-status = |Convertido { lv_meins } → { lv_unid }|.
          ls_alv-icon   = icon_led_green.
        ELSE.
          ls_alv-qtd_comp_conv = <fs_ce>-qtd_comp.
          ls_alv-perda_conv    = <fs_ce>-perda.
          ls_alv-status        = 'Conversão não encontrada'.
          ls_alv-icon          = icon_led_red.
        ENDIF.
    ENDCASE.

    IF ls_alv-icon IS NOT INITIAL.
      APPEND ls_alv TO gt_alv.
    ENDIF.

  ENDLOOP.

  IF gt_alv IS INITIAL.
    MESSAGE 'Nenhuma divergência de unidade de medida encontrada'
      TYPE 'S' DISPLAY LIKE 'I'.
  ELSE.
    MESSAGE |{ lines( gt_alv ) } registros com divergência de unidade encontrados|
      TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_verificar_conversao_anterior
*& Verifica na tabela ZENG_PRE_FCI se já existe conversão registrada
*& para os itens do ALV no período selecionado.
*& Registros já convertidos recebem ícone vermelho e não serão
*& regravados na shadow nem na tabela de controle.
*&---------------------------------------------------------------------*
FORM f_verificar_conversao_anterior.

  DATA lt_pre_fci TYPE STANDARD TABLE OF zeng_pre_fci.

  CHECK gt_alv IS NOT INITIAL.

  SELECT * FROM zeng_pre_fci
    INTO TABLE lt_pre_fci
    FOR ALL ENTRIES IN gt_alv
    WHERE mandt         = sy-mandt
      AND empresa       = gt_alv-empresa
      AND filial        = gt_alv-filial
      AND centro        = gt_alv-centro
      AND cod_item      = gt_alv-cod_item
      AND cod_item_comp = gt_alv-cod_item_comp
      AND dt_conv       BETWEEN gv_periodo_de AND gv_periodo_ate.

  CHECK lt_pre_fci IS NOT INITIAL.

  SORT lt_pre_fci BY empresa filial centro cod_item cod_item_comp.

  DATA lv_ja_conv TYPE i.

  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).
    READ TABLE lt_pre_fci TRANSPORTING NO FIELDS
      WITH KEY empresa       = <fs_alv>-empresa
               filial        = <fs_alv>-filial
               centro        = <fs_alv>-centro
               cod_item      = <fs_alv>-cod_item
               cod_item_comp = <fs_alv>-cod_item_comp
      BINARY SEARCH.

    IF sy-subrc = 0.
      <fs_alv>-icon   = icon_led_red.
      <fs_alv>-status = 'Já convertido anteriormente'.
      lv_ja_conv = lv_ja_conv + 1.
    ENDIF.
  ENDLOOP.

  IF lv_ja_conv > 0.
    MESSAGE |{ lv_ja_conv } registros já convertidos anteriormente (ZENG_PRE_FCI)|
      TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_gravar_shadow
*&---------------------------------------------------------------------*
FORM f_gravar_shadow.

  DATA: lt_shadow TYPE STANDARD TABLE OF /tmf/d_cons_espc,
        ls_shadow TYPE /tmf/d_cons_espc.

  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).
    CHECK <fs_alv>-icon = icon_led_green.

    READ TABLE gt_cons_espc ASSIGNING FIELD-SYMBOL(<fs_ce>)
      WITH KEY empresa       = <fs_alv>-empresa
               filial        = <fs_alv>-filial
               centro        = <fs_alv>-centro
               cod_item      = <fs_alv>-cod_item
               cod_item_comp = <fs_alv>-cod_item_comp
               dt_ini        = <fs_alv>-dt_ini
               dt_fin        = <fs_alv>-dt_fin.

    CHECK sy-subrc = 0.

    CLEAR ls_shadow.
    MOVE-CORRESPONDING <fs_ce> TO ls_shadow.
    ls_shadow-qtd_comp = <fs_alv>-qtd_comp_conv.
    ls_shadow-perda    = <fs_alv>-perda_conv.

    APPEND ls_shadow TO lt_shadow.
  ENDLOOP.

  IF lt_shadow IS NOT INITIAL.
    MODIFY /tmf/d_cons_espc FROM TABLE lt_shadow.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
      MESSAGE |{ lines( lt_shadow ) } registros gravados na shadow /TMF/D_CONS_ESPC|
        TYPE 'S'.
    ELSE.
      ROLLBACK WORK.
      MESSAGE 'Erro ao gravar na shadow /TMF/D_CONS_ESPC' TYPE 'E'.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_gravar_controle
*& Grava os registros convertidos com sucesso (ícone verde) na tabela
*& de controle ZENG_PRE_FCI para evitar reconversão futura.
*&---------------------------------------------------------------------*
FORM f_gravar_controle.

  DATA: lt_pre_fci TYPE STANDARD TABLE OF zeng_pre_fci,
        ls_pre_fci TYPE zeng_pre_fci.

  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).
    CHECK <fs_alv>-icon = icon_led_green.

    CLEAR ls_pre_fci.
    ls_pre_fci-mandt         = sy-mandt.
    ls_pre_fci-empresa       = <fs_alv>-empresa.
    ls_pre_fci-filial        = <fs_alv>-filial.
    ls_pre_fci-centro        = <fs_alv>-centro.
    ls_pre_fci-dt_conv       = sy-datum.
    ls_pre_fci-cod_item      = <fs_alv>-cod_item.
    ls_pre_fci-cod_item_comp = <fs_alv>-cod_item_comp.
    ls_pre_fci-unid_inv_con  = <fs_alv>-unid_inv_item.
    ls_pre_fci-vl_conv       = <fs_alv>-qtd_comp_conv.

    APPEND ls_pre_fci TO lt_pre_fci.
  ENDLOOP.

  IF lt_pre_fci IS NOT INITIAL.
    MODIFY zeng_pre_fci FROM TABLE lt_pre_fci.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
      MESSAGE |{ lines( lt_pre_fci ) } registros gravados na ZENG_PRE_FCI|
        TYPE 'S'.
    ELSE.
      ROLLBACK WORK.
      MESSAGE 'Erro ao gravar na ZENG_PRE_FCI' TYPE 'W'.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_exibir_alv
*&---------------------------------------------------------------------*
FORM f_exibir_alv.

  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column,
        lo_funcs   TYPE REF TO cl_salv_functions_list.

  IF gt_alv IS INITIAL.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = gt_alv ).

      lo_funcs = lo_alv->get_functions( ).
      lo_funcs->set_all( abap_true ).

      lo_columns = lo_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      DEFINE set_col_text.
        TRY.
            lo_column = lo_columns->get_column( &1 ).
            lo_column->set_short_text( &2 ).
            lo_column->set_medium_text( &3 ).
            lo_column->set_long_text( &4 ).
          CATCH cx_salv_not_found ##NO_HANDLER.
        ENDTRY.
      END-OF-DEFINITION.

      set_col_text 'ICON'          'Sts'       'Status'            'Status'.
      set_col_text 'STATUS'        'Desc.Sts'  'Descr.Status'      'Descrição do Status'.
      set_col_text 'EMPRESA'       'Empresa'   'Empresa'           'Empresa'.
      set_col_text 'FILIAL'        'Filial'    'Filial'            'Filial'.
      set_col_text 'CENTRO'        'Centro'    'Centro'            'Centro'.
      set_col_text 'COD_ITEM'      'Prod.Saí'  'Produto Saída'     'Código Produto Saída'.
      set_col_text 'COD_ITEM_COMP' 'Comp.'     'Componente'        'Código Item Componente'.
      set_col_text 'MEINS_STPO'    'UM STPO'   'Unid.Med.STPO'     'Unidade de Medida STPO'.
      set_col_text 'UNID_INV_ITEM' 'UM ITEM'   'Unid.Med.ITEM'     'Unidade de Medida ITEM'.
      set_col_text 'QTD_COMP_ORIG' 'Qtd Orig'  'Qtd.Comp Orig.'    'Quantidade Componente Original'.
      set_col_text 'QTD_COMP_CONV' 'Qtd Conv'  'Qtd.Comp Conv.'    'Quantidade Componente Convertida'.
      set_col_text 'PERDA_ORIG'    'Prd Orig'  'Perda Orig.'       'Perda Original'.
      set_col_text 'PERDA_CONV'    'Prd Conv'  'Perda Conv.'       'Perda Convertida'.
      set_col_text 'DT_INI'        'Dt.Ini'    'Data Início'       'Data Início Validade'.
      set_col_text 'DT_FIN'        'Dt.Fin'    'Data Fim'          'Data Fim Validade'.

      lo_alv->get_display_settings( )->set_list_header(
        'Pré-processamento FCI - Conversão Unidade de Medida' ).
      lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
  ENDTRY.

ENDFORM.
