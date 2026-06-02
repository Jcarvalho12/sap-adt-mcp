class /DPF/CL_WEBSERVICE_WRAP definition
  public
  create public .

public section.

  interfaces IF_HTTP_EXTENSION .

  data MV_REPORT_ID type /TMF/DE_REPORT_ID .
  data MV_EXEC_ID type STRING .

  class-methods ENABLE_CORS
    importing
      !SERVER_INSTANCE type ref to IF_HTTP_SERVER optional .
  methods AUTHORITY_CHECK
    importing
      !IV_EMPRESA type /TMF/DE_EMPRESA default '*'
      !IV_FILIAL type /TMF/DE_FILIAL default '*'
      !IV_REPORT_ID type CHAR10 optional
      !IV_ACTVT type CHAR2 default '16'
      !IV_TABNAME type TABNAME default '*'
      !IV_FIELDNAME type FIELDNAME default '*'
      !IV_DUMMY type AB default '*'
      !IT_PARAMS type TIHTTPNVP optional
    returning
      value(R_SUBRC) type SYST_SUBRC .
  methods EXECUTA_PRE_PROCESSAMENTO
    importing
      !IV_VIEW_NAME type /TMF/DE_VIEW_NAME
      !IT_PLACEHOLDERS type /DPF/CL_DB_SELECT=>MTY_PLACEHOLDER_TABLE
      !IV_TABLE_NAME type STRING
      !IV_BUKRS type /TMF/DE_EMPRESA
      !IV_BRANCH type /TMF/DE_ESTABELECIMENTO
      !IV_NO_AUTO_MANDT type FLAG optional
      !IV_COLS type STRING optional
      !IV_WHERE type STRING optional
      !IV_RAW_COLUMNS type STRING optional
    raising
      CX_SQL_EXCEPTION
      /TMF/CX_REGISTER_EXCEPTION
      /DPF/CX_TEXT_MESSAGE
      CX_SHDB_EXCEPTION .
  methods EXECUTA_RELATORIO
    importing
      !SEL_SCREEN type /DPF/TT_RSPARAMS
      !I_RUN_ID type /TMF/DE_RUN_ID
      !IV_CACHE type FLAG optional
      !IT_PARAMS type TIHTTPNVP optional
    exporting
      value(EO_OUTPUT_DATA) type ref to DATA
    raising
      /DPF/CX_EXCEL
      /DPF/CX_TEXT_MESSAGE
      /TMF/CX_TOM_API
      /TMF/CX_API_SECURITY
      CX_SHDB_EXCEPTION
      /TMF/CX_REGISTER_EXCEPTION
      CX_SQL_EXCEPTION
      CX_UUID_ERROR
      CX_STATIC_CHECK
      CX_AMDP_EXECUTION_FAILED .
  methods EXECUTA_RELATORIO_AUTO
  final
    importing
      !SEL_SCREEN type /DPF/TT_RSPARAMS
      !I_RUN_ID type /TMF/DE_RUN_ID
      !IV_CACHE type FLAG optional
    exporting
      value(EO_OUTPUT_DATA) type ref to DATA
    raising
      /TMF/CX_REGISTER_EXCEPTION .
  methods SUBMIT_JOB
    importing
      !IV_SEL_SCREEN type STRING
      !IV_NOMEJOB type TBTCJOB-JOBNAME
      !I_RUN_ID type /TMF/DE_RUN_ID
      !IV_EMPRESA type /TMF/DE_EMPRESA
      !IV_FILIAL type /TMF/DE_FILIAL
      !IV_PERDE type /TMF/DE_DT_E_S
      !IV_PERATE type /TMF/DE_DT_E_S
    exporting
      !EV_JOBCOUNT type TBTCJOB-JOBCOUNT
    returning
      value(RO_REPORT_RUN) type ref to /TMF/CL_TOM_REPORT_RUN
    raising
      /TMF/CX_TOM_LOG
      /TMF/CX_SPED_JOB
      CX_LAW_LOG
      /TMF/CX_TMF_MISSING_PARAMETERS
      /TMF/CX_API_SECURITY
      CX_UUID_ERROR
      /TMF/CX_NO_AUTHORITY
      /TMF/CX_NO_SPED_VERSION .
  methods VERIFICAR_EMPRESA_FILIAL
    importing
      !IT_PARAMS type TIHTTPNVP
    returning
      value(R_SUBRC) type SYST_SUBRC .
protected section.

  data SERVER type ref to IF_HTTP_SERVER .

  methods GET_DT_HR_CSV
    importing
      !IT_SEL_SCREEN type /DPF/TT_RSPARAMS
    exporting
      !EV_CSV_DT type TBTCJOB-SDLSTRTDT
      !EV_CSV_HR type TBTCJOB-SDLSTRTTM .
  methods TO_JSON
    importing
      !I_DATA type DATA
      !I_NO_RESPONSE type FLAG optional
      !I_HTTP_STATUS type INT4 default 200
      !I_REASON_TEXT type STRING default 'OK'
      !I_ID_EXEC type CSEQUENCE optional
    exporting
      !EV_JSON type STRING .
  methods DO_DELETE
    importing
      !IT_PARAMS type TIHTTPNVP .
  methods DO_GET
    importing
      !IT_PARAMS type TIHTTPNVP .
  methods DO_POST
    importing
      !IT_PARAMS type TIHTTPNVP
    raising
      CX_UUID_ERROR .
  methods DO_POST_AUTO
  final
    importing
      !IT_PARAMS type TIHTTPNVP
    exporting
      !EO_REPORT_RUN type ref to /TMF/CL_TOM_REPORT_RUN
    raising
      CX_UUID_ERROR .
  methods DO_PUT
    importing
      !IT_PARAMS type TIHTTPNVP .
  methods GET_ATTACHMENT
    importing
      !IV_MANDT type SY-MANDT
      !IV_REPORT_ID type /TMF/DE_REPORT_ID
      !IV_EMPRESA type /TMF/DE_EMPRESA optional
      !IV_ATTACHMENT_ID type SYSUUID_C32 optional
      !IV_FILENAME type LOCALFILE optional
    returning
      value(RT_ATTACHMENT) type /DPF/TT_ATTACHMENT .
  methods GET_FISCAL_PERIOD_STATUS
    importing
      !IV_BUKRS type /TMF/DE_EMPRESA
      !IV_BRANCH type /TMF/DE_ESTABELECIMENTO
      !IV_ANO type GJAHR
      !IV_MES type MONAT
    exporting
      !EV_STATUS type /TMF/DE_FISCPER_STATUS_TO
      !EV_STATUS_TEXT type VAL_TEXT
    raising
      /TMF/CX_FISCAL_PERIOD_STATUS
      /TMF/CX_NO_AUTHORITY
      CX_LAW_LOG .
  methods GET_MANDT_TDF
    importing
      !IV_EMPRESA type /TMF/DE_EMPRESA
      !IV_FILIAL type /TMF/DE_FILIAL
    returning
      value(RV_MANDT_TDF) type MANDT .
  methods JSON_TO_SEL_SCREEN
    importing
      !IT_PARAMS type TIHTTPNVP
    returning
      value(RT_SEL_SCREEN) type /DPF/TT_RSPARAMS .
  methods MONTAR_CABECALHO_AUTO
    importing
      !IV_EMPRESA type /TMF/DE_EMPRESA
      !IV_FILIAL type /TMF/DE_FILIAL
    exporting
      !ET_CABECALHO type /TMF/V_EMP_FED .
  methods RESPONSE_FROM_REPORT_RUN
    importing
      !IO_REPORT_RUN type ref to /TMF/CL_TOM_REPORT_RUN
    exporting
      !EV_FILE_URL type STRING
    raising
      /TMF/CX_TOM_API
      /TMF/CX_API_SECURITY .
  methods SAVE_ATTACHMENT
    importing
      !IV_MANDT type SY-MANDT
      !IV_REPORT_ID type /TMF/DE_REPORT_ID
      !IV_EMPRESA type /TMF/DE_EMPRESA
      !IV_FILENAME type LOCALFILE
      !IV_FILE_TYPE type FILETYPE
      !IV_HEX_DATA type RSRSTRING
      !IV_DESCRICAO type /DPF/ATTACHMENT-DESCRICAO optional
    returning
      value(RV_ATTACHMENT_ID) type SYSUUID_C32
    raising
      CX_UUID_ERROR .
  methods TRAVAR_PERIODO_CHECK
    importing
      !IT_PARAMS type TIHTTPNVP
    exporting
      !EV_MESSAGE type STRING
    returning
      value(R_SUBRC) type SYST_SUBRC
    raising
      /TMF/CX_REGISTER_EXCEPTION
      /DPF/CX_TEXT_MESSAGE
      CX_SHDB_EXCEPTION
      CX_SQL_EXCEPTION .
  methods VERIFICAR_AGENDAMENTO
    importing
      !IT_SEL_SCREEN type /DPF/TT_RSPARAMS
    returning
      value(RV_AGENDAR) type CHAR1 .
  methods VERIFICA_PERIODO_FISCAL_ABERTO
    importing
      !IV_EMPRESA type /TMF/DE_EMPRESA
      !IV_FILIAL type /TMF/DE_ESTABELECIMENTO
      !IV_ANO type CHAR4
      !IV_MES type CHAR2
    exporting
      !EV_COD_STATUS type /TMF/DE_FISCPER_STATUS_TO
      !EV_DESC_STATUS type VAL_TEXT
      !EV_PERIODO_FISCAL_ABERTO type FLAG
    raising
      CX_LAW_LOG
      /TMF/CX_NO_AUTHORITY
      /TMF/CX_FISCAL_PERIOD_STATUS .
  PRIVATE SECTION.

    METHODS verificar_confluence
      EXPORTING
        !eo_data TYPE REF TO data .
ENDCLASS.



CLASS /DPF/CL_WEBSERVICE_WRAP IMPLEMENTATION.


  METHOD authority_check.

    TYPES: BEGIN OF ty_empresa,
             empresa TYPE /tmf/de_empresa,
           END OF ty_empresa.

    DATA: lt_empresa TYPE STANDARD TABLE OF ty_empresa.

    DATA: sel_screen      TYPE /dpf/tt_rsparams,
          s_bukrs         TYPE RANGE OF /tmf/de_empresa,
          sw_bukrs        LIKE LINE OF s_bukrs,
          p_bukrs         TYPE /tmf/de_empresa,
          p_branch        TYPE /tmf/de_estabelecimento,
          p_report_id(50) TYPE c,
          p_actvt(2)      TYPE c,
          s_branch        TYPE RANGE OF /tmf/de_estabelecimento,
          sw_branch       LIKE LINE OF s_branch,
          lv_field_name   TYPE string,
          p_tabn(40)      TYPE c,
          p_field(40)     TYPE c,
          p_dummy         TYPE ab.

    DATA : wa_dref TYPE REF TO data.

    "Verificando se deve pular os authority check

    SELECT COUNT(*)                                     "#EC CI_NOFIELD
                  FROM /dpf/hosts
                  WHERE no_auth_check = 'X'.
    IF sy-subrc IS INITIAL.
      CLEAR r_subrc.
      RETURN.
    ENDIF.

    IF it_params IS INITIAL.
      IF iv_empresa = '' OR iv_empresa = '*'.
        AUTHORITY-CHECK OBJECT '/DPF/AUTH1'
           "ID '/TMF/EMPR'  FIELD iv_empresa
           "ID '/TMF/FILI'  FIELD iv_filial
           ID '/TMF/REPID' FIELD iv_report_id
           ID 'ACTVT'      FIELD iv_actvt
           ID '/DPF/TABN'  FIELD iv_tabname
           ID '/DPF/FIELD' FIELD iv_fieldname
           ID 'DUMMY'      FIELD iv_dummy(40).
        r_subrc = sy-subrc.
      ELSE.
        AUTHORITY-CHECK OBJECT '/DPF/AUTH1'
           ID '/TMF/EMPR'  FIELD iv_empresa
           "ID '/TMF/FILI'  FIELD iv_filial
           ID '/TMF/REPID' FIELD iv_report_id
           ID 'ACTVT'      FIELD iv_actvt
           ID '/DPF/TABN'  FIELD iv_tabname
           ID '/DPF/FIELD' FIELD iv_fieldname
           ID 'DUMMY'      FIELD iv_dummy(40).
        r_subrc = sy-subrc.
      ENDIF.
      IF p_dummy EQ 'HIDE'.
        SELECT COUNT(*) FROM
            /dpf/v_field_per ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
          WHERE
            report_id = @iv_report_id AND
            field =  @iv_fieldname AND
            permission = 'D'.
        IF sy-subrc IS INITIAL.
          r_subrc = 4.
          RETURN.
        ENDIF.
      ENDIF.
    ELSE.

      FIELD-SYMBOLS:
        <fst_select_option> TYPE ANY TABLE,
        <fs_select_option>  TYPE any,
        <fs_parameter>      TYPE any,
        <fst_output>        TYPE ANY TABLE ##NEEDED.

      "--------------------------------------------------------------------------------------------------
      " Converter parâmetros da tela para o formato abap
      "--------------------------------------------------------------------------------------------------
      sel_screen = me->json_to_sel_screen( it_params ).

      LOOP AT sel_screen INTO DATA(lw_sel_screen).
        IF lw_sel_screen-selname CP 'S_*'. "Select options
          ASSIGN (lw_sel_screen-selname) TO <fst_select_option>.
          IF sy-subrc IS INITIAL.
            CREATE DATA wa_dref LIKE LINE OF <fst_select_option>.
            ASSIGN wa_dref->* TO <fs_select_option>.
            MOVE-CORRESPONDING lw_sel_screen TO <fs_select_option>.
            INSERT <fs_select_option> INTO TABLE <fst_select_option>.
            UNASSIGN <fs_select_option>.
            lv_field_name   = lw_sel_screen-selname .
            REPLACE 'S_' IN lv_field_name WITH 'SW_' .
            ASSIGN (lv_field_name) TO <fs_select_option>.
            IF sy-subrc IS INITIAL.
              "Read table nao funciona para tipos genericos
              LOOP AT <fst_select_option>
                ASSIGNING FIELD-SYMBOL(<fs_first_line>).
                <fs_select_option> = <fs_first_line>.
                EXIT.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ELSE. " PARAMETER
          ASSIGN (lw_sel_screen-selname) TO <fs_parameter> .
          IF sy-subrc IS INITIAL.
            <fs_parameter> = lw_sel_screen-low.
          ENDIF.
        ENDIF.
        FREE: wa_dref.
      ENDLOOP.
      p_report_id = server->request->get_form_field('P_REPORT_ID') ."Campo tinha mais que 8 posições
      REPLACE ALL OCCURRENCES OF |'| IN  p_report_id  WITH ''.
      REPLACE ALL OCCURRENCES OF |"| IN  p_report_id  WITH ''.

      "--------------------------------------------------------------------------------------------------
      "Authority check para todas as empresas / filiais
      "--------------------------------------------------------------------------------------------------
      IF s_bukrs[] IS INITIAL AND p_bukrs IS NOT INITIAL.
        sw_bukrs-low = p_bukrs.
        sw_bukrs-sign = 'I'.
        sw_bukrs-option = 'EQ'.
        APPEND sw_bukrs TO s_bukrs.
        CLEAR sw_bukrs.
      ENDIF.

      IF s_bukrs[] IS INITIAL.  "Verifica autorização sem Empresa

        AUTHORITY-CHECK OBJECT '/DPF/AUTH1'
          ID '/TMF/REPID' FIELD p_report_id(40)
          ID 'ACTVT'      FIELD '16'
          ID '/DPF/TABN'  FIELD p_tabn
          ID '/DPF/FIELD' FIELD p_field
          ID 'DUMMY'      FIELD p_dummy(40).

        r_subrc = sy-subrc.
        IF r_subrc IS NOT INITIAL.
          RETURN.
        ELSE.
          IF p_dummy EQ 'HIDE'.
            SELECT COUNT(*) FROM
                /dpf/v_field_per ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
              WHERE
                report_id = @p_report_id AND
                field =  @p_field AND
                permission = 'D'.
            IF sy-subrc IS INITIAL.
              r_subrc = 4.
              RETURN.
            ENDIF.
          ENDIF.
        ENDIF.

      ELSE.                   "Verifica autorização com Empresa

        SELECT empresa
          FROM /tmf/d_cnpj_root CLIENT SPECIFIED
          INTO TABLE lt_empresa
         WHERE empresa IN s_bukrs
           AND vig_de  <= sy-datlo
           AND vig_ate >= sy-datlo.

        LOOP AT lt_empresa ASSIGNING FIELD-SYMBOL(<fs_empresa>).
          AUTHORITY-CHECK OBJECT '/DPF/AUTH1'
            ID '/TMF/EMPR'  FIELD <fs_empresa>-empresa
            ID '/TMF/REPID' FIELD p_report_id(40)
            ID 'ACTVT'      FIELD '16'
            ID '/DPF/TABN'  FIELD p_tabn
            ID '/DPF/FIELD' FIELD p_field
            ID 'DUMMY'      FIELD p_dummy(40).

          r_subrc = sy-subrc.
          IF r_subrc IS NOT INITIAL.
            RETURN.
          ELSE.
            IF p_dummy EQ 'HIDE'.
              SELECT COUNT(*) FROM
                  /dpf/v_field_per ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
                WHERE
                  report_id = @p_report_id AND
                  field =  @p_field AND
                  permission = 'D'.
              IF sy-subrc IS INITIAL.
                r_subrc = 4.
                RETURN.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.

      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD do_delete ##NEEDED.
  ENDMETHOD.


  METHOD do_get ##NEEDED.
  ENDMETHOD.


  METHOD do_post ##NEEDED.

  ENDMETHOD.


  METHOD do_post_auto.

    DATA: lw_sel_screen          TYPE /dpf/st_rsparams,
          lw_reponse             TYPE /dpf/st_tom_response ##NEEDED,
          lv_run_id              TYPE /tmf/de_run_id,
          p_empresa              TYPE /tmf/de_empresa,
          p_filial               TYPE /tmf/de_filial,
          p_perde                TYPE /tmf/de_dt_e_s,
          p_perate               TYPE /tmf/de_dt_e_s,
          lo_data                TYPE REF TO data,
          lw_cpdkey              TYPE seocpdkey,
          lw_method_details      TYPE seoo_method_details,
          lv_erro_max_job        TYPE c LENGTH 5000,
          lv_erro_empresa_filial TYPE flag,
          lv_cache               TYPE flag,
          lt_headers             TYPE tihttpnvp.

    FIELD-SYMBOLS: <fs_output> TYPE any.

    DATA(lt_sel_screen) = me->json_to_sel_screen( it_params ).

    READ TABLE lt_sel_screen WITH KEY selname = 'P_BUKRS'  INTO DATA(lw_sel_screen_bukrs).
    READ TABLE lt_sel_screen WITH KEY selname = 'P_BRANCH' INTO DATA(lw_sel_screen_branch).
    READ TABLE lt_sel_screen WITH KEY selname = 'S_BUKRS'  INTO DATA(lw_sel_screen_sbukrs).
    READ TABLE lt_sel_screen WITH KEY selname = 'S_BRANCH' INTO DATA(lw_sel_screen_sbranch).
    READ TABLE lt_sel_screen WITH KEY selname = 'P_REPID'  INTO DATA(lw_sel_repid).
    READ TABLE lt_sel_screen WITH KEY selname = 'S_DATE'   INTO DATA(lw_sel_screen_sdate).

    p_empresa = lw_sel_screen_bukrs-low.
    p_filial  = lw_sel_screen_branch-low.
    p_perde   = lw_sel_screen_sdate-low.
    p_perate  = lw_sel_screen_sdate-high.

    IF p_empresa IS INITIAL.
      p_empresa = lw_sel_screen_sbukrs-low.
    ENDIF.

    IF p_filial IS INITIAL.
      p_filial = lw_sel_screen_sbranch-low.
    ENDIF.

    READ TABLE lt_sel_screen WITH KEY selname = 'P_ARQTOM' INTO DATA(lw_sel_screen_arq).
    READ TABLE lt_sel_screen WITH KEY selname = 'P_CSVTOM' INTO DATA(lw_sel_screen_csv).
    READ TABLE lt_sel_screen WITH KEY selname = 'P_PDFTOM' INTO DATA(lw_sel_screen_pdf).

    IF me->mv_report_id IS  INITIAL.
      me->mv_report_id = lw_sel_repid-low.
    ENDIF.

    "ID da execução
    READ TABLE lt_sel_screen WITH KEY selname = 'P_EXECID' INTO DATA(lw_sel_screen_execid).

    IF sy-subrc = 0.
      me->mv_exec_id = lw_sel_screen_execid-low .
      REPLACE ALL OCCURRENCES OF '"' IN me->mv_exec_id WITH ''.
    ELSE.
      me->mv_exec_id = cl_system_uuid=>create_uuid_c32_static( ).
    ENDIF.

    "Filtro executado na coluna da tabela (na tela)
    READ TABLE lt_sel_screen WITH KEY selname = 'P_FILTER' INTO DATA(lw_sel_screen_filter).

    IF sy-subrc = 0.
      DATA(lv_filter) = lw_sel_screen_filter-low.
    ELSE.
      CLEAR lv_filter.
    ENDIF.

    "Wander - 28.07.2022 - Inclusao da opção de buscar o link do confluence
    TRY.
        DATA(lv_verificar_confluence) = lt_sel_screen[ selname = 'P_CONFLU' ]-low.
      CATCH cx_sy_itab_line_not_found.
        CLEAR lv_verificar_confluence.
    ENDTRY.

    "Guardar ID da execução e filtros para serem utilizado nos casos de leitura
    "de cache de tabelas
    DATA(lo_cache) = /dpf/cl_cache=>get_instance( ).

    lo_cache->set_exec_id(
      EXPORTING
        iv_exec_id = me->mv_exec_id
    ).

    lo_cache->set_filter(
      EXPORTING
        iv_filter = lv_filter
    ).

    "Tratamento do cache - O parametro P_CACHE não pode ficar global na classe do cache
    "Ele tem que ser passado como parametro em cada ponto onde ele precisa ser utilizado
    "Neste caso ele é enviado automaticamente para o EXECUTA_RELATORIO e o desenvolvedor
    "decide se quer utilizar ou não
    READ TABLE lt_sel_screen WITH KEY selname = 'P_CACHE' INTO DATA(lw_sel_screen_cache).

    IF sy-subrc = 0.
      REPLACE ALL OCCURRENCES OF '"' IN lw_sel_screen_cache-low WITH ''.
      TRANSLATE lw_sel_screen_cache-low TO UPPER CASE.
      IF lw_sel_screen_cache-low = 'NULL'.
        CLEAR lw_sel_screen_cache-low.
      ENDIF.
      lv_cache = lw_sel_screen_cache-low .
    ELSE.
      CLEAR lv_cache.
    ENDIF.

    TRY.

        "------------------------------------------------
        " Geração em background (com ou sem agendamento
        "------------------------------------------------
        IF ( lw_sel_screen_pdf-low = abap_true
          OR lw_sel_screen_csv-low = abap_true
          OR lw_sel_screen_arq-low = abap_true )
          AND me->mv_report_id IS NOT INITIAL.

          SELECT SINGLE report_name
            INTO @DATA(lv_report_name)
            FROM /tmf/d_rep_fisc
           WHERE report_id = @me->mv_report_id.

          IF sy-subrc IS NOT INITIAL.
            DATA(lv_msg_text) = |REPORT ID não existe na tabela /TMF/D_REP_FISC: | && me->mv_report_id.

            "MESSAGE e026(/tmf/sped) WITH 'REPORT ID INVALIDO' lw_sel_repid-low space space.
            RAISE EXCEPTION TYPE /tmf/cx_register_exception
              EXPORTING
                error_code     = '008'
                error_message  = CONV #( lv_msg_text )
                internal_error = sy-subrc.
          ENDIF.

          "=============================================================
          "Verificar se houve agendamento do job (Quando o usuário clica
          "no botão EXCEL ainda na PRIMEIRA tela
          "=============================================================
          DATA(lv_agendar) = me->verificar_agendamento(
            EXPORTING
              it_sel_screen = lt_sel_screen
          ).

          "Se não for agendamento utilizar o método novo de escalonar e disparar
          "o job. Utiliza o programa standard /TMF/JOB_EXECUTER e outras classes
          "de controle
          IF lv_agendar = abap_false.

            " Convertenr dados para JSON
            me->to_json(
              EXPORTING
                i_data        = lt_sel_screen
                i_no_response = 'X'
              IMPORTING
                ev_json       = DATA(lv_sel_screen)
            ).

            " Escalonar e gerenciar a execução do job
            eo_report_run = me->submit_job(
              EXPORTING
                iv_sel_screen = lv_sel_screen
                i_run_id      = lv_run_id
                iv_empresa    = p_empresa
                iv_filial     = p_filial
                iv_perde      = p_perde
                iv_perate     = p_perate
                iv_nomejob    = |SMARTTAX 4 | && lv_report_name
            ).

          ELSE.
            "Se for job agendado, manter a forma anterior de execução do job

            "Criar instância do TOM
            eo_report_run = /dpf/cl_tom_integration=>create_or_running(
              EXPORTING
                i_empresa       = p_empresa
                i_filial        = p_filial
                i_periodo_ini   = p_perde
                i_periodo_fin   = p_perate
                i_create_status = /tmf/cl_constants=>mo_tom->report_status-scheduled
                i_report_id     = me->mv_report_id
            ).

            lv_run_id = eo_report_run->get_run_id( ).

            "Informando execução do TOM ao report para que o mesmo atualize o status
            CLEAR lw_sel_screen.
            lw_sel_screen-selname = 'P_RUN_ID'.
            lw_sel_screen-kind    = 'P'.
            lw_sel_screen-option  = 'EQ'.
            lw_sel_screen-sign    = 'I'.
            lw_sel_screen-low     = lv_run_id.
            APPEND lw_sel_screen TO lt_sel_screen.

            "--------------------------------------------------
            " Converter dados pra JSON
            "--------------------------------------------------
            me->to_json(
              EXPORTING
                i_data        = lt_sel_screen
                i_no_response = abap_true
              IMPORTING
                ev_json       = lv_sel_screen
            ).

            me->submit_job(
              EXPORTING
                iv_sel_screen = lv_sel_screen
                i_run_id      = lv_run_id
                iv_empresa    = p_empresa
                iv_filial     = p_filial
                iv_perde      = p_perde
                iv_perate     = p_perate
                iv_nomejob    = |SMARTTAX | && lv_report_name
              IMPORTING
                ev_jobcount   = DATA(lv_jobcount)
            ).

            eo_report_run->set_jobcount( iv_jobcount = lv_jobcount ).

          ENDIF.

        ELSE.

          "------------------------------------------------
          " Execução online
          "------------------------------------------------

          "Wander - 28.07.2022 - Se for opção do confluence deve apenas retornar o
          "link. Não é necessário chamar o executa_relatorio
          IF lv_verificar_confluence = abap_true.

            me->verificar_confluence(
              IMPORTING
                eo_data = lo_data
            ).

          ELSE.

            "Verificando se existe uma implementação específica do EXECUTA_RELATÓRIO ou se
            "pode usar a implementação automágica
            DATA(lv_cls_name) = cl_abap_classdescr=>get_class_name( me ).

            REPLACE ALL OCCURRENCES OF '\CLASS=' IN lv_cls_name WITH ''.
            lw_cpdkey-clsname = lv_cls_name.
            lw_cpdkey-cpdname = 'EXECUTA_RELATORIO'.

            CALL FUNCTION 'SEO_METHOD_GET_DETAIL'
              EXPORTING
                cpdkey         = lw_cpdkey
              IMPORTING
                method_details = lw_method_details.

            IF lw_method_details-is_redefined = abap_true.

              TRY .
                  IF me->verificar_empresa_filial(
                      EXPORTING
                        it_params = it_params
                    ) = 0.

                    CLEAR lv_erro_empresa_filial.
                  ELSE.
                    lv_erro_empresa_filial = abap_true.
                  ENDIF.

                CATCH cx_root INTO DATA(lo_exception).
                  me->to_json(
                    i_data        = lo_exception->get_text( )
                    i_http_status = 500
                  ).

                  lv_erro_empresa_filial = abap_true.
              ENDTRY.

              IF lv_erro_empresa_filial IS INITIAL.
                me->executa_relatorio(
                  EXPORTING
                    sel_screen     = lt_sel_screen
                    i_run_id       = lv_run_id
                    iv_cache       = lv_cache
                    it_params      = it_params
                  IMPORTING
                    eo_output_data = lo_data
                ).
              ENDIF.

            ELSE.
              me->executa_relatorio_auto(
                EXPORTING
                  sel_screen     = lt_sel_screen
                  i_run_id       = lv_run_id
                  iv_cache       = lv_cache
                IMPORTING
                  eo_output_data = lo_data
              ).
            ENDIF.

          ENDIF.

        ENDIF.

        IF lv_erro_empresa_filial IS INITIAL.

          READ TABLE lt_sel_screen WITH KEY selname = 'P_JSON' INTO lw_sel_screen.

          IF sy-subrc = 0 AND lw_sel_screen-low = 'X'.
            ASSIGN lo_data->* TO <fs_output>.
            me->to_json( i_data = <fs_output> ).
          ELSE.
            me->response_from_report_run( eo_report_run ).
          ENDIF.

        ELSE.

          me->to_json(
            EXPORTING
              i_data        = 'Não foi possível verificar os dados informados de empresa e filial!'
              i_http_status = '500'
              i_reason_text = 'ERROR'
          ).

        ENDIF.

      CATCH cx_root INTO DATA(lo_root) ##CATCH_ALL.
        DATA(lv_mensagens) = /dpf/cl_text_exception=>get_text( lo_root ).

        TRY.
            "Adicionar a mensagem de erro no LOG do tom
            DATA(lo_tom_log) = /tmf/cl_tom_log=>get_instance( ).

            IF lo_tom_log IS NOT INITIAL
              AND lo_tom_log IS BOUND
              AND eo_report_run IS NOT INITIAL
              AND eo_report_run IS BOUND.

              lo_tom_log->log_general_error(
                EXPORTING
                  iv_run_id       = eo_report_run->get_run_id( )
                  iv_msg_text     = CONV #( lv_mensagens )
              ).

            ENDIF.

          CATCH cx_root INTO DATA(lo_root_aux) ##CATCH_ALL.
            "Não é necessário tratar neste caso
        ENDTRY.

        me->to_json(
          EXPORTING
            i_data        = lv_mensagens
            i_http_status = '500'
            i_reason_text = 'ERROR'
        ).
    ENDTRY.

  ENDMETHOD.


  METHOD do_put ##NEEDED.
  ENDMETHOD.


  METHOD enable_cors.

    DATA: lt_headers         TYPE tihttpnvp,
          lw_headers         TYPE ihttpnvp,
          lv_allowed_headers TYPE ihttpnvp-value.

    server_instance->response->set_header_field(
      EXPORTING
        name  = 'Access-Control-Allow-Origin' ##NO_TEXT
        value = '*'
    ).

    server_instance->response->set_header_field(
      EXPORTING
        name  = 'Access-Control-Allow-Methods' ##NO_TEXT
        value = 'GET, POST, PATCH, PUT, DELETE, OPTIONS'
    ).

    "Request Headers
    server_instance->request->get_header_fields(
      CHANGING
        fields = lt_headers
    ).

    lv_allowed_headers = 'authorization,' ##NO_TEXT.
    READ TABLE lt_headers WITH KEY name = 'X-DPFISC-ID' TRANSPORTING NO FIELDS.

    IF sy-subrc IS NOT INITIAL.
      lw_headers-name = 'X-DPFISC-ID'.
      APPEND lw_headers TO lt_headers.
      lw_headers-name = 'X-DPFISC-UNAME'.
      APPEND lw_headers TO lt_headers.
      lw_headers-name = 'X-DPFISC-MANDT'.
      APPEND lw_headers TO lt_headers.
      lw_headers-name = 'X-DPFISC-FILENAME'.
      APPEND lw_headers TO lt_headers.
      lw_headers-name = 'X-DPFISC-ATTACHPARM'.
      APPEND lw_headers TO lt_headers.
    ENDIF.

    LOOP AT lt_headers  ASSIGNING FIELD-SYMBOL(<fs_header>).
      lv_allowed_headers = lv_allowed_headers && <fs_header>-name && ','.
    ENDLOOP.

    SHIFT lv_allowed_headers RIGHT BY 1 PLACES.

    DATA(lv_request) = server_instance->request->get_header_field(
      EXPORTING
        name = 'Access-Control-Request-Headers'
    ).

    lv_allowed_headers = lv_allowed_headers && lv_request.

    server_instance->response->set_header_field(
      name  = 'Access-Control-Allow-Headers' ##NO_TEXT
      value = lv_allowed_headers
    ).

    server_instance->response->set_header_field(
      name  = 'Access-Control-Allow-Credentials' ##NO_TEXT
      value = 'true'
    ).

    "Expor o exec-id. Número randômico necessário para o cache
    server_instance->response->set_header_field(
      name  = 'Access-Control-Expose-Headers' ##NO_TEXT
      value = 'exec-id'
    ).

    RETURN.
  ENDMETHOD.


  METHOD executa_pre_processamento.

    DATA: lv_sql         TYPE string,
          lv_fields      TYPE /dpf/cl_db_select=>my_table_fields,
          lt_output_data TYPE REF TO data ##NEEDED.

    DATA(lo_db_select) = NEW /dpf/cl_db_select(
      iv_empresa = iv_bukrs
      iv_filial  = iv_branch
    ).

    IF iv_cols IS INITIAL.
      "Caso não tenha passado iv_columns vai prevalecer os nomes dos campos da tabela a ser atualizada.
      lo_db_select->select_fields(
        EXPORTING
          iv_view_name = iv_table_name
        IMPORTING
          et_fields    = lv_fields
       ).
    ENDIF.

    lo_db_select->select_builder(
      EXPORTING
        iv_view_name     = iv_view_name
        it_placeholders  = it_placeholders
        iv_report_id     = me->mv_report_id
        iv_no_auto_mandt = iv_no_auto_mandt
        iv_columns       = iv_cols
        iv_where         = iv_where
        iv_raw_columns   = iv_raw_columns
      IMPORTING
        ev_sql           = lv_sql
        eo_output_data   = lt_output_data
      CHANGING
        iv_fields        = lv_fields
    ).

    DATA(lo_db_insert) = NEW /dpf/cl_db_insert( ).

    DATA(lv_upsert_sql) = lo_db_insert->upsert_from_select(
      EXPORTING
        iv_empresa       = iv_bukrs
        iv_filial        = iv_branch
        iv_select_clause = lv_sql
        iv_table_name    = iv_table_name
        iv_report_id     = me->mv_report_id
        iv_fields        = lv_fields
    ).

    lo_db_insert->execute_query(
      EXPORTING
        iv_sql = lv_upsert_sql
    ).

  ENDMETHOD.


  METHOD executa_relatorio.

    TYPES: ty_placeholder       TYPE STANDARD TABLE OF /dpf/cl_db_select=>mty_placeholder WITH EMPTY KEY.

    "--------------------------------------------------------------------------------------------------
    " Parâmetros da tela
    "--------------------------------------------------------------------------------------------------
    DATA: p_mandt  TYPE mandt, ".....................Obrigatório
          p_bukrs  TYPE /tmf/de_empresa, "...........Obrigatório
          s_branch  TYPE RANGE OF /tmf/de_estabelecimento, "...Obrigatório
          sw_branch LIKE LINE OF s_branch,
          s_date   TYPE RANGE OF datum, "............Obrigatório
          sw_date  LIKE LINE OF s_date, "............Obrigatório
          s_doc     TYPE RANGE OF /tmf/de_nf_id,
          sw_doc    LIKE LINE OF s_doc,
          p_tp_apu  TYPE flag,
          p_no_arq  TYPE string,
          p_tp_arq  TYPE char1.

    "--------------------------------------------------------------------------------------------------
    " Parâmetros auxiliares
    "--------------------------------------------------------------------------------------------------
    DATA:
      p_arqtom TYPE flag, "....................Retorna Arquivo pelo TOM.
      p_json   TYPE flag. "....................Retorna JSON

    "--------------------------------------------------------------------------------------------------
    " Converter os parâmetros de entrada do formato RSPARAM para o
    " formato abap
    "--------------------------------------------------------------------------------------------------
    DATA: lw_placeholder TYPE /dpf/cl_db_select=>mty_placeholder,
          lt_placeholder TYPE TABLE OF /dpf/cl_db_select=>mty_placeholder,
          lv_field_name  TYPE string,
          wa_dref        TYPE REF TO data.

    FIELD-SYMBOLS: <fst_select_option> TYPE ANY TABLE,
                   <fs_select_option>  TYPE any,
                   <fs_parameter>      TYPE any.

    LOOP AT sel_screen
      INTO DATA(lw_sel_screen).

      IF lw_sel_screen-selname CP 'S_*'.
        ASSIGN (lw_sel_screen-selname) TO <fst_select_option>.
        IF sy-subrc IS INITIAL.
          CREATE DATA wa_dref LIKE LINE OF <fst_select_option>.
          ASSIGN wa_dref->* TO <fs_select_option>.
          MOVE-CORRESPONDING lw_sel_screen TO <fs_select_option>.
          INSERT <fs_select_option> INTO TABLE <fst_select_option>.
          UNASSIGN <fs_select_option>.
          lv_field_name   = lw_sel_screen-selname .
          REPLACE 'S_' IN lv_field_name WITH 'SW_' .
          ASSIGN (lv_field_name) TO <fs_select_option>.
          IF sy-subrc IS INITIAL.
            "Read table nao funciona para tipos genericos
            LOOP AT <fst_select_option>
              ASSIGNING FIELD-SYMBOL(<fs_first_line>).
              <fs_select_option> = <fs_first_line>.
              EXIT.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ELSE. " PARAMETER
        ASSIGN (lw_sel_screen-selname) TO <fs_parameter> .
        IF sy-subrc IS INITIAL.
          <fs_parameter> = lw_sel_screen-low.
        ENDIF.
      ENDIF.

      FREE: wa_dref.
    ENDLOOP.

    "--------------------------------------------------------------------------------------------------
    " Popula WHERE ou PLACEHOLDER (Z_WANDER VERSION)
    "--------------------------------------------------------------------------------------------------
    APPEND LINES OF VALUE ty_placeholder(
      ( placeholder_name = 'P_MANDT'
        value            = p_mandt )
      ( placeholder_name = 'P_EMPRESA'
        value            = p_bukrs )
      ( placeholder_name = 'P_FILIAL'
        value = cl_shdb_seltab=>combine_seltabs(
                                                  it_named_seltabs =  VALUE #(     ( name = 'FILIAL' dref = REF #( s_branch[] ) )     )
                                                )
       )
      ( placeholder_name = 'P_PERIODO_DE'
        value            = sw_date-low )
      ( placeholder_name = 'P_PERIODO_ATE'
        value            = sw_date-high )
      ( placeholder_name = 'P_DOC_DE'
        value            = cl_shdb_seltab=>combine_seltabs(
                                                  it_named_seltabs =  VALUE #(     ( name = 'NF_ID' dref = REF #( s_branch[] ) )     )
                                                )
      )

      ( placeholder_name = 'P_TP_APU'
        value            = p_tp_apu )
      ( placeholder_name = 'P_NO_ARQ'
        value            = p_no_arq )
      ( placeholder_name = 'P_TP_ARQ'
        value            = p_tp_arq )

    ) TO lt_placeholder.

    DATA(lo_db_select) = NEW /dpf/cl_db_select(
        iv_empresa = p_bukrs
        iv_filial  = sw_branch-low
    ).
    DATA: lv_sql         TYPE string,
          lt_output_data TYPE REF TO data,
          lt_arquivo     TYPE TABLE OF string.

    "--------------------------------------------------------------------------------------------------
    " EXECUTA FUNÇÕES
    "--------------------------------------------------------------------------------------------------
    CASE abap_true.
      WHEN p_json.
      WHEN p_arqtom.
      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.


  METHOD executa_relatorio_auto.

    DATA(lv_msg_text) = 'NÃO IMPLEMENTADO'.

    MESSAGE e026(/tmf/sped) WITH lv_msg_text space space space.

    RAISE EXCEPTION TYPE /tmf/cx_register_exception
      EXPORTING
        error_code     = '008'
        error_message  = CONV #( lv_msg_text )
        internal_error = sy-subrc.

  ENDMETHOD.


  METHOD get_attachment.

    TYPES: ty_r_attachment_id TYPE RANGE OF sysuuid_c32,
           ty_r_empresa       TYPE RANGE OF /tmf/de_empresa,
           ty_r_filename      TYPE RANGE OF localfile.

    DATA: lt_r_attachment_id TYPE ty_r_attachment_id,
          lt_r_empresa       TYPE ty_r_empresa,
          lt_r_filename      TYPE ty_r_filename.

    CLEAR rt_attachment.

    "Montar range de ID anexo, se informado
    IF iv_attachment_id IS NOT INITIAL.
      APPEND VALUE #(
          sign   = 'I'
          option = 'EQ'
          low    = iv_attachment_id
      ) TO lt_r_attachment_id.
    ENDIF.

    "Montar range de empresa, se informada
    IF iv_empresa IS NOT INITIAL.
      APPEND VALUE #(
          sign   = 'I'
          option = 'EQ'
          low    = iv_empresa
      ) TO lt_r_empresa.
    ENDIF.

    "Montar range de nome do arquivo se informado
    IF iv_filename IS NOT INITIAL.
      APPEND VALUE #(
          sign   = 'I'
          option = 'EQ'
          low    = iv_filename
      ) TO lt_r_filename.
    ENDIF.

    "Selecionar anexos
    SELECT *
      FROM /dpf/attachment CLIENT SPECIFIED
     WHERE mandt          = @iv_mandt
       AND report_id     =  @iv_report_id
       AND empresa       IN @lt_r_empresa
       AND attachment_id IN @lt_r_attachment_id
       AND filename      IN @lt_r_filename
     ORDER BY filename, att_date, att_time
      INTO TABLE @rt_attachment.

    IF sy-subrc <> 0.
      CLEAR rt_attachment.
    ENDIF.

  ENDMETHOD.


  METHOD get_dt_hr_csv.

    LOOP AT it_sel_screen ASSIGNING FIELD-SYMBOL(<fs_sel_screen>).
      IF <fs_sel_screen>-selname EQ 'P_CSV_DT'.
        ev_csv_dt = <fs_sel_screen>-low.
      ELSEIF <fs_sel_screen>-selname EQ 'P_CSV_HR'.
        ev_csv_hr = <fs_sel_screen>-low.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_fiscal_period_status.

    DATA(lo_fiscal_period) = NEW /tmf/cl_fiscal_period_service(
      iv_bukrs  = iv_bukrs
      iv_branch = iv_branch
    ).

    TRY .
        lo_fiscal_period->get_status_static(
          EXPORTING
            iv_burks       = iv_bukrs    " Company Code
            iv_branch      = iv_branch   " Business Place
            iv_gjahr       = iv_ano    " Fiscal Year
            iv_monat       = iv_mes    " Fiscal period
          IMPORTING
            ev_status      = ev_status   " Fiscal Period Status
            ev_status_text = ev_status_text "Fiscal Period Status Text
        ).

      CATCH /tmf/cx_fiscal_period_status INTO DATA(lo_excpt).
        DATA(lo_compare_expt) = NEW /tmf/cx_fiscal_period_status(
          textid = /tmf/cx_fiscal_period_status=>error_status_not_found
        ).

        IF lo_excpt->get_text( ) EQ lo_compare_expt->get_text( ).
          CLEAR ev_status.
          ev_status_text = |Nenhum status definido para o período.|.
        ELSE.
          RAISE EXCEPTION lo_excpt.
        ENDIF.
    ENDTRY.

  ENDMETHOD.


  METHOD get_mandt_tdf.

    CLEAR rv_mandt_tdf.

    IF iv_filial IS NOT INITIAL.

      SELECT mandt_tdf
        FROM /tmf/d_sys_inf
          UP TO 1 ROWS
        INTO rv_mandt_tdf
       WHERE bukrs = iv_empresa
         AND branch = iv_filial.
      ENDSELECT.

    ELSE.

      SELECT mandt_tdf
        FROM /tmf/d_sys_inf
          UP TO 1 ROWS
        INTO rv_mandt_tdf
       WHERE bukrs = iv_empresa .
      ENDSELECT.

    ENDIF.

  ENDMETHOD.


  METHOD if_http_extension~handle_request.

    " Internal table
    " Variables
    DATA: l_rc   TYPE i ##NEEDED,
          l_json TYPE string ##NEEDED.

    " Variables
    DATA: l_verb      TYPE string,
          l_path_info TYPE string,
          l_resource  TYPE string ##NEEDED,
          l_param_1   TYPE string ##NEEDED,
          l_param_2   TYPE string ##NEEDED.

    " Retrieving the parameters
    DATA: lt_params          TYPE tihttpnvp.

    server->request->get_form_fields(
      CHANGING
         fields = lt_params
     ).

    me->server = server.

    " Retrieving the request method (POST, GET, PUT, DELETE)
    l_verb = server->request->get_header_field(
      name = '~request_method'
    ).

    me->enable_cors(
      me->server
    ).

    IF l_verb EQ 'OPTIONS'.
      RETURN.
    ENDIF.

    "Verificando se o metodo DO_POST foi redefinido, se for ele irá utilizar o metodo especifico, senão vai pro automático
    DATA: lw_cpdkey         TYPE seocpdkey,
          lw_method_details TYPE  seoo_method_details,
          lo_cls_relat      TYPE REF TO /dpf/cl_webservice_wrap.

    DATA(lv_clsname) = cl_abap_classdescr=>get_class_name( me ).
    DATA lv_report_id TYPE string.
    DATA lv_auth_check TYPE string.
    DATA lv_periodo_check TYPE string.
    DATA lv_log_erro_ajax TYPE string.
    DATA lv_get_sid TYPE string.

    DATA lv_class_name TYPE /dpf/menu-abap_class_name.

    REPLACE ALL OCCURRENCES OF '\CLASS=' IN lv_clsname WITH ''.
    lw_cpdkey-clsname = lv_clsname.
    lw_cpdkey-cpdname = 'DO_POST'.

    CALL FUNCTION 'SEO_METHOD_GET_DETAIL'
      EXPORTING
        cpdkey         = lw_cpdkey
      IMPORTING
        method_details = lw_method_details.

    lv_report_id     = server->request->get_form_field('P_REPORT_ID') .
    lv_auth_check    = server->request->get_form_field('P_AUTH_CHECK') .
    lv_periodo_check = server->request->get_form_field('P_PERIODO_CHECK') .
    lv_log_erro_ajax = server->request->get_form_field('P_LOG_ERRO_AJAX') .
    lv_get_sid       = server->request->get_form_field('P_GET_SID').

    REPLACE ALL OCCURRENCES OF |'| IN lv_report_id WITH ''.
    REPLACE ALL OCCURRENCES OF |"| IN lv_report_id WITH ''.

    me->mv_report_id = lv_report_id.

    IF lw_cpdkey-clsname = '/DPF/CL_WEBSERVICE_WRAP'.

      IF lv_auth_check IS NOT INITIAL .

        IF me->authority_check(
             EXPORTING
               it_params = lt_params
           ) IS NOT INITIAL.

          me->to_json(
            EXPORTING
              i_data        = lv_report_id
              i_no_response = 'X'
            IMPORTING
              ev_json       = DATA(lv_auth_object)
          ).

          server->response->set_status(
            code   = '403'
            reason = 'forbidden' ##NO_TEXT
          ).

          server->response->set_cdata(
            data = |Sem permissão: | && '/DPF/AUTH' && lv_auth_object
          ).

        ENDIF.

        RETURN.

      ELSE.

        DATA lv_msg_trava_per TYPE string.

        IF lv_periodo_check IS NOT INITIAL .
          TRY .
              IF me->verificar_empresa_filial( EXPORTING it_params = lt_params ) IS INITIAL.

                IF me->travar_periodo_check(
                     EXPORTING
                       it_params  = lt_params
                     IMPORTING
                       ev_message = lv_msg_trava_per
                   ) IS NOT INITIAL.

                  TYPES: BEGIN OF y_retorno,
                           mensagem TYPE string,
                         END OF y_retorno.

                  DATA lw_retorno TYPE y_retorno.

                  lw_retorno-mensagem = lv_msg_trava_per.
                  FIELD-SYMBOLS: <fs_output> TYPE y_retorno.
                  ASSIGN lw_retorno TO <fs_output>.

                  me->to_json( <fs_output> ).
                ENDIF.

              ELSE.

                me->to_json(
                  i_data        = 'Não foi possível verificar os dados informados de empresa e filial!'
                  i_http_status = '500'
                  i_reason_text = 'ERROR'
                ).

              ENDIF.

            CATCH cx_root INTO DATA(lo_exception).

              me->to_json(
                i_data        = lo_exception->get_text( )
                i_http_status = 500
              ).

          ENDTRY.

          RETURN.
        ENDIF.

        IF lv_get_sid IS NOT INITIAL.

          DATA(lv_sid) = sy-sysid.
          FIELD-SYMBOLS: <fs_sid> TYPE sy-sysid.
          ASSIGN lv_sid TO <fs_sid>.
          me->to_json( <fs_sid> ).
          RETURN.

        ENDIF.

        "Grava os erros de ajax dos relatórios
        IF lv_log_erro_ajax IS NOT INITIAL.

          DATA: lv_log_dados       TYPE string,
                lv_parametros_ajax TYPE string,
                lv_response_text   TYPE string,
                lw_log_dados       TYPE /dpf/d_log_ajax,
                lw_ativa_log       TYPE /dpf/d_ativa_log,
                it_log_dados       TYPE TABLE OF /dpf/d_log_ajax.

          lv_log_dados        = server->request->get_form_field('P_LOG_DADOS_AJAX').
          lv_response_text    = server->request->get_form_field('P_RESPONSETEXT').
          lv_parametros_ajax  = server->request->get_form_field('P_PARAMETROS_AJAX').

          REPLACE ALL OCCURRENCES OF '[{"low":"' IN lv_log_dados WITH ''.
          REPLACE ALL OCCURRENCES OF '","high":"","kind":"P","option":"EQ","sign":"I"}]' IN lv_log_dados WITH ''.
          REPLACE ALL OCCURRENCES OF '\' IN lv_log_dados WITH ''.

          REPLACE ALL OCCURRENCES OF '[{"low":"' IN lv_parametros_ajax WITH ''.
          REPLACE ALL OCCURRENCES OF '","high":"","kind":"P","option":"EQ","sign":"I"}]' IN lv_parametros_ajax WITH ''.
          REPLACE ALL OCCURRENCES OF '\' IN lv_parametros_ajax WITH ''.

          REPLACE ALL OCCURRENCES OF '[{"low":"' IN lv_response_text WITH ''.
          REPLACE ALL OCCURRENCES OF '","high":"","kind":"P","option":"EQ","sign":"I"}]' IN lv_response_text WITH ''.
          REPLACE ALL OCCURRENCES OF '\n' IN lv_response_text WITH ''.

          /dpf/cl_json=>deserialize(
            EXPORTING
              json  = lv_log_dados
            CHANGING
              data  = lw_log_dados
          ).

          IF lw_log_dados-tipo EQ 'ajaxSend'.
            SELECT *
              FROM /dpf/d_ativa_log CLIENT SPECIFIED UP TO 1 ROWS
              INTO lw_ativa_log
             WHERE tipo_log = 'ajaxSend'.
            ENDSELECT.
            IF lw_ativa_log-ativo EQ ''.
              RETURN.
            ENDIF.
          ELSEIF lw_log_dados-tipo EQ 'ajaxError'.
            SELECT *
              FROM /dpf/d_ativa_log CLIENT SPECIFIED UP TO 1 ROWS
              INTO lw_ativa_log
             WHERE tipo_log = 'ajaxError'.
            ENDSELECT.
            IF lw_ativa_log-ativo EQ ''.
              RETURN.
            ENDIF.
          ENDIF.

          lw_log_dados-usuario      = sy-uname.
          lw_log_dados-parametros   = lv_parametros_ajax.
          lw_log_dados-responsetext = lv_response_text.

          IF lw_log_dados-mandt IS INITIAL.
            SELECT mandt_tdf
              FROM /tmf/d_sys_inf CLIENT SPECIFIED UP TO 1 ROWS
              INTO lw_log_dados-mandt.
            ENDSELECT.
          ENDIF.

          APPEND lw_log_dados TO it_log_dados.
          INSERT /dpf/d_log_ajax CLIENT SPECIFIED FROM TABLE it_log_dados.

          IF sy-subrc = 0.
            COMMIT WORK.
          ELSE.
            ROLLBACK  WORK.
          ENDIF.

          RETURN.

        ENDIF.

        IF lv_report_id EQ 'MENU' OR lv_report_id EQ 'ROUTES'.

          CREATE OBJECT lo_cls_relat TYPE ('/DPF/CL_GET_MENU').
          lo_cls_relat->if_http_extension~handle_request(
            server = server
          ).

        ELSE.

          IF me->authority_check(
               EXPORTING
                 iv_report_id = CONV #( lv_report_id )
            ) IS INITIAL.

            ">>> Início - Engineering - Wander Rodrigues - 27.07.2020 15:26:07
            IF lv_report_id    >= '8000000000'   "Range de Report ID exclusivo para treinamento
              AND lv_report_id <= '8999999999'.  "Range de Report ID exclusivo para treinamento
              "Verificar se a tabela de treinamento existe
              SELECT SINGLE tabname
                FROM dd02l
               WHERE tabname = '/DPF/TREINAMENTO'
                INTO @DATA(lv_tabname).

              IF sy-subrc = 0.
                DATA(lv_where) = |REPORT_ID = '| && lv_report_id && |'|.

                TRY.
                    SELECT ('ABAP_CLASS_NAME')          "#EC CI_NOFIELD
                      FROM (lv_tabname)
                        UP TO 1 ROWS
                      INTO @lv_class_name
                     WHERE (lv_where).
                    ENDSELECT.
                  CATCH cx_sy_dynamic_osql_semantics. "Impedir qualquer erro com esta tabela para nao impactar o produto
                    "Programa segue normalmente
                ENDTRY.
              ENDIF.
            ELSE.
              ">>> Fim - Engineering - Wander Rodrigues - 27.07.2020 15:26:07
              SELECT abap_class_name                    "#EC CI_NOFIELD
                FROM /dpf/menu
                  UP TO 1 ROWS
                INTO @lv_class_name
               WHERE report_id = @lv_report_id.
              ENDSELECT.
            ENDIF.

            IF lv_class_name IS INITIAL OR lv_class_name = ' '.
              RETURN.
            ENDIF.

            CREATE OBJECT lo_cls_relat TYPE (lv_class_name). " SE ERRO AQUI, VERIFICAR ABAP_CLASS_NAME NA TABELA /DPF/MENU
            lo_cls_relat->mv_report_id = lv_report_id.
            lo_cls_relat->if_http_extension~handle_request(
              server = server
            ).

          ELSE.

            server->response->set_status(
              code   = '403'
              reason = 'forbidden' ##NO_TEXT
            ).
            server->response->set_cdata(
              data = |Sem permissão: | && '/DPF/AUTH' && lv_report_id
            ).

          ENDIF.
        ENDIF.
      ENDIF.

      RETURN.
    ENDIF.

    "Retrieving the parameters passed in the URL
    l_path_info = server->request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO l_resource
                                  l_param_1
                                  l_param_2.

    me->enable_cors(
      me->server
     ).

    IF l_verb EQ 'OPTIONS'.
      RETURN.
    ENDIF.

    "Only methods GET, POST, PUT, DELETE are allowed
    IF ( l_verb NE 'GET' ) AND ( l_verb NE 'POST' ) AND
       ( l_verb NE 'PUT' ) AND ( l_verb NE 'DELETE' ).

      " For any other method the service should return the error code 405
      server->response->set_status(
        code   = '405'
        reason = CONV #( 'Method not allowed'(001) )
      ).

      server->response->set_header_field(
        name  = CONV #( 'Allow'(002) )
        value = 'POST, GET, PUT, DELETE'
      ).

      RETURN.

    ENDIF.

    CASE l_verb.

      WHEN 'POST'.   " C (Create)

        IF lw_method_details-is_redefined = 'X'.
          TRY.
              me->do_post(
                EXPORTING
                  it_params = lt_params
              ).
            CATCH cx_uuid_error INTO DATA(lo_error).
              me->to_json(
                EXPORTING
                  i_data        = lo_error->get_text( )
                  i_http_status = '500'
                  i_reason_text = 'ERROR'
              ).
          ENDTRY.
        ELSE.
          TRY.
              me->do_post_auto(
                EXPORTING
                  it_params = lt_params
              ).
            CATCH cx_uuid_error INTO lo_error.
              me->to_json(
                EXPORTING
                  i_data        = lo_error->get_text( )
                  i_http_status = '500'
                  i_reason_text = 'ERROR'
              ).
          ENDTRY.
        ENDIF.

      WHEN 'GET'.    " R (Read)

        me->do_get(
          EXPORTING
            it_params = lt_params
        ).

      WHEN 'PUT'.

        me->do_put(
          EXPORTING
            it_params = lt_params
        ).

      WHEN 'DELETE'. " D (Delete)

        me->do_delete(
          EXPORTING
            it_params = lt_params
        ).

    ENDCASE.

  ENDMETHOD.


  METHOD json_to_sel_screen.
    DATA: lt_sel_screen        TYPE /dpf/tt_rsparams,
          lw_sel_screen        TYPE /dpf/st_rsparams,
          lo_data              TYPE REF TO data ##NEEDED,
          lt_report_parameters TYPE /dpf/tt_rsparams.

    LOOP AT it_params INTO DATA(lw_params).
      /dpf/cl_json=>deserialize(
        EXPORTING
          json = lw_params-value
        CHANGING
          data  = lt_report_parameters
      ).

      LOOP AT lt_report_parameters ASSIGNING FIELD-SYMBOL(<fs_parameters>).
        MOVE-CORRESPONDING <fs_parameters> TO lw_sel_screen.
        lw_sel_screen-selname = lw_params-name.
        TRANSLATE lw_sel_screen-selname TO UPPER CASE.
        APPEND lw_sel_screen TO lt_sel_screen.
      ENDLOOP.

      FREE: lt_report_parameters,lw_sel_screen.
    ENDLOOP.

    rt_sel_screen = lt_sel_screen[].
  ENDMETHOD.


  METHOD montar_cabecalho_auto.
    "Metodo que retorna os dados da empresa usados para montar o cabecalho padrao do DPFISC
    "Ao usar esse metodo, deve-se redefinir o DO_POST para modificar o retorno do json para conter as informacoes do cabecalho e do retorno
    "Por padrao, ha tambem o periodo, que pode ser montado com o trecho de codigo a seguir:
    "lv_periodo = sw_date-low+6(2) && |/| && sw_date-low+4(2) && |/| && sw_date-low(4) && | - | && sw_date-high+6(2) && |/| && sw_date-high+4(2) && |/| && sw_date-high(4).
    "O cabecalho e montado na tela. Telas de exemplo: relatorio DOT ES, beneficios fiscais
    DATA: lt_estabelec TYPE /tmf/v_emp_fed,
          lv_eh_matriz TYPE flag.

    IF iv_filial IS INITIAL.
      lv_eh_matriz = 'X'.
      SELECT SINGLE *
        INTO et_cabecalho
        FROM /tmf/v_emp_fed ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
       WHERE empresa   = iv_empresa
         AND eh_matriz = lv_eh_matriz.
    ELSE.
      SELECT SINGLE *
        INTO et_cabecalho
        FROM /tmf/v_emp_fed ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
       WHERE empresa         = iv_empresa
         AND estabelecimento = iv_filial.
    ENDIF.
  ENDMETHOD.


  METHOD response_from_report_run.

    DATA lv_file_url TYPE string.

    DATA(lt_report_files)  = /tmf/cl_tom_metadata=>get_report_files(
      iv_run_id = io_report_run->get_run_id( )
    ).

    IF lines( lt_report_files ) EQ 1.
      READ TABLE lt_report_files INTO DATA(lw_report_files) INDEX 1.
      DATA(lo_report_file) =  /tmf/cl_tom_metadata=>get_report_file(
        iv_file_id = lw_report_files->get_file_id( )
      ).
    ENDIF.

    " Caso o arquivo não tenha sido gerado, ele passa a url vazia pois o mesmo pode estar sendo gerado em background.
    IF lo_report_file IS NOT INITIAL.

      lv_file_url = /dpf/cl_ui5_caller=>get_server_url_tdf( ) &&
        /tmf/cl_tom_metadata=>get_download_url(
          EXPORTING
            iv_file_id     =  lo_report_file->get_file_id( )
            io_report_run  = io_report_run
            io_report_file = lo_report_file
         )->get_url( ).

    ELSE.

      lv_file_url = ''.

    ENDIF.

    ev_file_url = /dpf/cl_ui5_caller=>get_server_url_tdf(
      path = /dpf/cl_ui5_caller=>lc_tdf_path
              && 'tom01/index.html' )  ##NO_TEXT
              && '#/detail/'
              && io_report_run->get_run_id( ).

    me->to_json( VALUE /dpf/st_tom_response(
        run_id    = io_report_run->get_run_id( )
        report_id = io_report_run->get_report_id( )
        tom_url   = /dpf/cl_ui5_caller=>get_server_url_tdf(
                      path = /dpf/cl_ui5_caller=>lc_tdf_path
                              && 'tom01/index.html' )  ##NO_TEXT
                              && '#/detail/'
                              && io_report_run->get_run_id( )
        file_url  = lv_file_url
      )
    ).

  ENDMETHOD.


  METHOD save_attachment.

    CLEAR rv_attachment_id.

    IF iv_hex_data IS INITIAL.
      RETURN.
    ENDIF.

    "Gerar ID único para o anexo
    DATA(lv_attachment_id) = cl_system_uuid=>create_uuid_c32_static( ).

    "Montar estrutura
    DATA(ls_attachment) = VALUE /dpf/attachment(
        mandt         = iv_mandt
        report_id     = iv_report_id
        empresa       = iv_empresa
        attachment_id = lv_attachment_id
        filename      = iv_filename
        file_type     = iv_file_type
        hex_data      = iv_hex_data
        att_date      = sy-datum
        att_time      = sy-uzeit
        descricao     = iv_descricao
    ).

    "Gravar anexo
    INSERT INTO /dpf/attachment USING CLIENT @iv_mandt VALUES @ls_attachment.

    IF sy-subrc <> 0.
      ROLLBACK WORK.                                   "#EC CI_ROLLBACK
    ELSE.
      COMMIT WORK AND WAIT.

      "Retornar o ID Anexo gerado
      rv_attachment_id = lv_attachment_id.
    ENDIF.

  ENDMETHOD.


  METHOD submit_job .

    DATA: lv_job_was_released TYPE btch0000-char1 ##NEEDED, " Indica se o job foi liberado
          lt_sel_screen       TYPE /dpf/tt_rsparams,
          ls_return           TYPE /tmf/message_return_table,
          lv_jobname          TYPE /tmf/de_jobname,
          lv_timestamp        TYPE timestampl,
          lv_csv_dt           TYPE tbtcjob-sdlstrtdt,
          lv_csv_hr           TYPE tbtcjob-sdlstrttm,
          lv_csv_ex           TYPE btch0000-char1,
          lv_dt_atu           TYPE char8,
          lv_hr_atu           TYPE char6,
          ls_log              TYPE bal_s_log,
          ls_msg              TYPE bal_s_msg.

    CLEAR ro_report_run.
    CLEAR ev_jobcount.

    SELECT SINGLE FROM /tmf/d_tom_job_s CLIENT SPECIFIED
    FIELDS jobname
     WHERE report_id = @me->mv_report_id
      INTO @lv_jobname.

    IF sy-subrc <> 0.
      lv_jobname = iv_nomejob.
    ENDIF.

    "Converter JSON para selection table
    /dpf/cl_json=>deserialize(
      EXPORTING
        json = iv_sel_screen
      CHANGING
        data = lt_sel_screen
    ).

    "Verificar se é agendamento
    DATA(lv_agendar) = me->verificar_agendamento( lt_sel_screen ).

    IF lv_agendar = abap_false.

      "======================================================================================
      " Passos
      " 1) Guardar os parâmetros na classe /DPF/CL_JOB_PARAMETERS
      " 2) Instanciar a classe /DPF/CL_JOB
      "    Esta classe é responsável por validar os parâmetros do job
      "    e chamar a classe /TMF/CL_SPED_JOB
      " 3) A classe /TMF/CL_SPED_JOB dispara o programa /DPF/START_BACKGROUND_JOB
      "    que irá executar o método EXECUTA_RELATORIO em background
      " 4) Essa mesma classe dispara também o programa /TMF/JOB_EXECUTER que
      "    faz o controle de execuções simultâneas.
      " 5) No final da execução do job na SM37 existirão 2 passos, 1 pra cada programa
      "
      " Obs: Não foi possível reaproveitar o código antigo porque ele criava o RUN_ID antes
      " de criar o JOB, e isso causava erro no programa /TMF/JOB_EXECUTER
      "======================================================================================

      "Guardar todos os parâmetros necessários para execução do job
      DATA(lo_job_parameters) = NEW /dpf/cl_job_parameters( ).

      lo_job_parameters->set_selection_screen( iv_sel_screen ).

      "Obsoleto: o programa standard gera um novo run id e é ele que deve ser utilizado
      lo_job_parameters->set_run_id( i_run_id ).

      lo_job_parameters->set_orgstr_key( /tmf/cl_orgstr_utilities=>mc_cc ).
      lo_job_parameters->set_empresa( iv_empresa ).
      lo_job_parameters->set_filial( iv_filial ).
      lo_job_parameters->set_dt_ini( iv_perde ).
      lo_job_parameters->set_dt_fin( iv_perate ).
      lo_job_parameters->set_jobname( lv_jobname ).

      DATA(lv_clname) = cl_abap_classdescr=>get_class_name( me ).
      lo_job_parameters->set_classname( CONV #( lv_clname ) ).

      lo_job_parameters->set_report_id( me->mv_report_id ).
      lo_job_parameters->set_draft_run( abap_true ).
      lo_job_parameters->set_official_run( abap_false ).

      lo_job_parameters->set_erp_keys( ).

      "Web service must be treated as background execution
      sy-batch = abap_true.

      DATA(lo_job) = NEW /dpf/cl_job( lo_job_parameters ).

      "==================================================================
      " Fazer o escalonamento e controle de execução do JOB
      "==================================================================
      lo_job->schedule_execution( ).

      "É necessário retornar o REPORT_RUN para que o DO_POST_AUTO possa
      "retornar o link do TOM pra tela
      ro_report_run = lo_job_parameters->get_report_run( ).

    ELSE.

      "Forma anterior de disparar job - Por enquanto os jobs
      "agendados com o botão EXCEL na primeira tela, ou qualquer outro agendamento
      "que use o P_CSV_DT e o P_CSV_HR vão continuar assim (a Classe acima sempre cria
      "o job para execução imediata)

      "Criar job
      CALL FUNCTION 'JOB_OPEN'
        EXPORTING
          jobname  = lv_jobname
        IMPORTING
          jobcount = ev_jobcount
        EXCEPTIONS
          OTHERS   = 1.

      IF sy-subrc <> 0.
        WRITE: 'Job não pode ser aberto - Código:'(004).
        RETURN.
      ENDIF.

      lv_clname = cl_abap_classdescr=>get_class_name( me ).

      "Entrar no programa que chama o método EXECUTA_RELATORIO
      SUBMIT /dpf/executa_relatorio_backgr               "#EC CI_SUBMIT
         USER sy-uname
         VIA JOB lv_jobname
         NUMBER ev_jobcount
         WITH p_sel_sc = iv_sel_screen
         WITH p_run_id = i_run_id
         WITH p_clname = lv_clname
         WITH p_nmjob  = lv_jobname
         WITH p_count  = ev_jobcount
         AND RETURN.

      "=========================================================================================
      "Regra nova para gerar CSV em background com data e hora definida pelo usuário
      "=========================================================================================

      CLEAR lv_csv_dt.
      CLEAR lv_csv_hr.

      "Buscar data e hora
      me->get_dt_hr_csv(
        EXPORTING
          it_sel_screen = lt_sel_screen
        IMPORTING
          ev_csv_dt     = lv_csv_dt
          ev_csv_hr     = lv_csv_hr
      ).

      "Data e hora do sistema
      lv_dt_atu = sy-datum.
      lv_hr_atu = sy-uzeit.

      " para retirar o erro da hora agendada ficar menor que a hora atual ou se o fuso for diferente
      IF lv_csv_dt IS NOT INITIAL
        AND lv_csv_dt <> ''
        AND lv_csv_dt <> '00000000'.

         "Não é necessário converter
*        "Buscar fuso horário do sistema e converter se necessário
*        DATA(lv_system_timezone) = cl_abap_tstmp=>get_system_timezone( ).
*
*        IF lv_system_timezone <> sy-zonlo.
*          CONVERT DATE lv_csv_dt TIME lv_csv_hr INTO TIME STAMP lv_timestamp TIME ZONE sy-zonlo.
*          CONVERT TIME STAMP lv_timestamp TIME ZONE lv_system_timezone INTO DATE lv_csv_dt TIME lv_csv_hr.
*        ENDIF.

        IF ( lv_csv_dt < lv_dt_atu )
          OR ( lv_csv_dt = lv_dt_atu AND lv_csv_hr < lv_hr_atu ).
          lv_csv_dt = lv_dt_atu.
          lv_csv_hr = lv_hr_atu.
        ENDIF.

      ENDIF.

      "Fill SLG1 Log Header
      ls_log = /tmf/cl_log=>get_log_header(
        iv_object    = '/TMF/BR'
        iv_subobject = 'REPORTS'
        iv_run_id    = i_run_id
      ).

      IF ( lv_csv_dt > lv_dt_atu )
        OR ( lv_csv_dt = lv_dt_atu AND lv_csv_hr > lv_hr_atu ).

        CLEAR lv_csv_ex.

        "Fill Message
        ls_msg = VALUE #(
          msgty = 'S'
          msgid = '/TMF/TOM_API'
          msgno = '013'
          msgv1 = |Execução programada para | &&
                  lv_csv_dt+6(2) && |/| && lv_csv_dt+4(2) && |/| && lv_csv_dt+0(4) &&
                  | às | &&
                  lv_csv_hr+0(2) && |:| && lv_csv_hr+2(2) && |:| && lv_csv_hr+4(2) &&
                  |.|
        ).

      ELSE.

        lv_csv_ex = 'X'.
        CLEAR lv_csv_dt.
        CLEAR lv_csv_hr.

        "Fill Message
        ls_msg = VALUE #(
          msgty = 'S'
          msgid = '/TMF/TOM_API'
          msgno = '013'
          msgv1 = |Execução imediata|
        ).

      ENDIF.

      TRY.
          /tmf/cl_log=>create_and_insert(
            is_header  = ls_log
            is_message = ls_msg
          ).

        CATCH cx_law_log INTO DATA(lx_log).
          RAISE EXCEPTION TYPE /tmf/cx_tom_log
            EXPORTING
              textid = /tmf/cx_tom_log=>error_save_log.
      ENDTRY.

      CALL FUNCTION 'JOB_CLOSE'
        EXPORTING
          jobcount         = ev_jobcount
          jobname          = lv_jobname
          strtimmed        = lv_csv_ex
          sdlstrtdt        = lv_csv_dt
          sdlstrttm        = lv_csv_hr
        IMPORTING
          job_was_released = lv_job_was_released
        EXCEPTIONS
          OTHERS           = 1.

      "Se der erro, emitir mensagem para gravar no job
      IF sy-subrc <> 0.
        WRITE: 'Job não pode ser fechado'(003).
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD to_json.

    CLEAR ev_json.

    DATA(lo_json_serializer) = NEW /dpf/json_serializer(
      data = i_data " Data to be serialized
    ).

    "Serialize ABAP data to JSON
    lo_json_serializer->serialize( ).

    "Get JSON string
    DATA(lv_json) = lo_json_serializer->get_data( ).

    IF i_no_response IS INITIAL.

      "Sets the content type of the response
      me->server->response->set_header_field(
        name  = 'exec-id' ##NO_TEXT
        value = me->mv_exec_id && '' ##NO_TEXT
      ).

      me->server->response->set_header_field(
        name  = 'Content-Type' ##NO_TEXT
        value = 'application/json; charset=utf-8' ##NO_TEXT
      ).

      "Returns the results in JSON format
      me->server->response->set_cdata(
        data = lv_json
      ).

      me->server->response->set_status(
        EXPORTING
          code   = i_http_status
          reason = i_reason_text
      ).

    ELSE.
      ev_json = lv_json.
    ENDIF.

  ENDMETHOD.


  METHOD travar_periodo_check.

    TYPES ty_t_placeholder TYPE TABLE OF /dpf/cl_db_select=>mty_placeholder WITH DEFAULT KEY.

    DATA: sel_screen      TYPE /dpf/tt_rsparams,
          s_bukrs         TYPE RANGE OF /tmf/de_empresa,
          sw_bukrs        LIKE LINE OF s_bukrs,
          p_mandt         TYPE mandt,
          p_bukrs         TYPE /tmf/de_empresa,
          p_branch        TYPE /tmf/de_estabelecimento,
          p_direct(1)     TYPE c,
          p_report_id(50) TYPE c,
          s_branch        TYPE RANGE OF /tmf/de_estabelecimento,
          sw_branch       LIKE LINE OF s_branch,
          s_date          TYPE RANGE OF datum,
          sw_date         LIKE LINE OF s_date,
          lv_field_name   TYPE string,
          wa_dref         TYPE REF TO data,
          lv_texto_tpe    TYPE string,
          lv_sql          TYPE string,
          lt_trvper       TYPE /dpf/tt_trvper,
          l_diferenca     TYPE i,
          l_direct(1)     TYPE c,
          gr_err          TYPE REF TO cx_root.

    FIELD-SYMBOLS: <fst_select_option> TYPE ANY TABLE,
                   <fs_select_option>  TYPE any,
                   <fs_parameter>      TYPE any,
                   <fst_output>        TYPE ANY TABLE ##NEEDED.

    "----------------------------------------------------------------------
    " Converter parâmetros da tela para o formato abap
    "----------------------------------------------------------------------
    sel_screen = me->json_to_sel_screen( it_params ).

    LOOP AT sel_screen INTO DATA(lw_sel_screen).
      IF lw_sel_screen-selname CP 'S_*'. "Select options
        ASSIGN (lw_sel_screen-selname) TO <fst_select_option>.
        IF sy-subrc IS INITIAL.
          CREATE DATA wa_dref LIKE LINE OF <fst_select_option>.
          ASSIGN wa_dref->* TO <fs_select_option>.
          MOVE-CORRESPONDING lw_sel_screen TO <fs_select_option>.
          INSERT <fs_select_option> INTO TABLE <fst_select_option>.
          UNASSIGN <fs_select_option>.
          lv_field_name   = lw_sel_screen-selname .
          REPLACE 'S_' IN lv_field_name WITH 'SW_' .
          ASSIGN (lv_field_name) TO <fs_select_option>.
          IF sy-subrc IS INITIAL.
            "Read table nao funciona para tipos genericos
            LOOP AT <fst_select_option>
              ASSIGNING FIELD-SYMBOL(<fs_first_line>).
              <fs_select_option> = <fs_first_line>.
              EXIT.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ELSE. " PARAMETER
        ASSIGN (lw_sel_screen-selname) TO <fs_parameter> .
        IF sy-subrc IS INITIAL.
          <fs_parameter> = lw_sel_screen-low.
        ENDIF.
      ENDIF.
      FREE wa_dref.
    ENDLOOP.

    p_report_id = server->request->get_form_field('P_REPORT_ID') ."Campo tinha mais que 8 posições

    REPLACE ALL OCCURRENCES OF |'| IN  p_report_id  WITH ''.
    REPLACE ALL OCCURRENCES OF |"| IN  p_report_id  WITH ''.

    CASE p_direct.
      WHEN '0'.
        l_direct = '1'.
      WHEN '1'.
        l_direct = '2'.
      WHEN OTHERS.
        l_direct = ''.
    ENDCASE.

    "----------------------------------------------------------------------
    " Preencher placeholder
    "----------------------------------------------------------------------
    DATA(lt_placeholder) = VALUE ty_t_placeholder(
      ( placeholder_name = 'P_MANDT'
        value            = p_mandt )
      ( placeholder_name = 'P_EMPRESA'
        value            = p_bukrs )
      ( placeholder_name = 'P_REPORT_ID'
        value            = p_report_id )
    ).

    IF sw_branch-low IS INITIAL.
      APPEND VALUE /dpf/cl_db_select=>mty_placeholder(
          placeholder_name = 'P_FILIAL'
          value            = |( FILIAL = '|  && p_branch && |' )|
      ) TO lt_placeholder.
    ELSE.
      APPEND VALUE /dpf/cl_db_select=>mty_placeholder(
          placeholder_name = 'P_FILIAL'
          value            = cl_shdb_seltab=>combine_seltabs(
                               it_named_seltabs = VALUE #(
                                 ( name = 'FILIAL'
                                   dref = REF #( s_branch[] ) )
                               )
                             )
      ) TO lt_placeholder.
    ENDIF.

    APPEND VALUE /dpf/cl_db_select=>mty_placeholder(
        placeholder_name = 'P_DIRECT'
        value            = l_direct
    ) TO lt_placeholder.

    "----------------------------------------------------------------------
    " Selecionar dados
    "----------------------------------------------------------------------
    DATA(lo_db_select) = NEW /dpf/cl_db_select(
      iv_empresa = p_bukrs
      iv_filial  = p_branch
    ).

    lo_db_select->select_builder(
      EXPORTING
        iv_view_name    = '/DPF/VTRVPER'
        it_placeholders = lt_placeholder
        iv_report_id    = me->mv_report_id
        iv_where        = ''
      IMPORTING
        ev_sql          = lv_sql
    ).

    lo_db_select->execute_select(
      EXPORTING
        iv_sql   = lv_sql
      CHANGING
        ct_table = lt_trvper
    ).

    READ TABLE lt_trvper INTO DATA(ls_trvper) INDEX 1.
    IF sy-subrc <> 0.
      CLEAR ls_trvper.
    ENDIF.

    IF ls_trvper-qtd_dias > 0.

      CALL FUNCTION 'DAYS_BETWEEN_TWO_DATES'
        EXPORTING
          i_datum_bis = sw_date-high
          i_datum_von = sw_date-low
          i_szbmeth   = 3 "Considerar calendário de 365 dias.
        IMPORTING
          e_tage      = l_diferenca. " Dieferença em dias

      l_diferenca = l_diferenca + 1.

      IF l_diferenca > ls_trvper-qtd_dias.
        r_subrc = 4.

        DATA lv_str_direcao TYPE string.

        CASE ls_trvper-direcao.
          WHEN '0'.
            lv_str_direcao = | quando a direção for igual a 0 (entrada)|.
          WHEN '1'.
            lv_str_direcao = | quando a direção for igual a 1 (saída)|.
          WHEN '2'.
            lv_str_direcao = | quando a direção for igual a 2 (entrada/saída)|.
          WHEN OTHERS.
            lv_str_direcao = ''.
        ENDCASE.

        IF ls_trvper-filial IS NOT INITIAL.
          ev_message = |Este programa possui regra de bloqueio por período. Para a filial | && ls_trvper-filial &&
                       |, é possível gerar dados de no máximo | && ls_trvper-qtd_dias && | dias| && lv_str_direcao && |.|.
        ELSE.
          ev_message = |Este programa possui regra de bloqueio por período. Para a empresa | && ls_trvper-empresa &&
                       |, é possível gerar dados de no máximo | && ls_trvper-qtd_dias && | dias| && lv_str_direcao && |.|.
        ENDIF.
      ELSE.
        r_subrc = 0.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD verificar_agendamento.

    DATA: lv_csv_dt TYPE tbtcjob-sdlstrtdt,
          lv_csv_hr TYPE tbtcjob-sdlstrttm.

    CLEAR rv_agendar.

    LOOP AT it_sel_screen ASSIGNING FIELD-SYMBOL(<fs_sel_screen>).
      IF <fs_sel_screen>-selname EQ 'P_CSV_DT'.
        lv_csv_dt = <fs_sel_screen>-low.
      ELSEIF <fs_sel_screen>-selname EQ 'P_CSV_HR'.
        lv_csv_hr = <fs_sel_screen>-low.
      ENDIF.
    ENDLOOP.

    IF lv_csv_dt IS NOT INITIAL
      OR lv_csv_hr IS NOT INITIAL.
      rv_agendar = abap_true.
    ELSE.
      rv_agendar = abap_false.
    ENDIF.

  ENDMETHOD.


  METHOD verificar_confluence.

    DATA: lv_fields          TYPE string,
          lv_table           TYPE string,
          lv_where           TYPE string,
          lv_link_confluence TYPE c LENGTH 255.

    CLEAR eo_data.

    "Verificar se existe o campo CONFLUENCE na tabela /DPF/MENU e se está preenchido
    "Foi feito desta forma para não causar nenhuma interrupção no produto
    "caso o campo ainda não exista nas tabelas

    "Verificar primeiro na /DPF/MENU
    lv_fields = 'CONFLUENCE'.
    lv_table  = '/DPF/MENU'.
    lv_where  = |REPORT_ID = '| && me->mv_report_id && |'|.

    TRY.
        SELECT SINGLE (lv_fields)
          FROM (lv_table)
         WHERE (lv_where)
          INTO @lv_link_confluence.

        IF sy-subrc <> 0.
          CLEAR lv_link_confluence.
        ENDIF.

      CATCH cx_sy_dynamic_osql_semantics.
        CLEAR lv_link_confluence.
    ENDTRY.

    IF lv_link_confluence IS INITIAL.

      "Verificar na /DPF/TREINAMENTO
      lv_fields = 'CONFLUENCE'.
      lv_table  = '/DPF/TREINAMENTO'.
      lv_where  = |REPORT_ID = '| && me->mv_report_id && |'|.

      TRY.
          SELECT SINGLE (lv_fields)
            FROM (lv_table)
           WHERE (lv_where)
            INTO @lv_link_confluence.

          IF sy-subrc <> 0.
            CLEAR lv_link_confluence.
          ENDIF.

        CATCH cx_sy_dynamic_osql_semantics.
          CLEAR lv_link_confluence.
      ENDTRY.

    ENDIF.

    "Retornar o link para o confluence (ou em branco caso o campo não exista
    "ou não esteja preenchido na tabela)
    CREATE DATA eo_data LIKE lv_link_confluence.
    ASSIGN eo_data->* TO FIELD-SYMBOL(<fs_data>).
    <fs_data> = lv_link_confluence.

  ENDMETHOD.


  METHOD verificar_empresa_filial.

    DATA: sel_screen    TYPE /dpf/tt_rsparams,
          s_bukrs       TYPE RANGE OF /tmf/de_empresa,
          sw_bukrs      LIKE LINE OF s_bukrs,
          p_mandt       TYPE mandt,
          p_bukrs       TYPE /tmf/de_empresa,
          p_branch      TYPE /tmf/de_estabelecimento,
          lv_field_name TYPE string,
          mv_mandt_tdf  TYPE mandt.

    DATA: wa_dref TYPE REF TO data.

    FIELD-SYMBOLS: <fst_select_option> TYPE ANY TABLE,
                   <fs_select_option>  TYPE any,
                   <fs_parameter>      TYPE any,
                   <fst_output>        TYPE ANY TABLE ##NEEDED
                   .

    CLEAR r_subrc.

    sel_screen = me->json_to_sel_screen( it_params ).

    LOOP AT sel_screen
      INTO DATA(lw_sel_screen).
      IF lw_sel_screen-selname CP 'S_*'. "Select options
        ASSIGN (lw_sel_screen-selname) TO <fst_select_option>.
        IF sy-subrc IS INITIAL.
          CREATE DATA wa_dref LIKE LINE OF <fst_select_option>.
          ASSIGN wa_dref->* TO <fs_select_option>.
          MOVE-CORRESPONDING lw_sel_screen TO <fs_select_option>.
          INSERT <fs_select_option> INTO TABLE <fst_select_option>.
          UNASSIGN <fs_select_option>.
          lv_field_name   = lw_sel_screen-selname .
          REPLACE 'S_' IN lv_field_name WITH 'SW_' .
          ASSIGN (lv_field_name) TO <fs_select_option>.
          IF sy-subrc IS INITIAL.
            "Read table nao funciona para tipos genericos
            LOOP AT <fst_select_option>
              ASSIGNING FIELD-SYMBOL(<fs_first_line>).
              <fs_select_option> = <fs_first_line>.
              EXIT.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ELSE. " PARAMETER
        ASSIGN (lw_sel_screen-selname) TO <fs_parameter> .
        IF sy-subrc IS INITIAL.
          <fs_parameter> = lw_sel_screen-low.
        ENDIF.
      ENDIF.
      FREE: wa_dref.
    ENDLOOP.

    IF p_bukrs IS NOT INITIAL.
      IF p_branch IS NOT INITIAL.
        SELECT SINGLE mandt_tdf FROM /tmf/d_sys_inf INTO mv_mandt_tdf WHERE bukrs = p_bukrs AND branch = p_branch.
      ELSE.
        SELECT SINGLE mandt_tdf FROM /tmf/d_sys_inf INTO mv_mandt_tdf WHERE bukrs = p_bukrs .
      ENDIF.

      r_subrc = sy-subrc.
    ELSE.
      r_subrc = 0.
    ENDIF.

  ENDMETHOD.


  METHOD verifica_periodo_fiscal_aberto.

    IF iv_filial IS NOT INITIAL.
      DATA(lv_filial) = iv_filial.
    ELSE.
      SELECT SINGLE estabelecimento
        INTO lv_filial
        FROM /tmf/v_emp_fed ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
       WHERE empresa   = iv_empresa
         AND eh_matriz = abap_true.

      IF sy-subrc <> 0.
        CLEAR lv_filial.
      ENDIF.
    ENDIF.

    me->get_fiscal_period_status(
      EXPORTING
        iv_bukrs       =  iv_empresa           " Empresa
        iv_branch      =  lv_filial            " Estabelecimento
        iv_ano         =  CONV #( iv_ano )     " Exercício
        iv_mes         =  CONV #( iv_mes )     " Mês do exercício
      IMPORTING
        ev_status      =  ev_cod_status        " Status do período contábil para
        ev_status_text =  ev_desc_status       " Texto breve para valores fixos
    ).

    "Regra definida de acordo com o praticado no standard Sap no ECC (JCR #14656 14/04/2022)
    IF ev_cod_status = ''         "''  Vazio
      OR ev_cod_status = '000'    "000 Não definido
      OR ev_cod_status = '100'    "100 Aberto
      OR ev_cod_status = '200'    "200 Cálculo
      OR ev_cod_status = '500'.   "500 Recálculo

      ev_periodo_fiscal_aberto = abap_true.

    ELSE.   "300 Relatório / 400 Encerrado / 600 Retificação

      ev_periodo_fiscal_aberto = abap_false.

    ENDIF.

  ENDMETHOD.
ENDCLASS.