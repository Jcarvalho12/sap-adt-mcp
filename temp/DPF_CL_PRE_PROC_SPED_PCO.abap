CLASS /dpf/cl_pre_proc_sped_pco DEFINITION
  PUBLIC
  INHERITING FROM /dpf/cl_webservice_wrap
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: ty_t_placeholder TYPE STANDARD TABLE OF /dpf/cl_db_select=>mty_placeholder WITH EMPTY KEY,
           ty_t_arquivo     TYPE TABLE OF string.

    INTERFACES if_amdp_marker_hdb .

    METHODS executa_relatorio REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_permissao,
             campo  TYPE string,
             status TYPE string,
           END OF ty_permissao .

    TYPES: BEGIN OF ty_tooltip,
             identificador TYPE string,
             dica          TYPE string,
           END OF ty_tooltip .

    DATA: it_permissao TYPE TABLE OF ty_permissao,
          wa_permissao TYPE ty_permissao,
          it_tooltip   TYPE TABLE OF ty_tooltip,
          wa_tooltip   TYPE ty_tooltip,
          s_chkcmp     TYPE RANGE OF string ,      "TABELA RANGE COM NOME DOS CAMPOS PARA VERIFICAR AUTORIZAÇÃO (LOW)
          s_tooltp     TYPE RANGE OF string ,      "TABELA RANGE COM OS IDENTIFICADORES DA DICA PARA SELECT NO DB (LOW)
          p_dt_rec     TYPE char6, "usado nos deletes do bloco M
          go_badi      TYPE REF TO /dpf/badi_pco_pre_proc.

    TYPES: BEGIN OF ty_retorno_periodo,
             empresa               TYPE char4,
             filial                TYPE char4,
             cod_status            TYPE /tmf/de_fiscper_status_to,
             desc_status           TYPE val_text,
             "status               TYPE string,     "JCR #14656 27/04/2022
             periodo_fiscal_aberto TYPE flag,       "JCR #14656 27/04/2022
           END OF ty_retorno_periodo.

    DATA: ls_retorno_periodo TYPE ty_retorno_periodo.

    "COD_CTA NF #11298
    TYPES: BEGIN OF ty_nf_item_cod_cta,
             mandt    TYPE char3,
             empresa  TYPE char4,
             filial   TYPE char4,
             nf_id    TYPE char10,
             num_item TYPE char6,
             dt_e_s   TYPE char8,
             dt_doc   TYPE char8,
             cod_mod  TYPE char2,
             cod_cta  TYPE c LENGTH 60,
           END OF ty_nf_item_cod_cta.

    "0111
    TYPES: BEGIN OF ty_registro_0111,
             mandt                TYPE char3,
             empresa              TYPE char4,
             per_ref              TYPE char6,
             rec_bru_ncum_trib_mi TYPE /dpf/de_dec_25_2,
             rec_bru_ncum_nt_mi   TYPE /dpf/de_dec_25_2,
             rec_bru_ncum_exp     TYPE /dpf/de_dec_25_2,
             rec_bru_cum          TYPE /dpf/de_dec_25_2,
             rec_bru_total        TYPE /dpf/de_dec_25_2,
           END OF ty_registro_0111 .

    "M105
    TYPES: BEGIN OF ty_registro_m105 ,
             mandt         TYPE char3,
             empresa       TYPE char4,
             per_ref       TYPE char6,
             cod_cred      TYPE char3,
             ind_cred_ori  TYPE char1,
             nat_bc_cred   TYPE char2,
             cst_pis       TYPE char2,
             aliq_pis      TYPE /dpf/de_dec_25_4,
             vl_bc_pis_tot TYPE /tmf/de_dec_25_6,
             vl_bc_pis_cum TYPE /tmf/de_dec_25_6,
             vl_bc_pis_nc  TYPE /tmf/de_dec_25_6,
             vl_bc_pis     TYPE /tmf/de_dec_25_6,
             desc_cred     TYPE char255,
             quant_bc_pis  TYPE /tmf/de_dec_25_6,
           END OF ty_registro_m105 .

    "M505
    TYPES: BEGIN OF ty_registro_m505,
             mandt            TYPE char3,
             empresa          TYPE char4,
             per_ref          TYPE char6,
             cod_cred         TYPE char3,
             ind_cred_ori     TYPE char1,
             nat_bc_cred      TYPE char2,
             cst_cofins       TYPE char2,
             aliq_cofins      TYPE /dpf/de_dec_25_4,
             vl_bc_cofins_tot TYPE /tmf/de_dec_25_6,
             vl_bc_cofins_cum TYPE /tmf/de_dec_25_6,
             vl_bc_cofins_nc  TYPE /tmf/de_dec_25_6,
             vl_bc_cofins     TYPE /tmf/de_dec_25_6,
             desc_cred        TYPE char255,
             quant_bc_cofins  TYPE /tmf/de_dec_25_6,
           END OF ty_registro_m505 .

    "M210/M610
    TYPES: BEGIN OF ty_registro_m210_m610,
             mandt                   TYPE char3,
             empresa                 TYPE char4,
             per_ref                 TYPE char6,
             num_lancto              TYPE char10,
             cod_cont                TYPE char2,
             vl_rec_brt              TYPE /dpf/de_dec_25_2,
             vl_bc_cont              TYPE /dpf/de_dec_25_2,
             aliq_pis                TYPE /dpf/de_dec_25_4,
             aliq_cofins             TYPE /dpf/de_dec_25_4,
             vl_ajus_acres_pis       TYPE /dpf/de_dec_25_2,
             vl_ajus_reduc_pis       TYPE /dpf/de_dec_25_2,
             vl_ajus_acres_cofins    TYPE /dpf/de_dec_25_2,
             vl_ajus_reduc_cofins    TYPE /dpf/de_dec_25_2,
             vl_cont_apur_pis        TYPE /dpf/de_dec_25_2,
             vl_cont_apur_cofins     TYPE /dpf/de_dec_25_2,
             vl_cont_per_pis         TYPE /dpf/de_dec_25_2,
             vl_cont_per_cofins      TYPE /dpf/de_dec_25_2,
             vl_ajus_acres_bc_pis    TYPE /dpf/de_dec_25_2,
             vl_ajus_reduc_bc_pis    TYPE /dpf/de_dec_25_2,
             vl_bc_cont_ajus         TYPE /dpf/de_dec_25_2,
             vl_ajus_acres_bc_cofins TYPE /dpf/de_dec_25_2,
             vl_ajus_reduc_bc_cofins TYPE /dpf/de_dec_25_2,
             vl_bc_cont_ajus_pis     TYPE /dpf/de_dec_25_2,
             vl_bc_cont_ajus_cofins  TYPE /dpf/de_dec_25_2,
           END OF ty_registro_m210_m610 .

    "M410
    TYPES: BEGIN OF ty_registro_m410,
             mandt   TYPE char3,
             empresa TYPE char4,
             per_ref TYPE char6,
             cst_pis TYPE char2,
             cod_cta TYPE c LENGTH 60,
             nat_rec TYPE char3,
             vl_rec  TYPE /dpf/de_dec_25_2,
           END OF ty_registro_m410 .

    "M400
    TYPES: BEGIN OF ty_registro_m400,
             mandt      TYPE char3,
             empresa    TYPE char4,
             per_ref    TYPE char6,
             cst_pis    TYPE char2,
             cod_cta    TYPE c LENGTH 60,
             vl_tot_rec TYPE /dpf/de_dec_25_2,
           END OF ty_registro_m400 .

    "M810
    TYPES: BEGIN OF ty_registro_m810,
             mandt      TYPE char3,
             empresa    TYPE char4,
             per_ref    TYPE char6,
             cst_cofins TYPE char2,
             cod_cta    TYPE c LENGTH 60,
             nat_rec    TYPE char3,
             vl_rec     TYPE /dpf/de_dec_25_2,
           END OF ty_registro_m810 .

    "M800
    TYPES: BEGIN OF ty_registro_m800,
             mandt      TYPE char3,
             empresa    TYPE char4,
             per_ref    TYPE char6,
             cst_cofins TYPE char2,
             cod_cta    TYPE c LENGTH 60,
             vl_tot_rec TYPE /dpf/de_dec_25_2,
           END OF ty_registro_m800 .

    "M100/M500
    TYPES: BEGIN OF ty_registro_m100_m500,
             mandt                TYPE char3,
             empresa              TYPE char4,
             per_ref              TYPE char6,
             cod_cred             TYPE char3,
             ind_cred_ori         TYPE char1,
             vl_bc_pis            TYPE /tmf/de_dec_25_6,
             aliq_pis             TYPE /tmf/de_dec_25_6,
             vl_bc_cofins         TYPE /tmf/de_dec_25_6,
             aliq_cofins          TYPE /tmf/de_dec_25_6,
             vl_cred_pis          TYPE /tmf/de_dec_25_6,
             vl_ajus_acres_pis    TYPE /tmf/de_dec_25_6,
             vl_ajus_reduc_pis    TYPE /tmf/de_dec_25_6,
             vl_cred_disp_pis     TYPE /tmf/de_dec_25_6,
             ind_desc_cred_pis    TYPE char1,
             vl_cred_desc_pis     TYPE /tmf/de_dec_25_6,
             sld_cred_pis         TYPE /tmf/de_dec_25_6,
             vl_cred_cofins       TYPE /tmf/de_dec_25_6,
             vl_ajus_acres_cofins TYPE /tmf/de_dec_25_6,
             vl_ajus_reduc_cofins TYPE /tmf/de_dec_25_6,
             vl_cred_disp_cofins  TYPE /tmf/de_dec_25_6,
             ind_desc_cred_cofins TYPE char1,
             vl_cred_desc_cofins  TYPE /tmf/de_dec_25_6,
             sld_cred_cofins      TYPE /tmf/de_dec_25_6,
           END OF ty_registro_m100_m500 .

    "M200/M600
    TYPES: BEGIN OF ty_registro_m200_m600,
             mandt                    TYPE char3,
             empresa                  TYPE char4,
             per_ref                  TYPE char6,
             vl_tot_cont_nc_per_pis   TYPE /tmf/de_dec_25_6,
             vl_tot_cred_desc_pis     TYPE /tmf/de_dec_25_6,
             vl_tot_cred_desc_ant_pis TYPE /tmf/de_dec_25_6,
             vl_tot_cont_nc_dev_pis   TYPE /tmf/de_dec_25_6,
             vl_ret_nc_pis            TYPE /tmf/de_dec_25_6,
             vl_out_ded_nc_pis        TYPE /tmf/de_dec_25_6,
             vl_cont_nc_rec_pis       TYPE /tmf/de_dec_25_6,
             vl_tot_cont_cum_per_pis  TYPE /tmf/de_dec_25_6,
             vl_ret_cum_pis           TYPE /tmf/de_dec_25_6,
             vl_out_ded_cum_pis       TYPE /tmf/de_dec_25_6,
             vl_cont_cum_rec_pis      TYPE /tmf/de_dec_25_6,
             vl_tot_cont_rec_pis      TYPE /tmf/de_dec_25_6,
             vl_tot_cont_nc_per_cof   TYPE /tmf/de_dec_25_6,
             vl_tot_cred_desc_cof     TYPE /tmf/de_dec_25_6,
             vl_tot_cred_desc_ant_cof TYPE /tmf/de_dec_25_6,
             vl_tot_cont_nc_dev_cof   TYPE /tmf/de_dec_25_6,
             vl_ret_nc_cof            TYPE /tmf/de_dec_25_6,
             vl_out_ded_nc_cof        TYPE /tmf/de_dec_25_6,
             vl_cont_nc_rec_cof       TYPE /tmf/de_dec_25_6,
             vl_tot_cont_cum_per_cof  TYPE /tmf/de_dec_25_6,
             vl_ret_cum_cof           TYPE /tmf/de_dec_25_6,
             vl_out_ded_cum_cof       TYPE /tmf/de_dec_25_6,
             vl_cont_cum_rec_cof      TYPE /tmf/de_dec_25_6,
             vl_tot_cont_rec_cof      TYPE /tmf/de_dec_25_6,
           END OF ty_registro_m200_m600 .

    "1100/1500
    TYPES: BEGIN OF ty_registro_1100_1500,
             mandt                TYPE char3,
             empresa              TYPE char4,
             filial               TYPE char4,
             dt_lancto            TYPE char8,
             tp_imp               TYPE char10,
             per_apu_cred         TYPE char6,
             orig_cred            TYPE char2,
             cnpj_suc             TYPE char14,
             cod_cred             TYPE char3,
             vl_cred_apu          TYPE /tmf/de_dec_25_6,
             vl_cred_ext_apu      TYPE /tmf/de_dec_25_6,
             vl_tot_cred_apu      TYPE /tmf/de_dec_25_6,
             vl_cred_desc_pa_ant  TYPE /tmf/de_dec_25_6,
             vl_cred_per_pa_ant   TYPE /tmf/de_dec_25_6,
             vl_cred_dcomp_pa_ant TYPE /tmf/de_dec_25_6,
             sd_cred_disp_efd     TYPE /tmf/de_dec_25_6,
             vl_cred_desc_efd     TYPE /tmf/de_dec_25_6,
             vl_cred_per_efd      TYPE /tmf/de_dec_25_6,
             vl_cred_dcomp_efd    TYPE /tmf/de_dec_25_6,
             vl_cred_trans        TYPE /tmf/de_dec_25_6,
             vl_cred_out          TYPE /tmf/de_dec_25_6,
             sld_cred_fim         TYPE /tmf/de_dec_25_6,
           END OF ty_registro_1100_1500 .

    "1300/1700
    TYPES: BEGIN OF ty_registro_1300_1700,
             mandt       TYPE char3,
             empresa     TYPE char4,
             filial      TYPE char4,
             dt_lancto   TYPE char8,
             tp_imp      TYPE char6,
             ind_nat_ret TYPE char3,
             pr_rec_ret  TYPE char6,
             vl_ret_apu  TYPE /tmf/de_dec_25_6,
             "vl_ret_per  TYPE /tmf/de_dec_25_6,    "JCR #14741 10/05/2022
             vl_ret_ded  TYPE /tmf/de_dec_25_6,     "JCR #14741 10/05/2022
             sld_ret     TYPE /tmf/de_dec_25_6,
           END OF ty_registro_1300_1700 .

    "Totais Registros Apuração
    TYPES: BEGIN OF ty_totais_registros,
             mandt              TYPE char3,
             empresa            TYPE char4,
             filial             TYPE char4,
             per_ref            TYPE char6,
             ordem              TYPE int4,
             registro           TYPE c LENGTH 60,
             vl_cofins_debitos  TYPE /tmf/de_dec_25_6,
             vl_cofins_creditos TYPE /tmf/de_dec_25_6,
             vl_pis_debitos     TYPE /tmf/de_dec_25_6,
             vl_pis_creditos    TYPE /tmf/de_dec_25_6,
           END OF ty_totais_registros .

    "NATUREZA DE RECEITA ISENTA Sem parâmetros na tabela ZDPFISC_EFD_CONTRIB_REC_ISENTAS    "JCR #15646 25/06/2022
    TYPES: BEGIN OF ty_nat_isenta_sem_param,
             mandt(3)      TYPE c,
             empresa(4)    TYPE c,
             nf_id(10)     TYPE c,
             cst_pis(2)    TYPE c,
             cst_cofins(2) TYPE c,
             cod_item(60)  TYPE c,
             cod_ncm(10)   TYPE c,
             cod_cta(60)   TYPE c,
             cod_part(60)  TYPE c,
             aliq_pis(16)  TYPE p DECIMALS 2,
             vl_oper(16)   TYPE p DECIMALS 2,
             nat_rec(3)    TYPE c,
           END OF ty_nat_isenta_sem_param.

    "saidas shadows
    TYPES: tt_registro_0111        TYPE TABLE OF ty_registro_0111,
           tt_registro_m105        TYPE TABLE OF ty_registro_m105,
           tt_registro_m505        TYPE TABLE OF ty_registro_m505,
           tt_registro_m210_m610   TYPE TABLE OF ty_registro_m210_m610,
           tt_registro_m400        TYPE TABLE OF ty_registro_m400,
           tt_registro_m410        TYPE TABLE OF ty_registro_m410,
           tt_registro_m800        TYPE TABLE OF ty_registro_m800,
           tt_registro_m810        TYPE TABLE OF ty_registro_m810,
           tt_registro_m100_m500   TYPE TABLE OF ty_registro_m100_m500,
           tt_registro_m200_m600   TYPE TABLE OF ty_registro_m200_m600,
           tt_registro_1100_1500   TYPE TABLE OF ty_registro_1100_1500,
           tt_registro_1300_1700   TYPE TABLE OF ty_registro_1300_1700,
           tt_totais_registros     TYPE TABLE OF ty_totais_registros,
           tt_nat_isenta_sem_param TYPE TABLE OF ty_nat_isenta_sem_param.   "JCR #15646 25/06/2022

    "-----------------------------------------------------------------------------------------------
    " Tabelas de retorno de dados
    "-----------------------------------------------------------------------------------------------
    DATA: lt_registro_0111        TYPE tt_registro_0111,
          lt_registro_m105        TYPE tt_registro_m105,
          lt_registro_m505        TYPE tt_registro_m505,
          lt_registro_m210_m610   TYPE tt_registro_m210_m610,
          lt_registro_m410        TYPE tt_registro_m410,
          lt_registro_m400        TYPE tt_registro_m400,
          lt_registro_m810        TYPE tt_registro_m810,
          lt_registro_m800        TYPE tt_registro_m800,
          lt_registro_m100_m500   TYPE tt_registro_m100_m500,
          lt_registro_m200_m600   TYPE tt_registro_m200_m600,
          lt_registro_1100_1500   TYPE tt_registro_1100_1500,
          lt_registro_1300_1700   TYPE tt_registro_1300_1700,
          lt_totais_registros     TYPE tt_totais_registros,
          lt_nat_isenta_sem_param TYPE tt_nat_isenta_sem_param.     "JCR #15646 25/06/2022

    METHODS alter_sequence
      IMPORTING
        iv_bukrs    TYPE /tmf/de_empresa
        iv_branch   TYPE /tmf/de_estabelecimento
        iv_sequence TYPE string
      RAISING
        cx_sql_exception .

    METHODS pre_proc_0200_aliq_icms
      IMPORTING
        iv_view_name     TYPE /tmf/de_view_name
        it_placeholders  TYPE /dpf/cl_db_select=>mty_placeholder_table
        iv_table_name    TYPE string
        iv_bukrs         TYPE /tmf/de_empresa
        iv_branch        TYPE /tmf/de_estabelecimento
        iv_no_auto_mandt TYPE flag OPTIONAL
        iv_cols          TYPE string OPTIONAL
        iv_where         TYPE string OPTIONAL
        iv_raw_columns   TYPE string OPTIONAL
      RAISING
        cx_shdb_exception
        cx_sql_exception
        /dpf/cx_text_message
        /tmf/cx_register_exception.

    METHODS verificar_permissao_campo
      IMPORTING
        VALUE(i_t_range_campos) LIKE s_chkcmp
      RETURNING
        VALUE(o_permissao)      LIKE it_permissao .

    METHODS obter_tooltip
      IMPORTING
        VALUE(i_t_range_id_dica) LIKE s_tooltp
      RETURNING
        VALUE(o_tooltip)         LIKE it_tooltip .

    METHODS executa_blocom_apuracao
      IMPORTING
        VALUE(iv_mandt)                TYPE char3
        VALUE(iv_empresa)              TYPE char4
        VALUE(iv_filial)               TYPE char4
        VALUE(iv_dt_ini)               TYPE sy-datum
        VALUE(iv_dt_fin)               TYPE sy-datum
        VALUE(iv_nfs_consolidadas)     TYPE char1
        VALUE(iv_pagina)               TYPE int4
        VALUE(iv_registro_excel)       TYPE char50
        VALUE(iv_inc_tributaria)       TYPE char1
        VALUE(iv_retido_fonte)         TYPE char1
        VALUE(iv_ledger)               TYPE char2
        VALUE(iv_f600_only_shadow)     TYPE abap_bool
      EXPORTING
        VALUE(et_registro_0111)        TYPE tt_registro_0111
        VALUE(et_registro_m105)        TYPE tt_registro_m105
        VALUE(et_registro_m505)        TYPE tt_registro_m505
        VALUE(et_registro_m210_m610)   TYPE tt_registro_m210_m610
        VALUE(et_registro_m410)        TYPE tt_registro_m410
        VALUE(et_registro_m400)        TYPE tt_registro_m400
        VALUE(et_registro_m810)        TYPE tt_registro_m810
        VALUE(et_registro_m800)        TYPE tt_registro_m800
        VALUE(et_registro_m100_m500)   TYPE tt_registro_m100_m500
        VALUE(et_registro_m200_m600)   TYPE tt_registro_m200_m600
        VALUE(et_registro_1100_1500)   TYPE tt_registro_1100_1500
        VALUE(et_registro_1300_1700)   TYPE tt_registro_1300_1700
        VALUE(et_totais_registros)     TYPE tt_totais_registros
        VALUE(et_nat_isenta_sem_param) TYPE tt_nat_isenta_sem_param.

    METHODS proc_desc_lc116
      IMPORTING
        VALUE(iv_mandt)   TYPE /tmf/de_mandt
        VALUE(iv_empresa) TYPE /tmf/de_empresa
        VALUE(iv_filial)  TYPE /tmf/de_estabelecimento
        VALUE(iv_ano)     TYPE /tmf/de_ano
        VALUE(iv_mes)     TYPE /tmf/de_mes.


ENDCLASS.

CLASS /dpf/cl_pre_proc_sped_pco IMPLEMENTATION.


  METHOD alter_sequence.

    DATA: lv_sequence  TYPE string.

    DATA(lo_db_select) = NEW /dpf/cl_db_select(
      iv_empresa = iv_bukrs
      iv_filial  = iv_branch
    ).

    IF iv_sequence IS NOT INITIAL.
      lv_sequence = 'ALTER SEQUENCE "DPFISC"."' && iv_sequence && '"  RESTART WITH 00001'.
    ENDIF.

    DATA(lo_db_insert) = NEW /dpf/cl_db_insert( ).

    lo_db_insert->execute_query(
      EXPORTING
        iv_sql = lv_sequence
    ).

  ENDMETHOD.


  METHOD executa_relatorio.

    TYPES: ty_t_placeholder TYPE STANDARD TABLE OF /dpf/cl_db_select=>mty_placeholder WITH EMPTY KEY.

    TYPES: BEGIN OF y_log,
             mensagem TYPE string,
           END OF y_log.

    DATA: lo_db_select TYPE REF TO /dpf/cl_db_select,
          lo_db_insert TYPE REF TO /dpf/cl_db_insert,
          lt_0111      TYPE TABLE OF /dpf/v0111,
          lt_f100      TYPE TABLE OF /dpf/vf100,
          lt_f130      TYPE TABLE OF /dpf/vf130,
          lt_f600      TYPE TABLE OF /dpf/vf600,
          lt_d101d105  TYPE TABLE OF /dpf/vd101d105,
          lt_d101nfit  TYPE TABLE OF /dpf/vd101nfitem,
          lt_vc110u    TYPE TABLE OF /dpf/vc110u,
          lt_vc110c    TYPE TABLE OF /dpf/vc110c,
          lv_where     TYPE string,
          lt_log       TYPE STANDARD TABLE OF y_log,
          wa_log       TYPE y_log,
          lt_arquivo   TYPE TABLE OF string,
          lv_texto     TYPE string,
          lt_item_icms TYPE TABLE OF /tmf/d_item_icms, "BJM - #7652
          p_blocoi     TYPE flag,
          p_0111       TYPE flag,
          p_0200ai     TYPE flag,
          p_0200cl     TYPE flag,
          p_0200ti     TYPE flag,
          p_0200cb     TYPE flag,  "Checkbox - Tipo de Item p/ NF sem Código de Item
          p_0200tp     TYPE char2, "Campo Tipo de Item p/ NF sem Código de Item
          p_f100       TYPE flag,
          p_f130       TYPE flag,
          p_f600       TYPE flag,
          p_d101       TYPE flag,
          p_c100       TYPE flag,
          p_c110       TYPE flag,
          p_altncm     TYPE flag,
          p_codcta     TYPE flag,                           "#11298
          p_criado     TYPE flag,
          p_crerro     TYPE flag,
          p_json       TYPE flag,
          p_arqtom     TYPE flag,
          p_verper     TYPE flag,
          p_descr      TYPE flag,   "17376
          p_mandt      TYPE /tmf/de_mandt,
          p_bukrs      TYPE /tmf/de_empresa,
          p_branch     TYPE /tmf/de_estabelecimento,
          p_ano        TYPE /tmf/de_ano,
          p_mes        TYPE /tmf/de_mes,
          p_dt_inv     TYPE sy-datum,
          p_ap_inv     TYPE flag,
          p_dtret(1)   TYPE c,
          p_ledger     TYPE /tmf/de_ledger,
          p_estbal     TYPE string,
          p_cols       TYPE string,
          p_colsi      TYPE string, "Exclusivo para o Bloco I
          perref       TYPE string,
          p_blocom     TYPE flag,
          p_blcoma     TYPE flag,
          p_nf_con     TYPE flag,
          p_retfon     TYPE flag,
          p_inctri     TYPE flag,
          p_ledgea     TYPE /tmf/de_ledger. "Bloco M - Apuração

    FIELD-SYMBOLS: <fst_select_option> TYPE ANY TABLE,
                   <fs_select_option>  TYPE any,
                   <fs_parameter>      TYPE any,
                   <fst_output>        TYPE ANY TABLE,
                   <ft_item_icms>      TYPE any. "BJM - #7652

    DATA: lv_texto_tpe   TYPE string,
          lw_placeholder TYPE /dpf/cl_db_select=>mty_placeholder,
          lv_sql         TYPE string,
          lv_field_name  TYPE string,
          lv_view_name   TYPE /tmf/de_view_name,
          lv_table_name  TYPE string,
          lv_bin_fsize   TYPE i,
          lv_dt_ini      TYPE sy-datum,
          lv_dt_fin      TYPE sy-datum,
          sw_date        TYPE RANGE OF sy-datum,
          lv_string      TYPE string,
          lv_file_name   TYPE char50.

    "-----------------------------------------------------------------------------------------------
    " Converter parâmetros de tela para o formato do abap
    "-----------------------------------------------------------------------------------------------
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

    "-----------------------------------------------------------------------------------------------
    " Definir Data Inicial e Data Final do período
    "-----------------------------------------------------------------------------------------------
    lv_dt_ini = p_ano && p_mes && '01'.

    CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
      EXPORTING
        day_in       = lv_dt_ini
      IMPORTING
        end_of_month = lv_dt_fin.

    "-----------------------------------------------------------------------------------------------
    " Preencher Placeholder
    "-----------------------------------------------------------------------------------------------
    DATA(lt_placeholder) = VALUE ty_t_placeholder(
      ( placeholder_name = 'P_MANDT'
        value            = p_mandt )
      ( placeholder_name = 'P_EMPRESA'
        value            = p_bukrs )
      ( placeholder_name = 'P_FILIAL'
        value            = p_branch )
      ( placeholder_name = 'P_ANO'
        value            = p_ano )
      ( placeholder_name = 'P_MES'
        value            = p_mes )
      ( placeholder_name = 'P_DT_INI'
        value            = lv_dt_ini )
      ( placeholder_name = 'P_DT_FIN'
        value            = lv_dt_fin )
      ( placeholder_name = 'P_APRES_INV'
        value            = p_ap_inv )
      ( placeholder_name = 'P_DT_INV'
        value            = p_dt_inv )
      ( placeholder_name = 'P_TIPO_ITEM'
        value            = p_0200tp )
    ).

    GET BADI me->go_badi.

    " usado pelo F100 e TOM
    DATA lv_ymde TYPE sy-datum.
    DATA lv_ymdate TYPE sy-datum.
    lv_ymde = p_ano && p_mes && '01'.

    CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
      EXPORTING
        day_in       = lv_ymde
      IMPORTING
        end_of_month = lv_ymdate.

    "-----------------------------------------------------------------------------------------------
    " Verifica permissão e dicas dos flags da tela
    "-----------------------------------------------------------------------------------------------
    IF p_json = 'X'.

      "Verificar permissão dos flags da tela
      IF s_chkcmp IS NOT INITIAL.
        CREATE DATA eo_output_data LIKE it_permissao.
        ASSIGN eo_output_data->* TO FIELD-SYMBOL(<fs_retorno>).

        <fs_retorno> = me->verificar_permissao_campo(
          EXPORTING
            i_t_range_campos = s_chkcmp[]
        ).

        RETURN. "Não continua o processamento procedural abaixo
      ENDIF.

      "Buscar o "tooltip" dos campos da tela
      IF s_tooltp IS NOT INITIAL.
        CREATE DATA eo_output_data LIKE it_tooltip.
        ASSIGN eo_output_data->* TO FIELD-SYMBOL(<fs_dica>).

        <fs_dica> = me->obter_tooltip(
          EXPORTING
            i_t_range_id_dica = s_tooltp[]
        ).

        RETURN. "Não continua o processamento procedural abaixo
      ENDIF.

    ENDIF.

    "-----------------------------------------------------------------------------------------------
    " Verifica Status do Periodo Fiscal
    "-----------------------------------------------------------------------------------------------
    IF p_verper = abap_true.

      " JCR #14656 27/04/2022 Ini
      IF p_branch IS NOT INITIAL.
        DATA(lv_filial) = p_branch.
      ELSE.
        SELECT SINGLE estabelecimento
          INTO lv_filial
          FROM /tmf/v_emp_fed   ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
         WHERE empresa   = p_bukrs
           AND eh_matriz = abap_true.
      ENDIF.

      me->verifica_periodo_fiscal_aberto(
        EXPORTING
          iv_empresa               = p_bukrs                                  " Empresa
          iv_filial                = lv_filial                                " Estabelecimento
          iv_ano                   = p_ano                                    " Exercício
          iv_mes                   = p_mes                                    " Mês do exercício
        IMPORTING
          ev_cod_status            = ls_retorno_periodo-cod_status            " Status do Período Fiscal
          ev_desc_status           = ls_retorno_periodo-desc_status           " Descrição do Status
          ev_periodo_fiscal_aberto = ls_retorno_periodo-periodo_fiscal_aberto " Período Fiscal Aberto ?
      ).

      ls_retorno_periodo-empresa = p_bukrs.
      ls_retorno_periodo-filial = lv_filial.

      " I - MBA - #16336 - 29.08.2022
      SELECT SINGLE @abap_true
        FROM /dpf/v_exit  ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
       WHERE nome  = 'PRE_PROC_PCO_STATUSPERIODO_NESTLE'
         AND ativo = @abap_true
        INTO @DATA(lv_exit_periodo_nestle).

      IF lv_exit_periodo_nestle = abap_true.
        CASE ls_retorno_periodo-cod_status.
          WHEN '' OR '000' OR '100'.
            "Para Nestçé considera esses 3 status como aberto
            ls_retorno_periodo-periodo_fiscal_aberto = abap_true.
          WHEN OTHERS.
            ls_retorno_periodo-periodo_fiscal_aberto = abap_false.
        ENDCASE.
      ENDIF.
      " F - MBA - #16336 - 29.08.2022

      " JCR #14656 27/04/2022 Fim

      CREATE DATA eo_output_data LIKE ls_retorno_periodo.
      ASSIGN eo_output_data->* TO FIELD-SYMBOL(<fs_retorno_periodo>).
      <fs_retorno_periodo> = ls_retorno_periodo.

      RETURN.

    ENDIF.

    "-----------------------------------------------------------------------------------------------
    " Instanciar classe do TOM
    "-----------------------------------------------------------------------------------------------
    IF p_arqtom = abap_true.

      DATA(lo_report_run) = /dpf/cl_tom_integration=>create_or_running(
         i_empresa     = p_bukrs
         i_filial      = p_branch
         i_periodo_ini = CONV #( lv_ymde )
         i_periodo_fin = CONV #( lv_ymdate )
         i_report_id   = me->mv_report_id
         i_run_id      = i_run_id
      ).

      APPEND 'SPED Pis/Cofins - Pré Processamento.' TO lt_arquivo.
      APPEND '' TO lt_arquivo.
      CONCATENATE 'Empresa: ' p_bukrs INTO lv_texto RESPECTING BLANKS.
      APPEND lv_texto TO lt_arquivo.
      CONCATENATE 'Filial: ' p_branch INTO lv_texto RESPECTING BLANKS.
      APPEND lv_texto TO lt_arquivo.
      CONCATENATE 'Ano de Referência: ' p_ano INTO lv_texto RESPECTING BLANKS.
      APPEND lv_texto TO lt_arquivo.
      CONCATENATE 'Mês de Referência: ' p_mes INTO lv_texto RESPECTING BLANKS.
      APPEND lv_texto TO lt_arquivo.
      APPEND '' TO lt_arquivo.

    ENDIF.

    "=========================================================================================
    "
    "
    "           Bloco I
    "
    "
    "=========================================================================================
    IF p_blocoi IS NOT INITIAL.

      lv_view_name  = '/DPF/VBLOCOI'.
      lv_table_name = '/TMF/D_RED_DED_I'. "ALTERAR

      CONCATENATE p_ano p_mes INTO perref.

      lw_placeholder-placeholder_name = 'P_LEDGER'.
      lw_placeholder-value = p_ledger.
      APPEND lw_placeholder TO lt_placeholder.
      lw_placeholder-placeholder_name = 'P_ESTR_BALANCO'.
      lw_placeholder-value = p_estbal.
      APPEND lw_placeholder TO lt_placeholder.

      DELETE FROM /tmf/d_red_ded_i CLIENT SPECIFIED
       WHERE mandt   = p_mandt
         AND empresa = p_bukrs
         AND filial  = p_branch
         AND per_ref = perref.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          iv_cols         = p_colsi " Na IRB, esta perdendo as referencias de uma coluna
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'BLOCO I -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'BLOCO I -> ERRO ' TO lt_arquivo.
      ENDIF.

      DELETE lt_placeholder  WHERE placeholder_name = 'P_LEDGER'.
      DELETE lt_placeholder  WHERE placeholder_name = 'P_ESTR_BALANCO'.

    ENDIF.

    "=========================================================================================
    "
    "
    "           0111
    "
    "
    "=========================================================================================
    IF p_0111 IS NOT INITIAL.

      lv_view_name  = '/DPF/V0111'.
      lv_table_name = '/TMF/D_REC_BRUTA'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND '0111 -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND '0111 -> ERRO ' TO lt_arquivo.
      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           #7920 - ALTERAÇÃO NCM
    "
    "
    "=========================================================================================
    IF p_altncm IS NOT INITIAL.

      lv_view_name  = '/DPF/VALTERNCM'.
      lv_table_name = '/TMF/D_NF_ITEM'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'Alteracao NCM -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'Alteracao NCM -> ERRO ' TO lt_arquivo.
      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           #4926 - Execução do 0200 ALIQ ICMS no PCO para com FILIAL opcional
    "
    "
    "=========================================================================================
    IF p_0200ai IS NOT INITIAL.

      lv_view_name  = '/DPF/V0200ALIQ'.
      lv_table_name = '/TMF/D_ITEM_ICMS'.

      me->pre_proc_0200_aliq_icms(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND '0200 - ALIQ ICMS -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND '0200 - ALIQ ICMS -> ERRO ' TO lt_arquivo.
      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           0200 - Cod_List/Cod_Item - preenche duas shadows
    "
    "
    "=========================================================================================
    IF p_0200cl IS NOT INITIAL.

      "engdb_custom.nestle.db.sped_pis_cofins.0200LISTPROD/0200_CODLST
      lv_view_name  = '/DPF/V0200CODLST'.
      lv_table_name = '/TMF/D_ITEM'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      p_criado = abap_true.
      APPEND '0200-Cod_List -> OK ' TO lt_arquivo.

      "engdb_custom.nestle.db.sped_pis_cofins.0200LISTPROD/0200_CODPRD
      lv_view_name  = '/DPF/V0200CODPRD'.
      lv_table_name = '/TMF/D_NF_ITEM'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      p_criado = abap_true.
      APPEND '0200-Cod_item -> OK ' TO lt_arquivo.

    ENDIF.

    "=========================================================================================
    "
    "
    "           #5687 - Bloco M
    "
    "
    "=========================================================================================
    IF NOT p_blocom IS INITIAL.

      DATA(l_periodo) = |{ p_mes }/{ p_ano }|.
      lw_placeholder-placeholder_name = 'P_PERIODO'.
      lw_placeholder-value = l_periodo.
      APPEND lw_placeholder TO lt_placeholder.

      lv_view_name  = '/DPF/V_M110_PRE'.
      lv_table_name = '/TMF/D_AJ_CRED_P'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).
      COMMIT WORK AND WAIT.

      lv_view_name  = '/DPF/V_M510_PRE'.
      lv_table_name = '/TMF/D_AJ_CRED_C'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).
      COMMIT WORK AND WAIT.

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'Bloco M -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'Bloco M -> ERRO ' TO lt_arquivo.
      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           Bloco M - Apuração
    "
    "
    "=========================================================================================
    IF NOT p_blcoma IS INITIAL.

      "JCR #MAH-134 13/05/2024 Ini
      "Redeterminar o P_MANDT para casos em que existem mais de um mandante diferente do
      " mandante padrão do sistema. O MANDT das tabelas do Bloco M precisam estar configurados
      " na Empresa/Filial que é usada na deteminação do MANDT nos SELECTs da /TMF/PCO
      SELECT SINGLE FROM /tmf/v_emp_fed       ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
      FIELDS mandt_tdf
       WHERE empresa           = @p_bukrs
         AND ( estabelecimento = @p_branch OR eh_matriz = @abap_true )
       INTO @DATA(lv_mandt).

      IF lv_mandt IS NOT INITIAL.
        p_mandt = lv_mandt.
      ENDIF.
      "JCR #MAH-134 13/05/2024 Fim

      "NEST-567 - 11.12.2024 - WANDER - Tratar flag TDF_PCO_F600_ONLY_SHADOW - SP18-OSS 14
      "Copiado do método SET_F600_ONLY_SHADOW da classe /TMF/CL_SPED_PARAMETERS_PCO
      DATA(lv_f600_only_shadow) = abap_false.

      SELECT SINGLE FROM tvarvc
      FIELDS *
       WHERE name = 'TDF_PCO_F600_ONLY_SHADOW'
        INTO @DATA(ls_force_f600_shadow).

      IF ls_force_f600_shadow IS NOT INITIAL
        AND ls_force_f600_shadow-low = abap_true.
        lv_f600_only_shadow = abap_true.
      ELSE.

        SELECT SINGLE FROM /tmf/d_whtx_type
        FIELDS tax_type
          INTO @DATA(lv_tax_type).

        IF lv_tax_type IS NOT INITIAL.
          lv_f600_only_shadow = abap_true.
        ENDIF.
      ENDIF.

      me->executa_blocom_apuracao(
        EXPORTING
          iv_mandt                = p_mandt
          iv_empresa              = p_bukrs
          iv_filial               = p_branch
          iv_dt_ini               = lv_dt_ini
          iv_dt_fin               = lv_dt_fin
          iv_nfs_consolidadas     = p_nf_con
          iv_pagina               = 0
          iv_registro_excel       = ''
          iv_inc_tributaria       = p_inctri
          iv_retido_fonte         = p_retfon
          iv_ledger               = p_ledgea
          iv_f600_only_shadow     = lv_f600_only_shadow   "NEST-567 - 11.12.2024 - WANDER
        IMPORTING
          et_registro_0111        = lt_registro_0111
          et_registro_m105        = lt_registro_m105
          et_registro_m505        = lt_registro_m505
          et_registro_m210_m610   = lt_registro_m210_m610
          et_registro_m410        = lt_registro_m410
          et_registro_m400        = lt_registro_m400
          et_registro_m810        = lt_registro_m810
          et_registro_m800        = lt_registro_m800
          et_registro_m100_m500   = lt_registro_m100_m500
          et_registro_m200_m600   = lt_registro_m200_m600
          et_registro_1100_1500   = lt_registro_1100_1500
          et_registro_1300_1700   = lt_registro_1300_1700
          et_totais_registros     = lt_totais_registros
          et_nat_isenta_sem_param = lt_nat_isenta_sem_param    "JCR #15646 25/06/2022
      ).

      "Gravando as Shadows
      "Apagar shadows var shadowsBlocoM
      "0111
      DELETE FROM /tmf/d_rec_bruta CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M105
      DELETE FROM /tmf/d_credper_p CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M505
      DELETE FROM /tmf/d_credper_c CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M210/M610
      DELETE FROM /tmf/d_cont_dete CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M410
      DELETE FROM /tmf/d_drecise_p CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M400
      DELETE FROM /tmf/d_recisen_p CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M810
      DELETE FROM /tmf/d_drecise_c CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M800
      DELETE FROM /tmf/d_recisen_c CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M100/M500
      DELETE FROM /tmf/d_cred_per CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "M200/M600
      DELETE FROM /tmf/d_cont_impo CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      "1100/1500
      DELETE FROM /tmf/d_credfisc CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND dt_lancto = lv_dt_fin.

      CONCATENATE lv_dt_fin+4(2) lv_dt_fin(4) INTO p_dt_rec.

      "1300/1700
      DELETE FROM /tmf/d_vlrretfon CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      "AND dt_lancto = p_dataat.
      AND pr_rec_ret = p_dt_rec.

      "Totais Registros Apuração
      DELETE FROM /dpf/d_pco_apur CLIENT SPECIFIED
      WHERE mandt = p_mandt
      AND empresa = p_bukrs
      AND per_ref = lv_dt_fin(6).

      COMMIT WORK AND WAIT.

      "0111
      IF lt_registro_0111[] IS NOT INITIAL.
        DATA: shw_m111        TYPE TABLE OF  /tmf/d_rec_bruta.
        MOVE-CORRESPONDING lt_registro_0111[] TO shw_m111.
        "INSERT /tmf/d_rec_bruta USING CLIENT @p_mandt FROM TABLE @shw_m111.
        MODIFY /tmf/d_rec_bruta USING CLIENT @p_mandt FROM TABLE @shw_m111.
      ENDIF.

      "M105
      IF lt_registro_m105[] IS NOT INITIAL.
        DATA: shw_m105        TYPE TABLE OF /tmf/d_credper_p.
        MOVE-CORRESPONDING lt_registro_m105[] TO shw_m105.
        "INSERT /tmf/d_credper_p USING CLIENT @p_mandt FROM TABLE @shw_m105  .
        MODIFY /tmf/d_credper_p USING CLIENT @p_mandt FROM TABLE @shw_m105  .
      ENDIF.

      "M505
      IF lt_registro_m505[] IS NOT INITIAL.
        DATA: shw_m505        TYPE TABLE OF /tmf/d_credper_c.
        MOVE-CORRESPONDING lt_registro_m505[] TO shw_m505.
        "INSERT /tmf/d_credper_c USING CLIENT @p_mandt FROM TABLE @shw_m505  .
        MODIFY /tmf/d_credper_c USING CLIENT @p_mandt FROM TABLE @shw_m505  .
      ENDIF.

      "M210/M610
      IF lt_registro_m210_m610[] IS NOT INITIAL.
        DATA: shw_m210        TYPE TABLE OF /tmf/d_cont_dete.
        MOVE-CORRESPONDING lt_registro_m210_m610[] TO shw_m210.
        "INSERT /tmf/d_cont_dete USING CLIENT @p_mandt FROM TABLE @shw_m210  .
        MODIFY /tmf/d_cont_dete USING CLIENT @p_mandt FROM TABLE @shw_m210  .
      ENDIF.

      "M410
      IF lt_registro_m410[] IS NOT INITIAL.
        DATA: shw_m410        TYPE TABLE OF /tmf/d_drecise_p.
        DATA: ls_shw_m410        TYPE  /tmf/d_drecise_p.
        MOVE-CORRESPONDING lt_registro_m410[] TO shw_m410.

        LOOP AT shw_m410 INTO  ls_shw_m410 .
          ls_shw_m410-cod_cta_parent = ls_shw_m410-cod_cta.
          ls_shw_m410-num_item       = ls_shw_m410-nat_rec.
          ls_shw_m410-nat_rec        = ls_shw_m410-nat_rec.
          MODIFY shw_m410 FROM  ls_shw_m410  INDEX sy-tabix.
        ENDLOOP.

        "INSERT /tmf/d_drecise_p using client @p_mandt from table @shw_m410  .
        MODIFY /tmf/d_drecise_p USING CLIENT @p_mandt FROM TABLE @shw_m410  .
      ENDIF.

      "M400
      IF lt_registro_m400[] IS NOT INITIAL.
        DATA: shw_m400        TYPE TABLE OF /tmf/d_recisen_p.
        MOVE-CORRESPONDING lt_registro_m400[] TO shw_m400.
        "INSERT /tmf/d_recisen_p USING CLIENT @p_mandt FROM TABLE @shw_m400  .
        MODIFY /tmf/d_recisen_p USING CLIENT @p_mandt FROM TABLE @shw_m400  .
      ENDIF.

      "M810
      IF lt_registro_m810[] IS NOT INITIAL.
        DATA: shw_m810        TYPE TABLE OF /tmf/d_drecise_c.
        DATA: ls_shw_m810     TYPE  /tmf/d_drecise_c .
        MOVE-CORRESPONDING lt_registro_m810[] TO shw_m810.

        LOOP AT shw_m810 INTO  ls_shw_m810 .
          ls_shw_m810-cod_cta_parent = ls_shw_m810-cod_cta.
          ls_shw_m810-num_item       = ls_shw_m810-nat_rec.
          ls_shw_m810-nat_rec        = ls_shw_m810-nat_rec.
          MODIFY shw_m810 FROM  ls_shw_m810  INDEX sy-tabix.
        ENDLOOP.

        "INSERT /tmf/d_drecise_c using client @p_mandt from table @shw_m810  .
        MODIFY /tmf/d_drecise_c USING CLIENT @p_mandt FROM TABLE @shw_m810  .
      ENDIF.

      "M800
      IF lt_registro_m800[] IS NOT INITIAL.
        DATA: shw_m800        TYPE TABLE OF /tmf/d_recisen_c.
        MOVE-CORRESPONDING lt_registro_m800[] TO shw_m800.
        "INSERT /tmf/d_recisen_c using client @p_mandt from table @shw_m800  .
        MODIFY /tmf/d_recisen_c USING CLIENT @p_mandt FROM TABLE @shw_m800  .
      ENDIF.

      "M100/M500
      IF lt_registro_m100_m500[] IS NOT INITIAL.
        DATA: shw_m100        TYPE TABLE OF /tmf/d_cred_per.
        MOVE-CORRESPONDING lt_registro_m100_m500[] TO shw_m100.
        "INSERT /tmf/d_cred_per USING CLIENT @p_mandt FROM TABLE @shw_m100  .
        MODIFY /tmf/d_cred_per USING CLIENT @p_mandt FROM TABLE @shw_m100  .
      ENDIF.

      "M200/M600
      IF lt_registro_m200_m600[] IS NOT INITIAL.
        DATA: shw_m200        TYPE TABLE OF /tmf/d_cont_impo.
        MOVE-CORRESPONDING lt_registro_m200_m600[] TO shw_m200.
        "INSERT /tmf/d_cont_impo USING CLIENT @p_mandt FROM TABLE @shw_m200  .
        MODIFY /tmf/d_cont_impo USING CLIENT @p_mandt FROM TABLE @shw_m200  .
      ENDIF.

      "1100/1500
      IF lt_registro_1100_1500[] IS NOT INITIAL.
        DATA: shw_1100        TYPE TABLE OF /tmf/d_credfisc.
        MOVE-CORRESPONDING lt_registro_1100_1500[] TO shw_1100.
        MODIFY /tmf/d_credfisc USING CLIENT @p_mandt FROM TABLE @shw_1100 .
      ENDIF.

      "1300/1700
      IF lt_registro_1300_1700[] IS NOT INITIAL.
        DATA: shw_1300        TYPE TABLE OF /tmf/d_vlrretfon.
        MOVE-CORRESPONDING lt_registro_1300_1700[] TO shw_1300.
        "INSERT /tmf/d_vlrretfon USING CLIENT @p_mandt FROM TABLE @shw_1300  .
        MODIFY /tmf/d_vlrretfon USING CLIENT @p_mandt FROM TABLE @shw_1300  .
      ENDIF.

      "Totais Registros Apuração
      IF lt_totais_registros[] IS NOT INITIAL.
        DATA: shw_totais      TYPE TABLE OF /dpf/d_pco_apur.
        MOVE-CORRESPONDING lt_totais_registros[] TO shw_totais.
        "INSERT /dpf/d_pco_apur USING CLIENT @p_mandt FROM TABLE @shw_totais  .
        MODIFY /dpf/d_pco_apur USING CLIENT @p_mandt FROM TABLE @shw_totais  .
      ENDIF.

      "Log processamento Bloco M
      DATA: ls_logblocom TYPE /dpf/d_pcoblocom.
      ls_logblocom-mandt            = p_mandt.
      ls_logblocom-empresa          = p_bukrs.
      ls_logblocom-filial           = p_branch.
      ls_logblocom-per_ref          = lv_dt_fin(6).
      ls_logblocom-data             = sy-datlo.
      ls_logblocom-hora             = sy-timlo.
      ls_logblocom-usuario          = sy-uname.
      ls_logblocom-nfs_consolidadas = p_nf_con.
      ls_logblocom-inc_tributaria   = p_inctri.
      ls_logblocom-retido_fonte     = p_retfon.
      ls_logblocom-ledger           = p_ledgea.
      MODIFY /dpf/d_pcoblocom CLIENT SPECIFIED FROM ls_logblocom.

      COMMIT WORK AND WAIT.
      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'Bloco M - Apuração -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'Bloco M - Apuração -> ERRO ' TO lt_arquivo.
      ENDIF.

      IF lt_nat_isenta_sem_param IS NOT INITIAL.

        " Converter a Tabela Interna em Excel
        TRY.
            DATA(lv_excel) = /dpf/cl_file_tools=>build_xlsx_from_internal_table(
              it_data           = lt_nat_isenta_sem_param
              iv_worksheet_name = 'Planilha1'
            ).
          CATCH /dpf/cx_excel INTO DATA(lo_cx_excel).
            DATA(lv_text) = lo_cx_excel->get_text( ).
        ENDTRY.

        lv_file_name = 'Natureza Receita Isenta Sem Parametro' && | | && p_bukrs && | | && lv_dt_fin(4) && |-| && lv_dt_fin+4(2).

        " Gerar o arquivo
        /dpf/cl_tom_integration=>create_file(
          io_report_run               = lo_report_run
          file_name                   = lv_file_name
          i_binary                    = lv_excel
          iv_file_extension           = '.xlsx'
        ).

      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           0200 - TP_ITEM
    "
    "
    "=========================================================================================
    IF p_0200ti IS NOT INITIAL.

      lv_view_name  = '/DPF/V0200SPED'.
      lv_table_name = '/TMF/D_MAT_CONF'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs         = p_bukrs
          iv_branch        = p_branch
          iv_view_name     = lv_view_name
          iv_table_name    = lv_table_name
          it_placeholders  = lt_placeholder
          iv_no_auto_mandt = 'X'
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND '0200 - TP_ITEM -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND '0200 - TP_ITEM -> ERRO ' TO lt_arquivo.
      ENDIF.

      "Dentro do "0200 - TP_ITEM" verificar se o "Tipo de Item p/ NF sem Código de Item" foi marcado
      IF p_0200cb IS NOT INITIAL.

        me->executa_pre_processamento(
          EXPORTING
            iv_view_name     = '/DPF/V0200SEMCIT'
            it_placeholders  = lt_placeholder
            iv_table_name    = '/TMF/D_NF_ITEM'
            iv_bukrs         = p_bukrs
            iv_branch        = p_branch
            iv_no_auto_mandt = abap_true
        ).

        IF sy-subrc IS INITIAL.
          p_criado = 'X'.
          APPEND '0200 - NF sem Cód.Item -> OK ' TO lt_arquivo.
        ELSEIF
          p_crerro = 'X'.
          APPEND '0200 - NF sem Cód.Item -> ERRO ' TO lt_arquivo.
        ENDIF.

      ENDIF.
    ENDIF.

    "=========================================================================================
    "
    "
    "           F100
    "
    "
    "=========================================================================================
    DATA(lv_ignorar_f100_std) = abap_false.

    IF me->go_badi IS BOUND.

      CALL BADI me->go_badi->executar_f100
        EXPORTING
          iv_empresa                = p_bukrs
          iv_filial                 = p_branch
          it_sel_screen             = sel_screen
          it_placeholder            = lt_placeholder
        CHANGING
          cv_skip_smarttax_standard = lv_ignorar_f100_std
          cv_criado                 = p_criado
          cv_crerro                 = p_crerro
          ct_arquivo                = lt_arquivo.

    ENDIF.

    IF p_f100 IS NOT INITIAL
      AND lv_ignorar_f100_std <> abap_true.

      lv_view_name  = '/DPF/VF100'.
      lv_table_name = '/TMF/D_DEM_DOCS'.

      DELETE FROM /TMF/D_DEM_DOCS CLIENT SPECIFIED
       WHERE mandt   = p_mandt
         AND empresa = p_bukrs
         AND dt_lancto BETWEEN lv_dt_ini AND lv_dt_fin.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'F100 -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'F100 -> ERRO ' TO lt_arquivo.
      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           F130
    "
    "
    "=========================================================================================
    IF p_f130 IS NOT INITIAL.
      DATA lv_mes_oper TYPE char6.
      lv_mes_oper = lv_dt_ini+4(2) && lv_dt_ini(4).

      lv_table_name = '/TMF/D_BENSENCAR'.

      "JCR #13605 30/11/2021 Ini
      IF p_branch IS INITIAL.

        DELETE FROM /tmf/d_bensencar CLIENT SPECIFIED
         WHERE empresa          = p_bukrs
           AND tp_base_operacao = 'AQUISICAO'
           AND mes_oper_aquis   = lv_mes_oper.

      ELSE.

        DELETE FROM /tmf/d_bensencar CLIENT SPECIFIED
         WHERE empresa          = p_bukrs
           AND filial           = p_branch
           AND tp_base_operacao = 'AQUISICAO'
           AND mes_oper_aquis   = lv_mes_oper.

      ENDIF.
      "JCR #13605 30/11/2021 Fim



      " #15634 - 27/07/2022 - Gabriel Oliveira BEGIN
      SELECT SINGLE @abap_true
       FROM /dpf/v_exit  ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
      WHERE nome  = 'PRE_PROCESSAMENTO_PCO_F130_NESTLE'
        AND ativo = @abap_true
       INTO @DATA(lv_ativa).

      IF lv_ativa = abap_true.

        lv_view_name = 'ZENG_F130'.

        me->executa_pre_processamento(
        EXPORTING
          iv_bukrs         = p_bukrs
          iv_branch        = p_branch
          iv_view_name     = lv_view_name
          iv_table_name    = lv_table_name
          it_placeholders  = lt_placeholder
          iv_no_auto_mandt = 'X'                            "JLS #NEST-185 21-08-2023
      ).

        IF sy-subrc IS INITIAL.
          p_criado = 'X'.
          APPEND 'F130 Nestlé -> OK ' TO lt_arquivo.
        ELSEIF
          p_crerro = 'X'.
          APPEND 'F130 Nestlé -> ERRO ' TO lt_arquivo.
        ENDIF.

        " #15634 - 27/07/2022 - Gabriel Oliveira END

      ELSE.

        lv_view_name  = '/DPF/VF130'.

        me->executa_pre_processamento(
          EXPORTING
            iv_bukrs         = p_bukrs
            iv_branch        = p_branch
            iv_view_name     = lv_view_name
            iv_table_name    = lv_table_name
            it_placeholders  = lt_placeholder
            "iv_no_auto_mandt = abap_true                    "JLS #NEST-185 21-08-2023  "JCR #SPMTJ-4 05/12/2024
            iv_no_auto_mandt = abap_false                                               "JCR #SPMTJ-4 05/12/2024
                                                                                        "Usar o MANDT auto para outros clientes
        ).

        IF sy-subrc IS INITIAL.
          p_criado = 'X'.
          APPEND 'F130 -> OK ' TO lt_arquivo.
        ELSEIF
          p_crerro = 'X'.
          APPEND 'F130 -> ERRO ' TO lt_arquivo.
        ENDIF.
      ENDIF.
    ENDIF.

    "=========================================================================================
    "
    "
    "           F600
    "
    "
    "=========================================================================================
    IF p_f600 IS NOT INITIAL.

      lw_placeholder-placeholder_name = 'P_DT_RETENCAO'.
      lw_placeholder-value =  p_dtret.
      APPEND lw_placeholder TO lt_placeholder.

      lv_view_name  = '/DPF/VF600'.
      lv_table_name = '/TMF/D_CONTRETFT'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'F600 -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'F600 -> ERRO ' TO lt_arquivo.
      ENDIF.

      DELETE lt_placeholder  WHERE placeholder_name = 'P_DT_RETENCAO'.

    ENDIF.

    "=========================================================================================
    "
    "
    "           D101/D105 (IND_NAT_FRT)
    "
    "
    "=========================================================================================
    IF p_d101 IS NOT INITIAL.

      lv_view_name  = '/DPF/VD101D105'.
      lv_table_name = '/TMF/D_NFDOC_CPL'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs         = p_bukrs
          iv_branch        = p_branch
          iv_view_name     = lv_view_name
          iv_table_name    = lv_table_name
          it_placeholders  = lt_placeholder
          iv_cols          = p_cols
          iv_no_auto_mandt = abap_true
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'D101/D105 -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'D101/D105 -> ERRO ' TO lt_arquivo.
      ENDIF.

      lv_view_name  = '/DPF/VD101NFITEM'.
      lv_table_name = '/TMF/D_NF_ITEM'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs         = p_bukrs
          iv_branch        = p_branch
          iv_view_name     = lv_view_name
          iv_table_name    = lv_table_name
          it_placeholders  = lt_placeholder
          iv_no_auto_mandt = abap_true
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'D101NFITEM -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'D101NFITEM -> ERRO ' TO lt_arquivo.
      ENDIF.

      lv_view_name  = '/DPF/VD101NATFRT'.
      lv_table_name = '/TMF/D_NF_DOC'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs         = p_bukrs
          iv_branch        = p_branch
          iv_view_name     = lv_view_name
          iv_table_name    = lv_table_name
          it_placeholders  = lt_placeholder
          iv_no_auto_mandt = abap_true
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'D101NATFRT -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'D101NATFRT -> ERRO ' TO lt_arquivo.
      ENDIF.

    ENDIF.

*    "=========================================================================================
*    "
*    "
*    "           C100/D100 (IND_FRT)
*    "
*    "
*    "=========================================================================================
*    IF p_c100 IS NOT INITIAL.
*
*      lv_view_name  = '/DPF/V'.
*      lv_table_name = '/TMF/D_NF_DOC'.
*
*      me->executa_pre_processamento(
*       EXPORTING
*         iv_bukrs = p_bukrs
*         iv_branch = p_branch
*         iv_view_name = lv_view_name
*         iv_table_name = lv_table_name
*         it_placeholders = lt_placeholder
*         iv_cols = p_cols
*      ).
*
*      IF sy-subrc IS INITIAL.
*        p_criado = 'X'.
*        APPEND 'C100/D100 -> OK ' TO lt_arquivo.
*      ELSEIF
*        p_crerro = 'X'.
*        APPEND 'C100/D100 -> ERRO ' TO lt_arquivo.
*      ENDIF.
*
*    ENDIF.

    "=========================================================================================
    "
    "
    "           C110 - 0450
    "
    "
    "=========================================================================================
    IF p_c110 IS NOT INITIAL.

      " Apagar a shadow d_nf_codinf antes de rodar devido a conflito com o pré processamento do SPED fiscal
      DATA(lv_delete_nfcodinf) = |DELETE FROM "/TMF/D_NF_CODINF" AS shdw WHERE EXISTS  |.
      lv_delete_nfcodinf = lv_delete_nfcodinf && |(select nf_id from "_SYS_BIC"."sap.glo.tmflocbr.ctr/NF_DOCUMENTO" as nf |.
      lv_delete_nfcodinf = lv_delete_nfcodinf && | where empresa = '{ p_bukrs }' and dt_e_s between '{ lv_ymde }' and '{ lv_ymdate }' and shdw.nf_id = nf.nf_id);|.

      DATA(lo_sql) = NEW cl_sql_statement(  ).

      lo_sql->execute_query( lv_delete_nfcodinf ).

      FREE lo_sql.

      me->alter_sequence(
        EXPORTING
          iv_bukrs    = p_bukrs
          iv_branch   = p_branch
          iv_sequence = 'engdb.dpfisc.app.db.sped_pis_cofins.sequences::C110_0450'
      ).

      lv_view_name  = '/DPF/VC110U'.
      lv_table_name = '/TMF/D_COD_INF_D'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'C110 -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'C110 -> ERRO ' TO lt_arquivo.
      ENDIF.

      lv_view_name  = '/DPF/VC110C'.
      lv_table_name = '/TMF/D_NF_CODINF'.

      me->executa_pre_processamento(
        EXPORTING
          iv_bukrs        = p_bukrs
          iv_branch       = p_branch
          iv_view_name    = lv_view_name
          iv_table_name   = lv_table_name
          it_placeholders = lt_placeholder
      ).

      IF sy-subrc IS INITIAL.
        p_criado = 'X'.
        APPEND 'C110C -> OK ' TO lt_arquivo.
      ELSEIF
        p_crerro = 'X'.
        APPEND 'C110C -> ERRO ' TO lt_arquivo.
      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           #11298 - Preencher COD_CTA nas NFs
    "
    "
    "=========================================================================================
    IF p_codcta IS NOT INITIAL.

      DATA: lt_nf_item_cod_cta TYPE STANDARD TABLE OF ty_nf_item_cod_cta,
            lt_v_nf_item       TYPE STANDARD TABLE OF /tmf/v_nf_item,
            lt_d_nf_item       TYPE STANDARD TABLE OF string,
            ls_d_nf_item       TYPE /tmf/d_nf_item.

      FIELD-SYMBOLS <fst_result> TYPE ANY TABLE.

      "Parâmetros para chamada da procedure
      DATA lt_in_params TYPE TABLE OF string.
      DATA lv_procedure TYPE string.
      DATA lo_procedure TYPE REF TO /dpf/cl_db_procedure.

      "Tabela de retorno da Procedure
      DATA lo_nf_item_cod_cta TYPE REF TO data.
      CREATE DATA lo_nf_item_cod_cta TYPE TABLE OF ty_nf_item_cod_cta.

      "Retorno da chamada da Procedure
      DATA result_wrapper TYPE REF TO data.
      FIELD-SYMBOLS <fst_result_wrapper> TYPE /dpf/tt_dyn_data.
      CREATE DATA result_wrapper TYPE /dpf/tt_dyn_data.
      ASSIGN result_wrapper->* TO <fst_result_wrapper>.

      "Atribuição estruturas para chamada da procedure
      <fst_result_wrapper> = VALUE #(
        ( object      = lo_nf_item_cod_cta
          object_name = |NF_ITEM_COD_CTA| )
      ).

      lo_procedure = NEW /dpf/cl_db_procedure(
        iv_empresa = p_bukrs
        iv_filial  = p_branch
      ).

      "PROCEDURE QUE SERÁ CHAMADA
      lv_procedure = |engdb.dpfisc.app.db.sped_pis_cofins.COD_CTA_NF::COD_CTA_NF|.

      lt_in_params = VALUE #(
        ( CONV #( lo_procedure->get_mandt( ) ) )  "IN P_MANDT NVARCHAR(3),
        ( CONV #( p_bukrs )  )                    "IN P_EMPRESA NVARCHAR(4),
        ( CONV #( p_branch ) )                    "IN P_FILIAL NVARCHAR(4),
        ( CONV #( lv_dt_ini ) )                   "IN P_DT_INI NVARCHAR(8),
        ( CONV #( lv_dt_fin ) )                   "IN P_DT_FIN NVARCHAR(8),
      ).

      "Chamada com a classe /DPF/CL_DB_PROCEDURE para evitar dependência do objeto no trasnporte em outros clientes
      lo_procedure->call_procedure(
        EXPORTING
          iv_procedure_name = lv_procedure
          iv_schema_name    = |DPFISC|
          it_in_parameters  = lt_in_params
        IMPORTING
          et_result         = <fst_result_wrapper>
      ).

      "NF_ITEM_COD_CTA
      READ TABLE <fst_result_wrapper> INTO DATA(lw_result)
        WITH TABLE KEY object_name = 'NF_ITEM_COD_CTA'.

      ASSIGN lw_result-object->* TO <fst_result>.
      IF <fst_result> IS ASSIGNED AND <fst_result> IS NOT INITIAL.
        APPEND LINES OF <fst_result> TO lt_nf_item_cod_cta.
      ENDIF.

      IF lt_nf_item_cod_cta[] IS NOT INITIAL.

        SORT lt_nf_item_cod_cta BY mandt nf_id num_item.

        SELECT *
          FROM /tmf/v_nf_item CLIENT SPECIFIED ##DB_FEATURE_MODE[EXTERNAL_VIEWS]
          INTO TABLE lt_v_nf_item
           FOR ALL ENTRIES IN lt_nf_item_cod_cta
         WHERE mandt    = lt_nf_item_cod_cta-mandt
           AND nf_id    = lt_nf_item_cod_cta-nf_id
           AND num_item = lt_nf_item_cod_cta-num_item.

        LOOP AT lt_v_nf_item ASSIGNING FIELD-SYMBOL(<fs_v_nf_item>).
          READ TABLE lt_nf_item_cod_cta ASSIGNING FIELD-SYMBOL(<fs_nf_item_cod_cta>) BINARY SEARCH
              WITH KEY mandt    = <fs_v_nf_item>-mandt
                       nf_id    = <fs_v_nf_item>-nf_id
                       num_item = <fs_v_nf_item>-num_item.

          IF sy-subrc IS INITIAL.
            <fs_v_nf_item>-cod_cta = <fs_nf_item_cod_cta>-cod_cta.

            MOVE-CORRESPONDING <fs_v_nf_item> TO ls_d_nf_item.

            MODIFY /tmf/d_nf_item CLIENT SPECIFIED FROM ls_d_nf_item.

            IF sy-subrc IS INITIAL.
              lv_string =
                |="| && <fs_nf_item_cod_cta>-mandt      && |";| &&
                |="| && <fs_nf_item_cod_cta>-empresa    && |";| &&
                |="| && <fs_nf_item_cod_cta>-filial     && |";| &&
                |="| && <fs_nf_item_cod_cta>-nf_id      && |";| &&
                |="| && <fs_nf_item_cod_cta>-num_item   && |";| &&
                |="| && <fs_nf_item_cod_cta>-dt_e_s     && |";| &&
                |="| && <fs_nf_item_cod_cta>-dt_doc     && |";| &&
                |="| && <fs_nf_item_cod_cta>-cod_mod    && |";| &&
                |="| && <fs_nf_item_cod_cta>-cod_cta    && |";|.

              APPEND lv_string TO lt_d_nf_item.
            ENDIF.

          ENDIF.
        ENDLOOP.

        IF lt_d_nf_item IS NOT INITIAL.

          p_criado = 'X'.
          APPEND 'COD_CTA NF -> OK ' TO lt_arquivo.

          lv_string = |MANDT;EMPRESA;FILIAL;NF_ID;NUM_ITEM;DT_E_S;DT_DOC;COD_MOD;COD_CTA|.
          INSERT lv_string INTO lt_d_nf_item INDEX 1.

          lv_texto_tpe = 'Notas Atualizadas COD_CTA NF'.
          /dpf/cl_tom_integration=>create_file(
             io_report_run     = lo_report_run
             file_name         = CONV #( lv_texto_tpe )
             it_file_table     = lt_d_nf_item
             iv_file_extension = '.csv'
          ).

        ELSE.

          p_crerro = 'X'.
          APPEND 'COD_CTA NF -> Erro na atualização' TO lt_arquivo.

        ENDIF.

      ELSE.

        "p_crerro = 'X'. "TPPMS-3 - Wander - 12.01.2024 - Comentei. Não considerar como erro quando não encontrar. Já sai no log que não encontrou

        p_criado = 'X'.  "SPMTJ-11 - 11.12.2024 - Wander - Colocar como "Criado" para não gerar como erro
        APPEND 'COD_CTA NF -> Nenhum registro para atualização' TO lt_arquivo.

      ENDIF.

    ENDIF.

    "=========================================================================================
    "
    "
    "           #17376 - Wander - 01.03.2023
    "           Descrição nova - LC116
    "
    "
    "=========================================================================================
    IF p_descr IS NOT INITIAL.

      me->proc_desc_lc116(
        EXPORTING
          iv_mandt   = p_mandt
          iv_empresa = p_bukrs
          iv_filial  = p_branch
          iv_ano     = p_ano
          iv_mes     = p_mes
      ).

      p_criado = 'X'.
      APPEND 'Descrição Nova - LC116 -> OK ' TO lt_arquivo.

    ENDIF.

    IF p_arqtom = 'X'.

      "=========================================================================================
      "
      "
      "             Gerar arquivo no TOM
      "
      "
      "=========================================================================================
      IF p_criado = 'X' AND p_crerro IS INITIAL.
        lv_texto_tpe = 'Executado com sucesso'.
      ELSE.
        APPEND '' TO lt_arquivo.
        APPEND 'Ocorreu um erro ao executar o Pré-processamento.' TO lt_arquivo.

        lv_texto_tpe = 'Erro ao executar.'.
      ENDIF.

      /dpf/cl_tom_integration=>create_file(
         io_report_run     = lo_report_run
         file_name         = CONV #( lv_texto_tpe )
         it_file_table     = lt_arquivo
         iv_file_extension = '.txt'
      ).

    ELSE.

      "=========================================================================================
      "
      "
      "             Montar retorno no formato JSON
      "
      "
      "=========================================================================================
      wa_log-mensagem = 'Cenário(s) executados com sucesso'.
      APPEND wa_log TO lt_log.

      CREATE DATA eo_output_data LIKE lt_log.
      FIELD-SYMBOLS: <ft_log> TYPE ANY TABLE.
      ASSIGN eo_output_data->*  TO <ft_log> .
      <ft_log> = lt_log.

    ENDIF.

  ENDMETHOD.


  METHOD obter_tooltip.

    "#9378 - FBT - Dica para os pre processamentos, otimização backend calls  - Melhoria do Roadmap
    IF i_t_range_id_dica[] IS INITIAL.
      RETURN.
    ENDIF.

    SELECT identificador,
           descricao_padrao,
           descricao_customizada
      FROM /dpf/d_tooltip
     WHERE identificador IN @i_t_range_id_dica[]
      INTO TABLE @DATA(lt_dica_temp).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    "PRIORIZA A DESCRIÇÃO CUSTOMIZADA, CASO HAJA
    LOOP AT lt_dica_temp[] ASSIGNING FIELD-SYMBOL(<fs_dica_temp>).

      IF <fs_dica_temp>-descricao_customizada IS NOT INITIAL.
        wa_tooltip-identificador    = <fs_dica_temp>-identificador.
        wa_tooltip-dica             = <fs_dica_temp>-descricao_customizada.

        APPEND wa_tooltip TO it_tooltip.
      ELSE.
        wa_tooltip-identificador    = <fs_dica_temp>-identificador.
        wa_tooltip-dica             = <fs_dica_temp>-descricao_padrao.

        APPEND wa_tooltip TO it_tooltip.
      ENDIF.
    ENDLOOP.

    o_tooltip = it_tooltip.

  ENDMETHOD.


  METHOD pre_proc_0200_aliq_icms.

    TYPES: BEGIN OF ty_key_item_icms,
             mandt    TYPE /tmf/d_item_icms-mandt,
             pais     TYPE /tmf/d_item_icms-pais,
             origem   TYPE /tmf/d_item_icms-origem,
             destino  TYPE /tmf/d_item_icms-destino,
             dt_ini   TYPE /tmf/d_item_icms-dt_ini,
             cod_item TYPE /tmf/d_item_icms-cod_item,
           END OF ty_key_item_icms.

    DATA: lv_sql           TYPE string,
          lv_fields        TYPE /dpf/cl_db_select=>my_table_fields,
          lt_output_data   TYPE REF TO data ##NEEDED,
          lv_mandt         TYPE /tmf/d_item_icms-mandt,
          lt_key_item_icms TYPE TABLE OF ty_key_item_icms,
          lt_item_icms     TYPE TABLE OF /tmf/d_item_icms.  "BJM - 7652 - Acerto SPED Pis/Cofins - Pré Processamento ( Gravação de apenas a data mais recente )

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

    CLEAR lv_mandt.

    lo_db_select->get_mandt(
      RECEIVING
        rv_mandt = lv_mandt
    ).

    CLEAR lt_item_icms[].

    lo_db_select->execute_select(
      EXPORTING
        iv_sql   = lv_sql
      CHANGING
        ct_table = lt_item_icms
    ).

    IF NOT lt_item_icms[] IS INITIAL.

      SELECT mandt
             pais
             origem
             destino
             dt_ini
             cod_item
        FROM /tmf/d_item_icms CLIENT SPECIFIED
        INTO TABLE lt_key_item_icms
         FOR ALL ENTRIES IN lt_item_icms
       WHERE mandt    = lv_mandt
         AND pais     = lt_item_icms-pais
         AND origem   = lt_item_icms-origem
         AND destino  = lt_item_icms-destino
         AND cod_item = lt_item_icms-cod_item.

      "Por questão de performance a deleção será feita com a tabela selecionada acima com todas
      "as chaves necessárias para o delete abaixo
      "que contempla todos os registros da chave sem considerar a DT_INI
      DELETE (iv_table_name) USING CLIENT @lv_mandt FROM TABLE @lt_key_item_icms[].
      MODIFY (iv_table_name) USING CLIENT @lv_mandt FROM TABLE @lt_item_icms[].

    ENDIF.

  ENDMETHOD.

  METHOD verificar_permissao_campo.

    "#9378 - FBT - Dica para os pre processamentos, otimização backend calls  - Melhoria do Roadmap
    IF i_t_range_campos[] IS INITIAL.
      RETURN.
    ENDIF.

    DATA: lt_params TYPE tihttpnvp .
    DATA: wa_params TYPE ihttpnvp.

    LOOP AT i_t_range_campos[] INTO DATA(wa_chkcmp).
      CLEAR lt_params.

      wa_params-name  = 'p_auth_check'.
      wa_params-value = '[{"low":"X","high":"","kind":"P","option":"EQ","sign":"I"}]'.
      APPEND wa_params TO lt_params.

      wa_params-name  = 'p_field'.
      wa_params-value = '[{"low":"' &&  wa_chkcmp-low && '","high":"","kind":"P","option":"EQ","sign":"I"}]'.
      APPEND wa_params TO lt_params.

      wa_params-name  = 'p_dummy'.
      wa_params-value = '[{"low":"HIDE","high":"","kind":"P","option":"EQ","sign":"I"}]'.
      APPEND wa_params TO lt_params.

      wa_params-name  = 'p_report_id'.
      wa_params-value = '"' && me->mv_report_id && '"'.
      APPEND wa_params TO lt_params.

      IF me->authority_check( EXPORTING it_params = lt_params ) IS NOT INITIAL.
        "CASO NÃO TENHA AUTORIZAÇÃO
        wa_permissao-campo   = wa_chkcmp-low.
        wa_permissao-status  = abap_false.
        APPEND wa_permissao TO it_permissao.
      ELSE.
        "CASO TENHA AUTORIZAÇÃO
        wa_permissao-campo  = wa_chkcmp-low.
        wa_permissao-status = abap_true.
        APPEND wa_permissao TO it_permissao.
      ENDIF.
    ENDLOOP.

    o_permissao = it_permissao.

  ENDMETHOD.

  METHOD executa_blocom_apuracao  BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.apuracao_pis_cofins_v2.bloco_m::GERA_REGISTROS" (
        -- ENTRADAS
        P_MANDT                 => :IV_MANDT,
        P_EMPRESA               => :IV_EMPRESA,
        P_FILIAL                => :IV_FILIAL,
        P_DT_INI                => :IV_DT_INI,
        P_DT_FIN                => :IV_DT_FIN,
        P_NFS_CONSOLIDADAS      => :IV_NFS_CONSOLIDADAS,
        P_PAGINA                => :IV_PAGINA,
        P_REGISTRO_EXCEL        => :IV_REGISTRO_EXCEL,
        P_LEDGER                => :IV_LEDGER,
        P_INCIDENCIA_TRIBUTARIA => :IV_INC_TRIBUTARIA,
        P_RETIDO_FONTE          => :IV_RETIDO_FONTE,
        P_F600_ONLY_SHADOW      => :IV_F600_ONLY_SHADOW,        -- NEST-567 - 11.12.2024 - WANDER
        -- SAIDAS
        REGISTRO_0111           => :ET_REGISTRO_0111,
        REGISTRO_M105           => :ET_REGISTRO_M105,
        REGISTRO_M505           => :ET_REGISTRO_M505,
        REGISTRO_M210_M610      => :ET_REGISTRO_M210_M610,
        REGISTRO_M410           => :ET_REGISTRO_M410,
        REGISTRO_M400           => :ET_REGISTRO_M400,
        REGISTRO_M810           => :ET_REGISTRO_M810,
        REGISTRO_M800           => :ET_REGISTRO_M800,
        REGISTRO_M100_M500      => :ET_REGISTRO_M100_M500,
        REGISTRO_M200_M600      => :ET_REGISTRO_M200_M600,
        REGISTRO_1100_1500      => :ET_REGISTRO_1100_1500,
        REGISTRO_1300_1700      => :ET_REGISTRO_1300_1700,
        TOTAIS_REGISTROS        => :ET_TOTAIS_REGISTROS,
        NAT_ISENTA_SEM_PARAM    => :ET_NAT_ISENTA_SEM_PARAM     --JCR #15646 25/06/2022
    );

  ENDMETHOD.


  METHOD proc_desc_lc116 BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "DPFISC"."engdb.dpfisc.app.db.sped_pis_cofins.DESC_LC116::PR_DESC_LC116" (
        -- ENTRADAS
        P_MANDT     => :IV_MANDT,
        P_EMPRESA   => :IV_EMPRESA,
        P_FILIAL    => :IV_FILIAL,
        P_ANO       => :IV_ANO,
        P_MES       => :IV_MES
    );

  ENDMETHOD.

ENDCLASS.