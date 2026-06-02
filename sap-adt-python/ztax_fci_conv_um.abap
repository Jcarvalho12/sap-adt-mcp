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
  gt_cons_espc  TYPE STANDARD TABLE OF ty_cons_espc,
  gt_item_unid  TYPE SORTED TABLE OF ty_item_unid
                     WITH NON-UNIQUE KEY cod_item,
  gt_stpo_meins TYPE SORTED TABLE OF ty_stpo_meins
                     WITH NON-UNIQUE KEY cod_item_comp,
  gt_alv        TYPE STANDARD TABLE OF ty_alv,
  gv_periodo_de  TYPE c LENGTH 8,
  gv_periodo_ate TYPE c LENGTH 8.

*----------------------------------------------------------------------*
* Tela de Seleção
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_empres TYPE /tmf/de_empresa OBLIGATORY,
    p_filial TYPE /tmf/de_filial  OBLIGATORY,
    p_period TYPE spmon           OBLIGATORY.
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

  PERFORM f_montar_periodo.
  PERFORM f_buscar_consumo_especifico.

  CHECK gt_cons_espc IS NOT INITIAL.

  PERFORM f_buscar_unid_item.
  PERFORM f_buscar_meins_stpo.
  PERFORM f_processar_conversao.

  IF p_exec = abap_true AND gt_alv IS NOT INITIAL.
    PERFORM f_gravar_shadow.
  ENDIF.

  PERFORM f_exibir_alv.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Form f_montar_periodo
*&---------------------------------------------------------------------*
FORM f_montar_periodo.

  DATA: lv_ano     TYPE n LENGTH 4,
        lv_mes     TYPE n LENGTH 2,
        lv_mes_i   TYPE i,
        lv_last_day TYPE sy-datum.

  lv_ano = p_period(4).
  lv_mes = p_period+4(2).

  CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
    EXPORTING
      day_in       = CONV sy-datum( |{ lv_ano }{ lv_mes }01| )
    IMPORTING
      end_of_month = lv_last_day.

  gv_periodo_ate = lv_last_day.

  lv_mes_i = lv_mes - 2.
  IF lv_mes_i <= 0.
    lv_mes_i = lv_mes_i + 12.
    lv_ano   = lv_ano - 1.
  ENDIF.
  lv_mes = lv_mes_i.

  gv_periodo_de = |{ lv_ano }{ lv_mes }01|.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_buscar_consumo_especifico
*&---------------------------------------------------------------------*
FORM f_buscar_consumo_especifico.

  DATA: lo_sql    TYPE REF TO cl_sql_statement,
        lo_result TYPE REF TO cl_sql_result_set,
        lv_query  TYPE string.

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
        |AND "DT_INI"  <= '{ gv_periodo_ate }' | &&
        |AND "DT_FIN"  >= '{ gv_periodo_de }' | &&
        |AND "PERDA"   >= 0|.

      lo_result = lo_sql->execute_query( lv_query ).
      lo_result->set_param_table( REF #( gt_cons_espc ) ).
      lo_result->next_package( ).
      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql).
      MESSAGE lx_sql->get_text( ) TYPE 'E'.
  ENDTRY.

  IF gt_cons_espc IS INITIAL.
    MESSAGE 'Nenhum registro na CONSUMO_ESPECIFICO para o período informado'
      TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
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
        |FROM "STPO" AS S | &&
        |WHERE S."MANDT"  = '{ sy-mandt }' | &&
        |  AND S."STLTY"  = 'M' | &&
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

    " Buscar MEINS da STPO (COD_ITEM_COMP = STPO-IDNRK)
    READ TABLE gt_stpo_meins ASSIGNING FIELD-SYMBOL(<fs_stpo>)
      WITH KEY cod_item_comp = <fs_ce>-cod_item_comp.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    " Buscar UNID_INV da ITEM
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

    " Montar registro ALV
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

    " Regra de conversão conforme EF
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
        " Tentativa genérica via função SAP
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
