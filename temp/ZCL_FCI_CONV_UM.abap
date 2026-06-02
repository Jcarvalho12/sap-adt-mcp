CLASS zcl_fci_conv_um DEFINITION
  PUBLIC
  INHERITING FROM /dpf/cl_webservice_wrap
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_cons_espc_item,
             mandt         TYPE char3,
             empresa       TYPE char4,
             filial        TYPE char4,
             cod_item      TYPE /tmf/de_cod_item,
             cod_item_comp TYPE /tmf/de_cod_item,
             qtd_comp      TYPE /tmf/de_dec_25_6,
             perda         TYPE /tmf/de_dec_25_6,
             meins_stpo    TYPE char6,
             unid_inv      TYPE char6,
             descr_item    TYPE c LENGTH 255,
           END OF ty_cons_espc_item,

           ty_t_cons_espc_item TYPE STANDARD TABLE OF ty_cons_espc_item WITH EMPTY KEY.

    TYPES: BEGIN OF ty_resumo_conversao,
             cod_item       TYPE /tmf/de_cod_item,
             descr_item     TYPE c LENGTH 255,
             meins_stpo     TYPE char6,
             unid_inv       TYPE char6,
             qtd_original   TYPE /tmf/de_dec_25_6,
             qtd_convertida TYPE /tmf/de_dec_25_6,
             fator          TYPE string,
             status         TYPE string,
           END OF ty_resumo_conversao,

           ty_t_resumo_conversao TYPE STANDARD TABLE OF ty_resumo_conversao WITH EMPTY KEY.

    TYPES: BEGIN OF ty_detalhe_conversao,
             cod_item       TYPE /tmf/de_cod_item,
             cod_item_comp  TYPE /tmf/de_cod_item,
             meins_stpo     TYPE char6,
             unid_inv       TYPE char6,
             qtd_comp_orig  TYPE /tmf/de_dec_25_6,
             qtd_comp_conv  TYPE /tmf/de_dec_25_6,
             perda_orig     TYPE /tmf/de_dec_25_6,
             perda_conv     TYPE /tmf/de_dec_25_6,
             fator          TYPE string,
           END OF ty_detalhe_conversao,

           ty_t_detalhe_conversao TYPE STANDARD TABLE OF ty_detalhe_conversao WITH EMPTY KEY.

    TYPES: BEGIN OF ty_retorno_cabecalho,
             empresa     TYPE string,
             filial      TYPE string,
             periodo_ref TYPE string,
             teste       TYPE string,
             status      TYPE string,
           END OF ty_retorno_cabecalho.

    TYPES: BEGIN OF ty_retorno_relatorios,
             resumo_conversao  TYPE ty_t_resumo_conversao,
             detalhe_conversao TYPE ty_t_detalhe_conversao,
           END OF ty_retorno_relatorios.

    TYPES: BEGIN OF ty_retorno,
             cabecalho    TYPE ty_retorno_cabecalho,
             relatorios   TYPE ty_retorno_relatorios,
             excel_gerado TYPE string,
             mensagem     TYPE string,
           END OF ty_retorno.

    METHODS constructor .
    METHODS executa_relatorio REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS converter_unidade
      IMPORTING
        iv_meins_stpo    TYPE char6
        iv_unid_inv      TYPE char6
        iv_valor         TYPE /tmf/de_dec_25_6
      EXPORTING
        ev_valor_conv    TYPE /tmf/de_dec_25_6
        ev_fator         TYPE string
        ev_convertido    TYPE abap_bool.

ENDCLASS.



CLASS zcl_fci_conv_um IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
  ENDMETHOD.


  METHOD executa_relatorio.

    DATA: p_json   TYPE flag,
          p_acao   TYPE string,
          p_mandt  TYPE mandt,
          p_bukrs  TYPE /tmf/de_empresa,
          p_branch TYPE /tmf/de_estabelecimento,
          p_concat TYPE c,
          p_mteste TYPE flag,
          s_date   TYPE RANGE OF datum,
          sw_date  LIKE LINE OF s_date,
          s_produ  TYPE RANGE OF /tmf/de_cod_part,
          sw_prod  LIKE LINE OF s_produ.

    FIELD-SYMBOLS: <fst_select_option> TYPE ANY TABLE,
                   <fs_select_option>  TYPE any,
                   <fs_parameter>      TYPE any.

    DATA wa_dref TYPE REF TO data.
    LOOP AT sel_screen INTO DATA(lw_sel_screen).
      IF lw_sel_screen-selname CP 'S_*'.
        ASSIGN (lw_sel_screen-selname) TO <fst_select_option>.
        IF sy-subrc IS INITIAL.
          CREATE DATA wa_dref LIKE LINE OF <fst_select_option>.
          ASSIGN wa_dref->* TO <fs_select_option>.
          MOVE-CORRESPONDING lw_sel_screen TO <fs_select_option>.
          INSERT <fs_select_option> INTO TABLE <fst_select_option>.
          UNASSIGN <fs_select_option>.
          DATA(lv_field_name) = lw_sel_screen-selname.
          REPLACE 'S_' IN lv_field_name WITH 'SW_'.
          ASSIGN (lv_field_name) TO <fs_select_option>.
          IF sy-subrc IS INITIAL.
            LOOP AT <fst_select_option>
              ASSIGNING FIELD-SYMBOL(<fs_first_line>).
              <fs_select_option> = <fs_first_line>.
              EXIT.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ELSE.
        ASSIGN (lw_sel_screen-selname) TO <fs_parameter>.
        IF sy-subrc IS INITIAL.
          <fs_parameter> = lw_sel_screen-low.
        ENDIF.
      ENDIF.
      FREE wa_dref.
    ENDLOOP.

    LOOP AT s_date INTO sw_date.
      IF sw_date-high IS NOT INITIAL
        AND sw_date-high <> '00000000'.
        CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
          EXPORTING
            day_in       = sw_date-high
          IMPORTING
            end_of_month = sw_date-high.
        MODIFY s_date FROM sw_date.
      ENDIF.
    ENDLOOP.

    " Calcular período 2 meses anteriores (mesma lógica da FCI)
    DATA: lv_mes_cons         TYPE char2,
          lv_ano_cons         TYPE char4,
          lv_mes_anterior_de  TYPE datum,
          lv_mes_anterior_ate TYPE datum.

    lv_mes_cons = sw_date-low+4(2).
    lv_ano_cons = sw_date-low+0(4).

    IF lv_mes_cons <= 2.
      lv_ano_cons = lv_ano_cons - 1.
      lv_mes_cons = lv_mes_cons + 12.
    ENDIF.

    lv_mes_cons = lv_mes_cons - 2.

    IF lv_mes_cons <= 9.
      lv_mes_cons = '0' && lv_mes_cons.
    ENDIF.

    lv_mes_anterior_de  = lv_ano_cons && lv_mes_cons && '01'.

    DATA(lv_temp_date) = CONV datum( lv_ano_cons && lv_mes_cons && '01' ).
    CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
      EXPORTING
        day_in       = lv_temp_date
      IMPORTING
        end_of_month = lv_mes_anterior_ate.

    " Ler dados da view CONSUMO_ESPECIFICO via /TMF/V_CONS_ESPC
    " com cruzamento da STPO (MEINS) e ITEM (UNID_INV)
    DATA: lt_cons_espc TYPE ty_t_cons_espc_item,
          ls_cons_espc TYPE ty_cons_espc_item.

    DATA(lo_db_select) = NEW /dpf/cl_db_select(
      iv_empresa = p_bukrs
      iv_filial  = p_branch
    ).

    DATA: lt_placeholder TYPE TABLE OF /dpf/cl_db_select=>mty_placeholder,
          lw_placeholder TYPE /dpf/cl_db_select=>mty_placeholder.

    lw_placeholder-name  = 'P_MANDT'.
    lw_placeholder-value = p_mandt.
    APPEND lw_placeholder TO lt_placeholder.

    lw_placeholder-name  = 'P_BUKRS'.
    lw_placeholder-value = p_bukrs.
    APPEND lw_placeholder TO lt_placeholder.

    IF p_branch IS NOT INITIAL.
      lw_placeholder-name  = 'P_BRANCH'.
      lw_placeholder-value = p_branch.
      APPEND lw_placeholder TO lt_placeholder.
    ENDIF.

    lw_placeholder-name  = 'P_DT_INI'.
    lw_placeholder-value = lv_mes_anterior_de.
    APPEND lw_placeholder TO lt_placeholder.

    lw_placeholder-name  = 'P_DT_FIN'.
    lw_placeholder-value = lv_mes_anterior_ate.
    APPEND lw_placeholder TO lt_placeholder.

    " Selecionar dados da shadow table
    DATA lt_shadow TYPE STANDARD TABLE OF /tmf/d_cons_espc.

    SELECT * FROM /tmf/d_cons_espc
      INTO TABLE lt_shadow
      WHERE mandt   = p_mandt
        AND empresa = p_bukrs.

    " Selecionar STPO para obter MEINS dos componentes
    DATA: BEGIN OF ls_stpo,
            idnrk TYPE stpo-idnrk,
            meins TYPE stpo-meins,
          END OF ls_stpo,
          lt_stpo LIKE TABLE OF ls_stpo.

    SELECT idnrk meins
      FROM stpo
      INTO TABLE lt_stpo
      WHERE stlty = 'M'.

    " Selecionar ITEM para obter UNID_INV
    DATA: BEGIN OF ls_item_um,
            cod_item TYPE /tmf/de_cod_item,
            unid_inv TYPE char6,
          END OF ls_item_um,
          lt_item_um LIKE TABLE OF ls_item_um.

    DATA lv_view_name TYPE /tmf/de_view_name.
    lv_view_name = 'ITEM'.

    " Buscar dados diretamente via SQL na shadow
    DATA: lt_resumo  TYPE ty_t_resumo_conversao,
          ls_resumo  TYPE ty_resumo_conversao,
          lt_detalhe TYPE ty_t_detalhe_conversao,
          ls_detalhe TYPE ty_detalhe_conversao.

    DATA: lv_valor_conv TYPE /tmf/de_dec_25_6,
          lv_fator      TYPE string,
          lv_convertido TYPE abap_bool,
          lv_total_conv TYPE i VALUE 0,
          lv_total_proc TYPE i VALUE 0.

    LOOP AT lt_shadow ASSIGNING FIELD-SYMBOL(<fs_shadow>).

      lv_total_proc = lv_total_proc + 1.

      " Buscar MEINS na STPO
      DATA(lv_meins) = VALUE char6( ).
      READ TABLE lt_stpo INTO ls_stpo
        WITH KEY idnrk = <fs_shadow>-cod_item_comp.
      IF sy-subrc = 0.
        lv_meins = ls_stpo-meins.
      ELSE.
        CONTINUE.
      ENDIF.

      " Buscar UNID_INV do item
      DATA(lv_unid_inv) = VALUE char6( ).
      lv_unid_inv = <fs_shadow>-unid_inv.

      IF lv_unid_inv IS INITIAL.
        CONTINUE.
      ENDIF.

      " Verificar se há divergência de UM
      DATA(lv_meins_upper) = to_upper( CONV string( lv_meins ) ).
      DATA(lv_unid_upper)  = to_upper( CONV string( lv_unid_inv ) ).

      IF lv_meins_upper = lv_unid_upper.
        CONTINUE.
      ENDIF.

      " Converter QTD_COMP
      me->converter_unidade(
        EXPORTING
          iv_meins_stpo = lv_meins
          iv_unid_inv   = lv_unid_inv
          iv_valor      = <fs_shadow>-qtd_comp
        IMPORTING
          ev_valor_conv = DATA(lv_qtd_conv)
          ev_fator      = lv_fator
          ev_convertido = lv_convertido
      ).

      IF lv_convertido = abap_false.
        CONTINUE.
      ENDIF.

      " Converter PERDA
      me->converter_unidade(
        EXPORTING
          iv_meins_stpo = lv_meins
          iv_unid_inv   = lv_unid_inv
          iv_valor      = <fs_shadow>-perda
        IMPORTING
          ev_valor_conv = DATA(lv_perda_conv)
          ev_fator      = lv_fator
          ev_convertido = lv_convertido
      ).

      lv_total_conv = lv_total_conv + 1.

      " Montar detalhe
      CLEAR ls_detalhe.
      ls_detalhe-cod_item      = <fs_shadow>-cod_item.
      ls_detalhe-cod_item_comp = <fs_shadow>-cod_item_comp.
      ls_detalhe-meins_stpo    = lv_meins.
      ls_detalhe-unid_inv      = lv_unid_inv.
      ls_detalhe-qtd_comp_orig = <fs_shadow>-qtd_comp.
      ls_detalhe-qtd_comp_conv = lv_qtd_conv.
      ls_detalhe-perda_orig    = <fs_shadow>-perda.
      ls_detalhe-perda_conv    = lv_perda_conv.
      ls_detalhe-fator         = lv_fator.
      APPEND ls_detalhe TO lt_detalhe.

      " Montar resumo (agrupar por material)
      READ TABLE lt_resumo ASSIGNING FIELD-SYMBOL(<fs_resumo>)
        WITH KEY cod_item = <fs_shadow>-cod_item_comp.
      IF sy-subrc IS NOT INITIAL.
        CLEAR ls_resumo.
        ls_resumo-cod_item       = <fs_shadow>-cod_item_comp.
        ls_resumo-meins_stpo     = lv_meins.
        ls_resumo-unid_inv       = lv_unid_inv.
        ls_resumo-qtd_original   = <fs_shadow>-qtd_comp.
        ls_resumo-qtd_convertida = lv_qtd_conv.
        ls_resumo-fator          = lv_fator.
        ls_resumo-status         = 'Convertido'.
        APPEND ls_resumo TO lt_resumo.
      ELSE.
        <fs_resumo>-qtd_original   = <fs_resumo>-qtd_original + <fs_shadow>-qtd_comp.
        <fs_resumo>-qtd_convertida = <fs_resumo>-qtd_convertida + lv_qtd_conv.
      ENDIF.

      " Gravar se não for modo teste
      IF p_acao = 'GRAVAR' AND p_mteste <> 'X'.
        <fs_shadow>-qtd_comp = lv_qtd_conv.
        <fs_shadow>-perda    = lv_perda_conv.
      ENDIF.

    ENDLOOP.

    " Gravar na shadow table
    IF p_acao = 'GRAVAR' AND p_mteste <> 'X'.
      MODIFY /tmf/d_cons_espc FROM TABLE lt_shadow.
      COMMIT WORK AND WAIT.
    ENDIF.

    " Montar retorno
    DATA lt_retorno TYPE ty_retorno.

    me->montar_cabecalho_auto(
      EXPORTING
        iv_empresa   = p_bukrs
        iv_filial    = p_branch
      IMPORTING
        et_cabecalho = DATA(et_cabecalho)
    ).

    lt_retorno-cabecalho-periodo_ref = sw_date-low+4(2) && '/' && sw_date-low+0(4).
    lt_retorno-cabecalho-empresa     = et_cabecalho-nome_estabelec.
    lt_retorno-cabecalho-filial      = p_branch.
    lt_retorno-cabecalho-teste       = p_mteste.

    IF p_acao = 'GRAVAR' AND p_mteste <> 'X'.
      lt_retorno-cabecalho-status = 'Gravado'.
      lt_retorno-mensagem = |{ lv_total_conv } registro(s) convertido(s) e gravado(s) na shadow /TMF/D_CONS_ESPC.|.
    ELSE.
      lt_retorno-cabecalho-status = 'Simulação'.
      lt_retorno-mensagem = |Simulação: { lv_total_conv } registro(s) com divergência de UM encontrado(s) de { lv_total_proc } processado(s).|.
    ENDIF.

    lt_retorno-relatorios-resumo_conversao  = lt_resumo.
    lt_retorno-relatorios-detalhe_conversao = lt_detalhe.

    " Retorno JSON
    IF p_json = 'X'.
      CREATE DATA eo_output_data LIKE lt_retorno.
      ASSIGN eo_output_data->* TO FIELD-SYMBOL(<ft_retorno>).
      <ft_retorno> = lt_retorno.
    ENDIF.

  ENDMETHOD.


  METHOD converter_unidade.

    DATA: lv_meins_upper TYPE string,
          lv_unid_upper  TYPE string.

    lv_meins_upper = to_upper( CONV string( iv_meins_stpo ) ).
    lv_unid_upper  = to_upper( CONV string( iv_unid_inv ) ).

    ev_convertido = abap_false.
    ev_valor_conv = iv_valor.
    ev_fator      = '1'.

    " G -> KG: dividir por 1000
    IF ( lv_meins_upper = 'G' OR lv_meins_upper = 'GRM' )
      AND ( lv_unid_upper = 'KG' OR lv_unid_upper = 'KGM' ).
      ev_valor_conv = iv_valor / 1000.
      ev_fator      = '/ 1000'.
      ev_convertido = abap_true.
      RETURN.
    ENDIF.

    " KG -> G: multiplicar por 1000
    IF ( lv_meins_upper = 'KG' OR lv_meins_upper = 'KGM' )
      AND ( lv_unid_upper = 'G' OR lv_unid_upper = 'GRM' ).
      ev_valor_conv = iv_valor * 1000.
      ev_fator      = '* 1000'.
      ev_convertido = abap_true.
      RETURN.
    ENDIF.

    " Para outras conversões, usar BAPI padrão SAP
    DATA: lv_output_qty TYPE p LENGTH 16 DECIMALS 6.

    CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
      EXPORTING
        i_matnr              = CONV matnr( space )
        i_in_me              = CONV meins( iv_meins_stpo )
        i_out_me             = CONV meins( iv_unid_inv )
        i_menge              = CONV menge_d( iv_valor )
      IMPORTING
        e_menge              = lv_output_qty
      EXCEPTIONS
        error_in_application = 1
        error                = 2
        OTHERS               = 3.

    IF sy-subrc = 0 AND lv_output_qty <> iv_valor.
      ev_valor_conv = lv_output_qty.
      ev_fator      = |{ iv_meins_stpo }->{ iv_unid_inv }|.
      ev_convertido = abap_true.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
