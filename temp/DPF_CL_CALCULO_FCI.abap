CLASS /dpf/cl_calculo_fci DEFINITION
  PUBLIC
  INHERITING FROM /dpf/cl_webservice_wrap
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_amdp_marker_hdb.

    TYPES: BEGIN OF ty_prod_saida, "PRODUTOS DE SAIDA
             mandt         TYPE char3,
             empresa       TYPE char4,
             filial        TYPE char4,
             nf_id         TYPE char10,
             vl_item_total TYPE /tmf/de_dec_25_6,
             dt_doc        TYPE char8,
             cod_item      TYPE /tmf/de_cod_item,
             unid_inv      TYPE char6,
             cod_item_comp TYPE /tmf/de_cod_item,
             unid_inv_comp TYPE char6,
             conversao     TYPE char1,
             fat_conv      TYPE /tmf/de_dec_25_6,
           END OF ty_prod_saida.

    TYPES ty_t_prod_saida  TYPE STANDARD TABLE OF ty_prod_saida WITH EMPTY KEY.

    TYPES: BEGIN OF ty_itens, "ITENS
             mandt         TYPE char3,
             cod_item      TYPE /tmf/de_cod_item,
             cod_ncm       TYPE char16,
             tipo_item     TYPE char2,
             tipo_material TYPE char4,
             mtorg         TYPE char1,
             unid_inv      TYPE char6,
             descr_item    TYPE c LENGTH 255,
           END OF ty_itens.

    TYPES ty_t_itens  TYPE STANDARD TABLE OF ty_itens WITH EMPTY KEY.

    TYPES: BEGIN OF ty_nf, "NOTAS
             mandt            TYPE char3,
             cod_item         TYPE /tmf/de_cod_item,
             cod_ncm          TYPE char16,
             tipo_item        TYPE char2,
             tipo_material    TYPE char4,
             mtorg            TYPE char1,
             unid_inv         TYPE char6,
             descr_item       TYPE c LENGTH 255,
             empresa          TYPE char4,
             filial           TYPE char4,
             nf_id            TYPE char10,
             dt_doc           TYPE char8,
             num_item         TYPE char6,
             cfop             TYPE char10,
             direct           TYPE char1,
             vl_item_total    TYPE /tmf/de_dec_25_6,
             quantidade       TYPE /tmf/de_dec_25_6,
             numero_documento TYPE char9,
             unid_medida      TYPE char6,
             cod_part         TYPE /tmf/de_cod_part,
             vl_item          TYPE /tmf/de_dec_25_6,
             planta           TYPE char4,
           END OF ty_nf.

    TYPES ty_t_nf  TYPE STANDARD TABLE OF ty_nf WITH EMPTY KEY.

    TYPES: BEGIN OF ty_calculo_fci, "CALCULO FCI
             mandt           TYPE char3,
             empresa         TYPE char4,
             estabelecimento TYPE char4,
             mes_ref_fci     TYPE char6,
             cod_item        TYPE c LENGTH 60,
             tipo_material   TYPE char4,
             vlr_tot_saida   TYPE /tmf/de_dec_25_6,
             qtde_tot_saida  TYPE /tmf/de_dec_25_6,
             vlr_unit_saida  TYPE /tmf/de_dec_25_6,
             custo_unit      TYPE /tmf/de_dec_25_6,
             origem_material TYPE char1,
             vlr_tot_ent     TYPE /tmf/de_dec_25_6,
             qtde_tot_ent    TYPE /tmf/de_dec_25_6,
             vlr_unit_ent    TYPE /tmf/de_dec_25_6,
             perc_ci         TYPE /tmf/de_dec_25_6,
             perc_calc       TYPE /tmf/de_dec_25_6,
             planta          TYPE char4,
           END OF ty_calculo_fci.

    TYPES ty_t_calculo_fci  TYPE STANDARD TABLE OF ty_calculo_fci WITH EMPTY KEY.

    TYPES: BEGIN OF ty_origem_material, "ORIGEM MATERIAL
             mandt           TYPE char3,
             cod_item        TYPE /tmf/de_cod_item,
             origem_material TYPE char1,
             empresa         TYPE char4,
             estabelecimento TYPE char4,
             descr_item      TYPE c LENGTH 255,
             org_mat         TYPE char1,
           END OF ty_origem_material.

    TYPES ty_t_origem_material  TYPE STANDARD TABLE OF ty_origem_material WITH EMPTY KEY.

    TYPES: BEGIN OF ty_relatorio_memoria, "RELATORIO MEMORIA SAIDA
             mandt            TYPE char3,
             cod_item         TYPE /tmf/de_cod_item,
             unid_inv         TYPE char6,
             vlr_unit_ent     TYPE /tmf/de_dec_25_6,
             vlr_unit_saida   TYPE /tmf/de_dec_25_6,
             perc_ci          TYPE /tmf/de_dec_25_6,
             cfop             TYPE char10,
             cod_ncm          TYPE char16,
             numero_documento TYPE char9,
             dt_doc           TYPE char10,
             unid_medida      TYPE char6,
             cod_part         TYPE /tmf/de_cod_part,
             quantidade       TYPE /tmf/de_dec_25_6,
             vl_item          TYPE /tmf/de_dec_25_6,
             descr_item       TYPE c LENGTH 255,
             mtorg            TYPE char1,
             planta           TYPE char4,
             nf_id            TYPE char10, "Wander - 20/10/2020 - #10296
           END OF ty_relatorio_memoria.

    TYPES ty_t_relatorio_memoria  TYPE STANDARD TABLE OF ty_relatorio_memoria WITH EMPTY KEY.

    TYPES: BEGIN OF ty_relatorio_memoria_ent, "RELATORIO MEMORIA ENTRADA
             mandt            TYPE char3,
             cod_item_pai     TYPE /tmf/de_cod_item,
             cod_item         TYPE /tmf/de_cod_item,
             unid_inv         TYPE char6,
             vlr_unit_ent     TYPE /tmf/de_dec_25_6,
             vlr_unit_saida   TYPE /tmf/de_dec_25_6,
             perc_ci          TYPE /tmf/de_dec_25_6,
             cfop             TYPE char10,
             cod_ncm          TYPE char16,
             numero_documento TYPE char9,
             dt_doc           TYPE char10,
             unid_medida      TYPE char6,
             cod_part         TYPE /tmf/de_cod_part,
             quantidade       TYPE /tmf/de_dec_25_6,
             vl_item          TYPE /tmf/de_dec_25_6,
             descr_item       TYPE c LENGTH 255,
             coeficiente      TYPE /tmf/de_dec_25_6,
             mtorg            TYPE char1,
             planta           TYPE char4,
             nf_id            TYPE char10, "Wander - 20/10/2020 - #10296
           END OF ty_relatorio_memoria_ent.

    TYPES ty_t_relatorio_memoria_ent  TYPE STANDARD TABLE OF ty_relatorio_memoria_ent WITH EMPTY KEY.

    TYPES: BEGIN OF ty_arquivo,
             linha  TYPE string,
             filial TYPE string,
           END OF ty_arquivo,

           ty_t_arquivo TYPE STANDARD TABLE OF ty_arquivo,

           BEGIN OF ty_dados,
             cnpj          TYPE string,
             filial        TYPE string,
             total_filiais TYPE i,
           END OF ty_dados,

           ty_t_dados TYPE STANDARD TABLE OF ty_dados,

           BEGIN OF ty_registro_tabela_5020,
             mandt               TYPE mandt,
             empresa             TYPE /tmf/de_empresa,
             estabelecimento     TYPE /tmf/de_filial,
             tipo_registro       TYPE char4,
             nome_mercadoria     TYPE c LENGTH 255,
             codigo_ncm          TYPE char8,

             codigo_mercadoria   TYPE char50,
             codigo_gtin         TYPE char5,
             unid_merc           TYPE char6,
             vl_saida_merc_inter TYPE /dpf/d_fci_r5020-vl_saida_merc_inter,
             vl_parc_imp_ext     TYPE /dpf/d_fci_r5020-vl_parc_imp_ext,
             perc_ci             TYPE /dpf/d_fci_r5020-perc_ci,
             codigo_fci          TYPE c LENGTH 36,
             in_validacao_ficha  TYPE char20,
           END OF ty_registro_tabela_5020,

           ty_t_registro_tabela_5020 TYPE STANDARD TABLE OF ty_registro_tabela_5020 WITH EMPTY KEY.

    TYPES: BEGIN OF ty_conteudo_importacao,
             cod_item       TYPE /tmf/de_cod_item,
             unid_inv       TYPE char6,
             vlr_unit_ent   TYPE /tmf/de_dec_25_6,
             vlr_unit_saida TYPE /tmf/de_dec_25_6,
             perc_ci        TYPE /tmf/de_dec_25_6,
           END OF ty_conteudo_importacao,

           ty_t_conteudo_importacao TYPE STANDARD TABLE OF ty_conteudo_importacao WITH EMPTY KEY.

    " RETORNO
    " CABECALHO
    TYPES: BEGIN OF ty_retorno_cabecalho,
             empresa     TYPE string,
             filial      TYPE string,
             periodo_ref TYPE string,
             teste       TYPE string,
           END OF ty_retorno_cabecalho,

           "RELATORIOS
           BEGIN OF ty_retorno_relatorios,
             conteudo_importacao TYPE ty_t_conteudo_importacao,
             memoria_saida       TYPE ty_t_relatorio_memoria,
             memoria_entrada     TYPE ty_t_relatorio_memoria_ent,
             origem_material     TYPE ty_t_origem_material,
           END OF ty_retorno_relatorios,

           "RETORNO
           BEGIN OF ty_retorno,
             cabecalho             TYPE ty_retorno_cabecalho,
             itens_nao_encontrados TYPE string,
             excel_gerado          TYPE string,
             relatorios            TYPE ty_retorno_relatorios,
             arquivo_gerado        TYPE string,
             link_arquivo          TYPE string,
           END OF ty_retorno.

    TYPES: BEGIN OF ty_itens_novos,
             mandt         TYPE char3,
             empresa       TYPE char4,
             filial        TYPE char4,
             centro        TYPE char4,
             cod_item      TYPE c LENGTH 60,
             quantidade    TYPE /tmf/de_dec_25_6,
             vl_item_total TYPE /tmf/de_dec_25_6,
             unid_inv      TYPE char6,
           END OF ty_itens_novos,

           ty_t_itens_novos TYPE STANDARD TABLE OF ty_itens_novos WITH EMPTY KEY,

           BEGIN OF ty_cod_prod_sai,
             mandt         TYPE char3,
             empresa       TYPE char4,
             filial        TYPE char4,
             nf_id         TYPE c LENGTH 10,
             cod_produto   TYPE c LENGTH 60,
             vl_item_total TYPE /tmf/de_dec_25_6,
             dt_doc        TYPE char8,
             planta        TYPE char4,
           END OF ty_cod_prod_sai,

           ty_t_cod_prod_sai TYPE STANDARD TABLE OF ty_cod_prod_sai WITH EMPTY KEY,

           BEGIN OF ty_rel_item,
             mandt            TYPE char3,
             empresa          TYPE char4,
             filial           TYPE char4,
             nf_id            TYPE c LENGTH 10,
             cod_produto      TYPE c LENGTH 60,
             dt_doc           TYPE char8,
             num_item         TYPE char6,
             cfop             TYPE c LENGTH 10,
             direct           TYPE char1,
             quantidade       TYPE /tmf/de_dec_25_6,
             qtd              TYPE /tmf/de_dec_25_6,
             numero_documento TYPE c LENGTH 9,
             unid_medida      TYPE char6,
             cod_part         TYPE c LENGTH 60,
             vl_opr_saida     TYPE /tmf/de_dec_25_6,
             tipo_material    TYPE char4,
             planta           TYPE char4,
             umrez            TYPE p LENGTH 5 DECIMALS 0,
             umren            TYPE p LENGTH 5 DECIMALS 0,
             unid_inv         TYPE char6,
           END OF ty_rel_item,

           ty_t_rel_item TYPE STANDARD TABLE OF ty_rel_item WITH EMPTY KEY.

    METHODS constructor .

    METHODS executa_relatorio REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS retorna_itens
      IMPORTING
        VALUE(iv_input_mandt)       TYPE mandt
        VALUE(iv_input_cod_produto) TYPE string
        VALUE(iv_input_ncm)         TYPE string
      EXPORTING
        VALUE(et_out_item)          TYPE ty_t_itens .

    METHODS calculo_fci
      IMPORTING
        VALUE(iv_input_mandt)       TYPE mandt
        VALUE(iv_input_empresa)     TYPE /tmf/de_empresa
        VALUE(iv_input_filial)      TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)  TYPE s_date
        VALUE(iv_input_periodo_ate) TYPE s_date
        VALUE(iv_input_concatena)   TYPE char1
        VALUE(iv_input_direct)      TYPE char1
        VALUE(iv_input_cod_produto) TYPE string
        VALUE(iv_input_ncm)         TYPE string
      CHANGING
        VALUE(et_produto_saida)     TYPE ty_t_prod_saida
        VALUE(et_item_saida)        TYPE ty_t_itens
        VALUE(et_item_entrada)      TYPE ty_t_itens
        VALUE(et_movimento_nota)    TYPE ty_t_nf.

    METHODS call_calc_fci_atual
      IMPORTING
        VALUE(iv_input_mandt)       TYPE mandt
        VALUE(iv_input_empresa)     TYPE /tmf/de_empresa
        VALUE(iv_input_filial)      TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)  TYPE s_date
        VALUE(iv_input_periodo_ate) TYPE s_date
        VALUE(iv_input_concatena)   TYPE char1
        VALUE(iv_input_direct)      TYPE char1
        VALUE(iv_input_cod_produto) TYPE string
        VALUE(iv_input_ncm)         TYPE string
        VALUE(it_itens_novos)       TYPE ty_t_itens_novos
        VALUE(it_cod_produto_saida) TYPE ty_t_cod_prod_sai
        VALUE(it_relatorio_item)    TYPE ty_t_rel_item
      CHANGING
        VALUE(et_produto_saida)     TYPE ty_t_prod_saida
        VALUE(et_item_saida)        TYPE ty_t_itens
        VALUE(et_item_entrada)      TYPE ty_t_itens
        VALUE(et_movimento_nota)    TYPE ty_t_nf.

    METHODS call_produtos_saida
      IMPORTING
        VALUE(iv_input_mandt)       TYPE mandt
        VALUE(iv_input_empresa)     TYPE /tmf/de_empresa
        VALUE(iv_input_filial)      TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)  TYPE s_date
        VALUE(iv_input_periodo_ate) TYPE s_date
        VALUE(iv_input_concatena)   TYPE char1
        VALUE(iv_input_direct)      TYPE char1
        VALUE(iv_input_cod_produto) TYPE string
        VALUE(iv_input_ncm)         TYPE string
      CHANGING
        VALUE(et_itens_novos)       TYPE ty_t_itens_novos
        VALUE(et_cod_produto_saida) TYPE ty_t_cod_prod_sai
        VALUE(et_relatorio_item)    TYPE ty_t_rel_item.

    METHODS call_mov_itens_novos
      IMPORTING
        VALUE(iv_input_mandt)         TYPE mandt
        VALUE(iv_input_empresa)       TYPE /tmf/de_empresa
        VALUE(iv_input_filial)        TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)    TYPE s_date
        VALUE(iv_input_periodo_ate)   TYPE s_date
        VALUE(iv_input_concatena)     TYPE char1
        VALUE(iv_input_direct)        TYPE char1
        VALUE(iv_input_cod_produto)   TYPE string
        VALUE(iv_input_ncm)           TYPE string
        VALUE(iv_input_meses_retorno) TYPE i
      CHANGING
        VALUE(et_itens_novos)         TYPE ty_t_itens_novos
        VALUE(et_cod_produto_saida)   TYPE ty_t_cod_prod_sai
        VALUE(et_relatorio_item)      TYPE ty_t_rel_item.

    METHODS calculo_fci_atualizado
      IMPORTING
        VALUE(iv_input_mandt)       TYPE mandt
        VALUE(iv_input_empresa)     TYPE /tmf/de_empresa
        VALUE(iv_input_filial)      TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)  TYPE s_date
        VALUE(iv_input_periodo_ate) TYPE s_date
        VALUE(iv_input_concatena)   TYPE char1
        VALUE(iv_input_direct)      TYPE char1
        VALUE(iv_input_cod_produto) TYPE string
        VALUE(iv_input_ncm)         TYPE string
      CHANGING
        VALUE(et_produto_saida)     TYPE ty_t_prod_saida
        VALUE(et_item_saida)        TYPE ty_t_itens
        VALUE(et_item_entrada)      TYPE ty_t_itens
        VALUE(et_movimento_nota)    TYPE ty_t_nf.

    METHODS retorna_notas
      IMPORTING
        VALUE(iv_input_mandt)       TYPE mandt
        VALUE(iv_input_empresa)     TYPE /tmf/de_empresa
        VALUE(iv_input_filial)      TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)  TYPE s_date
        VALUE(iv_input_periodo_ate) TYPE s_date
        VALUE(iv_input_concatena)   TYPE char1
        VALUE(iv_input_direct)      TYPE char1
        VALUE(iv_input_item)        TYPE ty_t_itens
      EXPORTING
        VALUE(et_out_retorno)       TYPE ty_t_nf .

    METHODS selecao_notas
      IMPORTING
        VALUE(iv_input_mandt)           TYPE mandt
        VALUE(iv_input_empresa)         TYPE /tmf/de_empresa
        VALUE(iv_input_filial)          TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)      TYPE s_date
        VALUE(iv_input_periodo_ate)     TYPE s_date
        VALUE(iv_input_concatena)       TYPE char1
        VALUE(iv_input_direct)          TYPE char1
        VALUE(iv_input_item)            TYPE ty_t_itens
      EXPORTING
        VALUE(et_notas_total)           TYPE ty_t_nf
        VALUE(et_itens_nao_encontrados) TYPE ty_t_itens.

    METHODS calculo_movimento_nota
      IMPORTING
        VALUE(iv_input_mandt)      TYPE mandt
        VALUE(iv_input_empresa)    TYPE /tmf/de_empresa
        VALUE(iv_input_filial)     TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de) TYPE s_date
        VALUE(iv_input_recalcula)  TYPE flag
        VALUE(iv_input_relatorio)  TYPE ty_t_nf
      EXPORTING
        VALUE(et_calculo)          TYPE ty_t_calculo_fci
        VALUE(et_relatorio)        TYPE ty_t_relatorio_memoria.

    METHODS calculo_custo_efetivo
      IMPORTING
        VALUE(iv_input_mandt)      TYPE mandt
        VALUE(iv_input_empresa)    TYPE /tmf/de_empresa
        VALUE(iv_input_filial)     TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de) TYPE s_date
        VALUE(iv_input_recalcula)  TYPE flag
        VALUE(iv_input_relatorio)  TYPE ty_t_nf
      EXPORTING
        VALUE(et_calculo)          TYPE ty_t_calculo_fci
        VALUE(et_relatorio)        TYPE ty_t_relatorio_memoria.

    METHODS gerar_arquivo
      IMPORTING
        VALUE(iv_input_mandt)          TYPE mandt
        VALUE(iv_input_empresa)        TYPE /tmf/de_empresa
        VALUE(iv_input_filial)         TYPE /tmf/de_filial
        VALUE(iv_input_periodo_de)     TYPE s_date
        VALUE(iv_input_concatena)      TYPE char1
      EXPORTING
        VALUE(et_registro_tabela_5020) TYPE ty_t_registro_tabela_5020
        VALUE(et_arquivo)              TYPE ty_t_arquivo
        VALUE(et_dados)                TYPE ty_t_dados.

    METHODS origem_material
      IMPORTING
        VALUE(iv_input_mandt) TYPE mandt
        VALUE(iv_calculo)     TYPE ty_t_calculo_fci
      EXPORTING
        VALUE(et_origem)      TYPE ty_t_origem_material.

    METHODS gerar_excel
      IMPORTING
        VALUE(lt_retorno) TYPE ty_retorno
      EXPORTING
        VALUE(lv_zip)     TYPE xstring.

ENDCLASS.

CLASS /dpf/cl_calculo_fci IMPLEMENTATION.

  METHOD executa_relatorio.

    DATA: lt_vgiasptxt           TYPE TABLE OF /dpf/vgiasptxt,
          lv_fm_name             TYPE rs38l_fnam,
          lv_where               TYPE string,
          p_pdftom               TYPE flag,
          p_csvtom               TYPE flag,
          p_arqtom               TYPE flag,
          p_json                 TYPE flag,
          p_ldcout               TYPE flag,
          p_cnfsrv               TYPE flag,
          p_gerdip               TYPE flag,
          p_cols                 TYPE string,
          p_mandt                TYPE mandt,
          p_bukrs                TYPE /tmf/de_empresa,
          p_branch               TYPE /tmf/de_estabelecimento,
          s_date                 TYPE RANGE OF datum,
          sw_date                LIKE LINE OF s_date,
          p_concat               TYPE c,
          s_produ                TYPE RANGE OF /tmf/de_cod_part,
          sw_prod                LIKE LINE OF s_produ,
          s_ncm                  TYPE RANGE OF char16,
          sw_ncm                 LIKE LINE OF s_ncm,
          p_leiaut               TYPE char4,
          p_recalc               TYPE flag,
          p_mteste               TYPE flag,
          p_colcsv               TYPE string,
          lv_mes_anterior_de     TYPE datum,
          lv_mes_anterior_ate    TYPE datum,
          lv_mes_considerado_de  TYPE datum,
          lv_mes_considerado_ate TYPE datum,
          lv_ano_cons            TYPE char4,
          lv_mes_cons            TYPE char2,
          p_gerar                TYPE flag,
          lv_texto_tpe           TYPE string,
          lw_placeholder         TYPE /dpf/cl_db_select=>mty_placeholder,
          lt_placeholder         TYPE TABLE OF /dpf/cl_db_select=>mty_placeholder,
          lv_sql                 TYPE string,
          lo_data                TYPE REF TO data,
          lv_view_name           TYPE /tmf/de_view_name,
          lv_table_name          TYPE string,
          ls_otf_data            TYPE ssfcrescl,
          ls_output_options      TYPE ssfcompop,
          ls_control_parameters  TYPE ssfctrlop,
          lv_bin_fsize           TYPE i,
          lv_field_name          TYPE string,
          lt_otf                 TYPE STANDARD TABLE OF itcoo,
          lt_lines               TYPE STANDARD TABLE OF tline,
          lv_xstring_document    TYPE xstring,
          lt_retorno             TYPE ty_retorno,
          wa_retorno_cabecalho   TYPE ty_retorno_cabecalho,
          lt_produtos_saida      TYPE ty_t_prod_saida,
          lt_itens_saida         TYPE ty_t_itens,
          lt_itens_entrada       TYPE ty_t_itens,
          lt_notas_saida         TYPE ty_t_nf.

    FIELD-SYMBOLS: <fst_select_option> TYPE ANY TABLE,
                   <fs_select_option>  TYPE any,
                   <fs_parameter>      TYPE any,
                   <fst_output>        TYPE ANY TABLE,
                   <fs_table>          TYPE table.

    DATA lt_arquivo TYPE TABLE OF string .
    DATA lv_linha TYPE string.

    "----------------------------------------------------------------------------------------
    " Converter parâmetros da tela para o formato abap
    "----------------------------------------------------------------------------------------
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
            LOOP AT <fst_select_option>
              ASSIGNING FIELD-SYMBOL(<fs_first_line>).
              <fs_select_option> = <fs_first_line>.
              EXIT.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ELSE.
        ASSIGN (lw_sel_screen-selname) TO <fs_parameter> .
        IF sy-subrc IS INITIAL.
          <fs_parameter> = lw_sel_screen-low.
        ENDIF.
      ENDIF.
      FREE wa_dref.
    ENDLOOP.

    "----------------------------------------------------------------------------------------
    " Corrigir último dia do mês no período final
    " Vem da tela sempre com dia 31 fixo como data fim
    "----------------------------------------------------------------------------------------
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

    "----------------------------------------------------------------------------------------
    " Instanciar a classe de acesso ao hana
    "----------------------------------------------------------------------------------------
    DATA(lo_db_select) = NEW /dpf/cl_db_select(
      iv_empresa = p_bukrs
      iv_filial  = p_branch
    ).

    "----------------------------------------------------------------------------------------
    " VERIFICAR SE É A GERAÇÃO DO ARQUIVO OU RELATÓRIO EM TELA
    "----------------------------------------------------------------------------------------
    IF p_gerar = ''.  "Se não foi clique no botão Gerar Arquivo FCI

      "MES CONSIDERADO - 2 MESES
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

      lv_mes_anterior_de  = lv_ano_cons && lv_mes_cons && sw_date-low+6(2).
      lv_mes_anterior_ate = lv_ano_cons && lv_mes_cons && sw_date-high+6(2).

      "----------------------------------------------------------------------------------------
      "RETORNAR TODOS OS ITENS - ATUALIZACAO APÓS O CHAMADO #10476
      "----------------------------------------------------------------------------------------
      me->calculo_fci_atualizado(
        EXPORTING
          iv_input_mandt        = p_mandt
          iv_input_empresa      = p_bukrs
          iv_input_filial       = p_branch
          iv_input_periodo_de   = lv_mes_anterior_de "sw_date-low
          iv_input_periodo_ate  = lv_mes_anterior_ate "sw_date-high
          iv_input_concatena    = p_concat
          iv_input_direct       = '2'
          iv_input_cod_produto  = cl_shdb_seltab=>combine_seltabs(
                                    it_named_seltabs = VALUE #( (
                                      name = 'COD_PRODUTO'
                                      dref = REF #( s_produ[] ) )
                                    )
                                  )
          iv_input_ncm          = cl_shdb_seltab=>combine_seltabs(
                                    it_named_seltabs = VALUE #( (
                                      name = 'COD_NCM'
                                      dref = REF #( s_ncm[] ) )
                                    )
                                  )
        CHANGING
          et_produto_saida      = lt_produtos_saida
          et_item_saida         = lt_itens_saida
          et_item_entrada       = lt_itens_entrada
          et_movimento_nota     = lt_notas_saida
      ).

      "----------------------------------------------------------------------------------------
      " CALCULO MOVIMENTO DA NOTA
      "----------------------------------------------------------------------------------------
      me->calculo_movimento_nota(
        EXPORTING
          iv_input_mandt      = p_mandt
          iv_input_empresa    = p_bukrs
          iv_input_filial     = p_branch
          iv_input_periodo_de = sw_date-low
          iv_input_recalcula  = p_recalc
          iv_input_relatorio  = lt_notas_saida
        IMPORTING
          et_calculo          = DATA(lt_calculo_fci_saida)
          et_relatorio        = DATA(lt_relatorio_mov_nota)
      ).

      CALL FUNCTION 'TH_REDISPATCH'.

      "----------------------------------------------------------------------------------------
      " PEGAR SELEÇÃO DAS NOTAS COM DIRECT 1 NO PERIODO CONSIDERADO
      " 12 MESES DOS ITENS NÃO ENCONTRADOS NA SELEÇÃO ANTERIOR
      "----------------------------------------------------------------------------------------
      me->selecao_notas(
        EXPORTING
          iv_input_mandt           = p_mandt
          iv_input_empresa         = p_bukrs
          iv_input_filial          = p_branch
          iv_input_periodo_de      = lv_mes_anterior_de "p_mes_considerado_de
          iv_input_periodo_ate     = lv_mes_anterior_ate "p_mes_considerado_ate
          iv_input_concatena       = p_concat
          iv_input_direct          = '1'
          iv_input_item            = lt_itens_entrada
        IMPORTING
          et_itens_nao_encontrados = DATA(lt_itens_sem_entrada_saida)
          et_notas_total           = DATA(lt_notas_entrada)
      ).

      "----------------------------------------------------------------------------------------
      " CALCULO CUSTO EFETIVO
      "----------------------------------------------------------------------------------------
      me->calculo_custo_efetivo(
        EXPORTING
          iv_input_mandt      = p_mandt
          iv_input_empresa    = p_bukrs
          iv_input_filial     = p_branch
          iv_input_periodo_de = lv_mes_anterior_de " sw_date-low
          iv_input_recalcula  = p_recalc
          iv_input_relatorio  = lt_notas_entrada
        IMPORTING
          et_calculo          = DATA(lt_calculo_fci_entrada)
          et_relatorio        = DATA(lt_relatorio_custo_efetivo)
      ).

      CALL FUNCTION 'TH_REDISPATCH'.

      DATA: lv_qtde_ent        TYPE /tmf/de_dec_25_6,
            lv_total_ent       TYPE /tmf/de_dec_25_6,
            lv_unit_ent        TYPE /tmf/de_dec_25_6,
            lt_retorno_entrada TYPE ty_t_relatorio_memoria_ent,
            ls_retorno_entrada TYPE ty_relatorio_memoria_ent,
            lt_prod_sem_conv   TYPE ty_t_prod_saida.

      LOOP AT lt_calculo_fci_entrada ASSIGNING FIELD-SYMBOL(<fs_calculo_entrada>).

        LOOP AT lt_produtos_saida ASSIGNING FIELD-SYMBOL(<fs_produtos_saida>)
          WHERE cod_item_comp = <fs_calculo_entrada>-cod_item
            AND conversao     = 1.

          LOOP AT lt_calculo_fci_saida ASSIGNING FIELD-SYMBOL(<fs_calculo_saida>)
            WHERE cod_item = <fs_produtos_saida>-cod_item
              AND empresa  = <fs_produtos_saida>-empresa.

            IF (
                 ( p_recalc <> 'X' )
                 OR
                 ( p_recalc = 'X' AND <fs_calculo_saida>-vlr_tot_ent = 0 )
               ).

              CLEAR lv_qtde_ent.
              CLEAR lv_total_ent.
              CLEAR lv_unit_ent.

              lv_qtde_ent  = <fs_calculo_entrada>-qtde_tot_ent.
              lv_total_ent = <fs_calculo_entrada>-vlr_tot_ent.
              lv_unit_ent  = ( ( <fs_calculo_entrada>-vlr_unit_ent ) * <fs_produtos_saida>-fat_conv ) * ( <fs_calculo_entrada>-perc_calc / 100 ) . " 29/01/2020

              <fs_calculo_saida>-vlr_tot_ent    = <fs_calculo_saida>-vlr_tot_ent  + lv_total_ent.
              <fs_calculo_saida>-qtde_tot_ent   = <fs_calculo_saida>-qtde_tot_ent + lv_qtde_ent.
              <fs_calculo_saida>-vlr_unit_ent   = <fs_calculo_saida>-vlr_unit_ent + lv_unit_ent.

              <fs_calculo_saida>-vlr_unit_ent   = round( val = <fs_calculo_saida>-vlr_unit_ent dec = 2 ).
              <fs_calculo_saida>-vlr_unit_saida = round( val = <fs_calculo_saida>-vlr_unit_saida dec = 2 ).

              IF <fs_calculo_saida>-vlr_unit_saida <> '0.00'.
                <fs_calculo_saida>-perc_ci      = ( <fs_calculo_saida>-vlr_unit_ent / <fs_calculo_saida>-vlr_unit_saida ) * 100.
              ELSE.
                <fs_calculo_saida>-perc_ci      = 0.
              ENDIF.
              <fs_calculo_saida>-perc_ci        = round( val = <fs_calculo_saida>-perc_ci dec = 2 ).

            ENDIF.

          ENDLOOP.

          LOOP AT lt_relatorio_mov_nota ASSIGNING FIELD-SYMBOL(<fs_relatorio_mov_nota>)
            WHERE cod_item = <fs_produtos_saida>-cod_item.

            IF (
                 ( p_recalc <> 'X' )
                 OR
                 ( p_recalc = 'X' AND <fs_relatorio_mov_nota>-vlr_unit_ent = 0 )
               ).

              CLEAR lv_qtde_ent.
              CLEAR lv_total_ent.
              CLEAR lv_unit_ent.

              lv_qtde_ent  = <fs_calculo_entrada>-qtde_tot_ent.
              lv_total_ent = <fs_calculo_entrada>-vlr_tot_ent.
              lv_unit_ent  = ( ( <fs_calculo_entrada>-vlr_unit_ent ) * <fs_produtos_saida>-fat_conv ) * ( <fs_calculo_entrada>-perc_calc / 100 ) . " 29/01/2020

              <fs_relatorio_mov_nota>-vlr_unit_ent   = <fs_relatorio_mov_nota>-vlr_unit_ent + lv_unit_ent.

              <fs_relatorio_mov_nota>-vlr_unit_ent   = round( val = <fs_relatorio_mov_nota>-vlr_unit_ent dec = 2 ).
              <fs_relatorio_mov_nota>-vlr_unit_saida = round( val = <fs_relatorio_mov_nota>-vlr_unit_saida dec = 2 ).

              IF <fs_relatorio_mov_nota>-vlr_unit_saida <> '0.00'.
                <fs_relatorio_mov_nota>-perc_ci      = ( <fs_relatorio_mov_nota>-vlr_unit_ent / <fs_relatorio_mov_nota>-vlr_unit_saida ) * 100.
              ELSE.
                <fs_relatorio_mov_nota>-perc_ci      = 0.
              ENDIF.
              <fs_relatorio_mov_nota>-perc_ci        = round( val = <fs_relatorio_mov_nota>-perc_ci dec = 2 ).

            ENDIF.

          ENDLOOP.

          READ TABLE lt_retorno_entrada TRANSPORTING NO FIELDS
              WITH KEY cod_item     = <fs_calculo_entrada>-cod_item
                       cod_item_pai = <fs_produtos_saida>-cod_item.

          IF sy-subrc IS NOT INITIAL.
            LOOP AT lt_relatorio_custo_efetivo ASSIGNING FIELD-SYMBOL(<fs_rce>)
              WHERE cod_item = <fs_calculo_entrada>-cod_item.

              CLEAR ls_retorno_entrada.
              CLEAR lv_qtde_ent.
              CLEAR lv_total_ent.
              CLEAR lv_unit_ent.

              lv_qtde_ent  = <fs_rce>-quantidade.
              lv_total_ent = <fs_rce>-vl_item.
              lv_unit_ent  = ( ( <fs_rce>-vlr_unit_ent ) * <fs_produtos_saida>-fat_conv ) * ( <fs_calculo_entrada>-perc_calc / 100 ) . " 29/01/2020

              ls_retorno_entrada-mandt            = <fs_rce>-mandt.
              ls_retorno_entrada-cod_item_pai     = <fs_produtos_saida>-cod_item.
              ls_retorno_entrada-cod_item         = <fs_rce>-cod_item.
              ls_retorno_entrada-unid_inv         = <fs_rce>-unid_inv.
              ls_retorno_entrada-vlr_unit_ent     = lv_unit_ent.
              ls_retorno_entrada-vlr_unit_saida   = <fs_rce>-vlr_unit_saida.
              ls_retorno_entrada-perc_ci          = <fs_rce>-perc_ci.
              ls_retorno_entrada-cfop             = <fs_rce>-cfop.
              ls_retorno_entrada-cod_ncm          = <fs_rce>-cod_ncm.
              ls_retorno_entrada-numero_documento = <fs_rce>-numero_documento.

              IF <fs_rce>-dt_doc <> ''.
                ls_retorno_entrada-dt_doc = <fs_rce>-dt_doc+6(2) && '/' && <fs_rce>-dt_doc+4(2) && '/' && <fs_rce>-dt_doc+0(4).
              ENDIF.

              ls_retorno_entrada-unid_medida = <fs_rce>-unid_medida.
              ls_retorno_entrada-cod_part    = <fs_rce>-cod_part.
              ls_retorno_entrada-quantidade  = lv_qtde_ent.
              ls_retorno_entrada-vl_item     = lv_total_ent.
              ls_retorno_entrada-descr_item  = <fs_rce>-descr_item.
              ls_retorno_entrada-coeficiente = <fs_produtos_saida>-fat_conv.
              ls_retorno_entrada-mtorg       = <fs_rce>-mtorg.
              ls_retorno_entrada-nf_id       = <fs_rce>-nf_id. "Wander - 20/10/2020 - #10296

              APPEND ls_retorno_entrada TO lt_retorno_entrada.

            ENDLOOP.
          ENDIF.

        ENDLOOP.

        READ TABLE lt_produtos_saida INTO DATA(ls_produtos_saida)
          WITH KEY cod_item_comp = <fs_calculo_entrada>-cod_item
                   conversao     = 1.

        IF sy-subrc IS NOT INITIAL.
          LOOP AT lt_produtos_saida INTO ls_produtos_saida
            WHERE cod_item_comp = <fs_calculo_entrada>-cod_item
              AND conversao     = 0.

            APPEND ls_produtos_saida TO lt_prod_sem_conv.
          ENDLOOP.
        ENDIF.

      ENDLOOP.

      DATA lt_calc_fci TYPE ty_t_calculo_fci.

      LOOP AT lt_calculo_fci_saida INTO DATA(ls_calcfci)
        WHERE perc_ci <> 0.

        "O percentual aqui está arredondado e causa diferença na determinação da origem.
        "Buscar o perc_ci na lt_relatorio_mov_nota
        DATA(lv_perc_ci_aux) = VALUE /tmf/de_dec_25_6( lt_relatorio_mov_nota[ mandt    = ls_calcfci-mandt
                                                                              cod_item = ls_calcfci-cod_item
                                                                              mtorg    = ls_calcfci-origem_material
                                                                              planta   = ls_calcfci-planta ]-perc_ci OPTIONAL ).

        IF lv_perc_ci_aux IS NOT INITIAL.
          ls_calcfci-perc_ci = lv_perc_ci_aux.
        ENDIF.

        CLEAR lv_perc_ci_aux.

        APPEND ls_calcfci TO lt_calc_fci.
      ENDLOOP.

      CALL FUNCTION 'TH_REDISPATCH'.

      me->origem_material(
        EXPORTING
          iv_input_mandt = p_mandt
          iv_calculo     = lt_calc_fci
        IMPORTING
          et_origem      = DATA(lt_relatorio_origem_material)
      ).

      "----------------------------------------------------------------------------------------
      " RETORNO
      "----------------------------------------------------------------------------------------
      me->montar_cabecalho_auto(
        EXPORTING
          iv_empresa   = p_bukrs
          iv_filial    = p_branch
        IMPORTING
          et_cabecalho = DATA(et_cabecalho)
      ).

      wa_retorno_cabecalho-periodo_ref = sw_date-low+4(2) && '/' && sw_date-low+0(4).
      wa_retorno_cabecalho-empresa     = et_cabecalho-nome_estabelec.
      wa_retorno_cabecalho-filial      = p_branch.
      wa_retorno_cabecalho-teste       = p_mteste.

      lt_retorno-cabecalho = wa_retorno_cabecalho.

      DATA lt_retorno_mov_nota TYPE ty_t_relatorio_memoria.

      LOOP AT lt_relatorio_mov_nota ASSIGNING FIELD-SYMBOL(<fs_rel_mv_nt>).
        IF <fs_rel_mv_nt>-dt_doc <> ''.
          <fs_rel_mv_nt>-dt_doc = <fs_rel_mv_nt>-dt_doc+6(2) && '/' && <fs_rel_mv_nt>-dt_doc+4(2) && '/' && <fs_rel_mv_nt>-dt_doc+0(4).
        ENDIF.
        IF <fs_rel_mv_nt>-perc_ci <> 0.
          APPEND <fs_rel_mv_nt> TO lt_retorno_mov_nota.
        ENDIF.
      ENDLOOP.

      DATA: lt_conteudo_importacao TYPE ty_t_conteudo_importacao,
            ls_conteudo_importacao TYPE ty_conteudo_importacao.

      LOOP AT lt_retorno_mov_nota ASSIGNING FIELD-SYMBOL(<fs_ret_mov_nt>).

        READ TABLE lt_conteudo_importacao TRANSPORTING NO FIELDS
          WITH KEY cod_item = <fs_ret_mov_nt>-cod_item.

        IF sy-subrc IS NOT INITIAL.
          CLEAR ls_conteudo_importacao.

          ls_conteudo_importacao-cod_item         = <fs_ret_mov_nt>-cod_item.
          ls_conteudo_importacao-unid_inv         = <fs_ret_mov_nt>-unid_inv.
          ls_conteudo_importacao-vlr_unit_ent     = <fs_ret_mov_nt>-vlr_unit_ent.
          ls_conteudo_importacao-vlr_unit_saida   = <fs_ret_mov_nt>-vlr_unit_saida.
          ls_conteudo_importacao-perc_ci          = <fs_ret_mov_nt>-perc_ci.

          APPEND ls_conteudo_importacao TO lt_conteudo_importacao.
        ENDIF.

      ENDLOOP.

      lt_retorno-relatorios-memoria_saida             = lt_retorno_mov_nota.
      lt_retorno-relatorios-memoria_entrada           = lt_retorno_entrada.
      lt_retorno-relatorios-conteudo_importacao       = lt_conteudo_importacao.
      lt_retorno-relatorios-origem_material           = lt_relatorio_origem_material.

      "----------------------------------------------------------------------------------------
      " GRAVAÇÃO NA TABELA CALCULO_FCI
      "----------------------------------------------------------------------------------------

      "----------------------------------------------------------------------------------------
      " ARQUIVO NO TOM COM ITENS SEM ENTRADA E SAÍDA NO PERIODO
      "----------------------------------------------------------------------------------------
      CLEAR lt_arquivo.

      IF lt_itens_sem_entrada_saida IS NOT INITIAL.
        lv_linha = 'COD_ITEM; COD_ITEM_COMP; MOTIVO;'.

        APPEND lv_linha TO lt_arquivo.

        LOOP AT lt_itens_sem_entrada_saida ASSIGNING FIELD-SYMBOL(<fs_itsem_entsai>).
          CLEAR lv_linha.

          READ TABLE lt_produtos_saida INTO DATA(wa_prod_sai)
            WITH KEY cod_item_comp = <fs_itsem_entsai>-cod_item.

          IF sy-subrc IS INITIAL.
            lv_linha = wa_prod_sai-cod_item  && '; ' &&
                    <fs_itsem_entsai>-cod_item && '; SEM ENTRADA NOS ULTIMOS 12 MESES;'.
          ELSE.
            lv_linha = <fs_itsem_entsai>-cod_item && ';; PRODUTO DE SAÍDA SEM INSUMOS;'.
          ENDIF.

          APPEND lv_linha TO lt_arquivo.
        ENDLOOP.
      ENDIF.

      CLEAR lv_linha.

      IF lt_prod_sem_conv IS NOT INITIAL.
        IF lt_arquivo IS INITIAL.
          lv_linha = 'COD_ITEM; COD_ITEM_COMP; MOTIVO;'.
          APPEND lv_linha TO lt_arquivo.
        ENDIF.

        DATA lt_prd_add     TYPE ty_t_prod_saida.

        LOOP AT lt_prod_sem_conv INTO DATA(ls_prod_sem_conv).
          READ TABLE lt_prd_add TRANSPORTING NO FIELDS
            WITH KEY cod_item      = ls_prod_sem_conv-cod_item
                     cod_item_comp = ls_prod_sem_conv-cod_item_comp.

          IF sy-subrc IS NOT INITIAL.
            CLEAR lv_linha.

            lv_linha = ls_prod_sem_conv-cod_item  && '; ' &&
                    ls_prod_sem_conv-cod_item_comp && '; SEM FATOR DE CONVERSAO - ' &&
                    ls_prod_sem_conv-unid_inv_comp && ' - ' && ls_prod_sem_conv-unid_inv && ';'.

            APPEND lv_linha TO lt_arquivo.
            APPEND ls_prod_sem_conv TO lt_prd_add.
          ENDIF.
        ENDLOOP.
      ENDIF.

      IF p_json = 'X'.
        DATA(lo_report_run) = /dpf/cl_tom_integration=>create_or_running(
          i_empresa     = p_bukrs
          i_filial      = p_branch
          i_periodo_ini = CONV #( sw_date-low )
          i_periodo_fin = CONV #( sw_date-high )
          i_report_id   =  me->mv_report_id
          i_run_id      = i_run_id
        ).

        IF p_mteste <> 'X'.
          LOOP AT lt_calc_fci INTO DATA(wa_fci_sai).
            DELETE FROM /dpf/d_fci_calc CLIENT SPECIFIED
                WHERE mandt = wa_fci_sai-mandt.
          ENDLOOP.

          MODIFY /dpf/d_fci_calc USING CLIENT @p_mandt FROM TABLE @lt_calc_fci.
        ENDIF.

        IF lt_arquivo IS NOT INITIAL.
          TRY.
              /dpf/cl_tom_integration=>create_file(
                io_report_run     = lo_report_run
                file_name         = CONV #( 'Itens_sem_entrada_saida' )
                it_file_table     = lt_arquivo
                iv_file_extension = '.CSV'
                iv_aux_file       = 'X'
              ).

              COMMIT WORK AND WAIT.

            CATCH cx_root INTO DATA(lo_root).
              lo_report_run = /tmf/cl_tom_metadata=>change_report_run_status(
                EXPORTING
                  iv_run_id     = lo_report_run->get_run_id( )
                  iv_status     = /tmf/cl_constants=>mo_tom->report_status-error
              ).

              RAISE EXCEPTION lo_root.
          ENDTRY.
        ENDIF.

        IF p_mteste <> 'X'.
          me->gerar_excel(
            EXPORTING
              lt_retorno = lt_retorno
            IMPORTING
              lv_zip     = DATA(lv_zip)
          ).

          TRY.
              /dpf/cl_tom_integration=>create_file(
                io_report_run     = lo_report_run
                file_name         = CONV #( 'FCI_produtos' )
                i_binary          = lv_zip
                iv_file_extension = '.zip'
              ).

              COMMIT WORK AND WAIT.

            CATCH cx_root INTO lo_root.
              lo_report_run = /tmf/cl_tom_metadata=>change_report_run_status(
                EXPORTING
                  iv_run_id = lo_report_run->get_run_id( )
                  iv_status = /tmf/cl_constants=>mo_tom->report_status-error
              ).
              RAISE EXCEPTION lo_root.
          ENDTRY.
        ENDIF.

        IF lt_arquivo IS NOT INITIAL
          OR p_mteste <> 'X'.

          lo_report_run = /tmf/cl_tom_metadata=>change_report_run_status(
            EXPORTING
              iv_run_id = lo_report_run->get_run_id( )
              iv_status = /tmf/cl_constants=>mo_tom->report_status-created
          ).

          me->response_from_report_run(
            EXPORTING
              io_report_run = lo_report_run
            IMPORTING
              ev_file_url   = DATA(iv_url) " URL TOM DO ARQUIVO GERADO
          ).
        ENDIF.

        " FIM ARQUIVO NO TOM COM ITENS SEM ENTRADA E SAÍDA NO PERIODO
      ENDIF.

      IF lt_arquivo IS NOT INITIAL.
        lt_retorno-itens_nao_encontrados = iv_url.
      ENDIF.

      IF lv_zip IS NOT INITIAL.
        lt_retorno-excel_gerado = iv_url.
      ENDIF.

    ELSE.

      "Tratar clique no botão Gerar Arquivo FCI
      CALL FUNCTION 'TH_REDISPATCH'.

      "----------------------------------------------------------------------------------------
      " Gerar arquivo
      "----------------------------------------------------------------------------------------
      me->gerar_arquivo(
        EXPORTING
          iv_input_mandt          = p_mandt
          iv_input_empresa        = p_bukrs
          iv_input_filial         = p_branch
          iv_input_periodo_de     = sw_date-low
          iv_input_concatena      = p_concat
        IMPORTING
          et_registro_tabela_5020 = DATA(lt_registro_tabela_5020)
          et_arquivo              = DATA(lt_arquivo_gerado)
          et_dados                = DATA(lt_dados)
      ).

      MODIFY /dpf/d_fci_r5020 USING CLIENT @p_mandt FROM TABLE @lt_registro_tabela_5020.

      lo_report_run = /dpf/cl_tom_integration=>create_or_running(
        i_empresa     = p_bukrs
        i_filial      = p_branch
        i_periodo_ini = CONV #( sw_date-low )
        i_periodo_fin = CONV #( sw_date-high )
        i_report_id   = me->mv_report_id
        i_run_id      = i_run_id
      ).

      DATA iv_varias TYPE flag.
      DATA lv_file_content TYPE xstring.

      DATA(lo_zipper) = NEW cl_abap_zip( ).

      lo_zipper->support_unicode_names = 'X'.

      LOOP AT lt_dados ASSIGNING FIELD-SYMBOL(<fs_dados>).
        CLEAR lt_arquivo.
        CLEAR lv_file_content.

        IF <fs_dados>-total_filiais > 1.
          iv_varias = 'X'.
        ENDIF.

        "----------------------------------------------------------------------------------------
        " CONTEUDO DO ARQUIVO
        "----------------------------------------------------------------------------------------
        LOOP AT lt_arquivo_gerado INTO DATA(wa_linha)
          WHERE filial = <fs_dados>-filial.
          APPEND wa_linha-linha TO lt_arquivo.
        ENDLOOP.

        " NOME DO ARQUIVO
        DATA(nome_arquivo) = <fs_dados>-cnpj && '_' && sy-datum && '_' && sy-uzeit.

        "----------------------------------------------------------------------------------------
        " CRIAÇÃO DO ARQUIVO EM BINARIO COM CODIFICAÇÃO UTF-8
        "----------------------------------------------------------------------------------------
        DATA lv_body_xstring TYPE xstring.
        DATA lc_crlv TYPE xstring VALUE '0D0A'.
        FIELD-SYMBOLS: <fs_line> TYPE any.

        LOOP AT lt_arquivo ASSIGNING <fs_line>.
          CLEAR lv_body_xstring.
          CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
            EXPORTING
              text     = <fs_line>
              encoding = '4110'
            IMPORTING
              buffer   = lv_body_xstring
            EXCEPTIONS
              failed   = 1
              OTHERS   = 2.
          CONCATENATE lv_file_content lv_body_xstring lc_crlv INTO lv_file_content IN BYTE MODE.
        ENDLOOP.

        " FIM DO ARQUIVO

        "----------------------------------------------------------------------------------------
        " ADICIONANDO ARQUIVO AO ZIP
        "----------------------------------------------------------------------------------------
        lo_zipper->add(
          EXPORTING
            name    = nome_arquivo && '.txt'
            content = lv_file_content
        ).

      ENDLOOP.

      "----------------------------------------------------------------------------------------
      " FECHANDO ARQUIVO ZIP
      "----------------------------------------------------------------------------------------
      lv_zip = lo_zipper->save( ).

      TRY.
          /dpf/cl_tom_integration=>create_file(
            io_report_run     = lo_report_run
            file_name         = CONV #( 'FCI_arquivos' )
            i_binary          = lv_zip
            iv_file_extension = '.zip'
          ).

          COMMIT WORK AND WAIT.

        CATCH cx_root INTO lo_root.
          lo_report_run = /tmf/cl_tom_metadata=>change_report_run_status(
            EXPORTING
              iv_run_id = lo_report_run->get_run_id( )
              iv_status = /tmf/cl_constants=>mo_tom->report_status-error
          ).

          RAISE EXCEPTION lo_root.
      ENDTRY.

      lo_report_run = /tmf/cl_tom_metadata=>change_report_run_status(
        EXPORTING
          iv_run_id = lo_report_run->get_run_id( )
          iv_status = /tmf/cl_constants=>mo_tom->report_status-created
      ).

      me->response_from_report_run(
        EXPORTING
          io_report_run = lo_report_run
        IMPORTING
          ev_file_url   = iv_url " URL TOM DO ARQUIVO GERADO
      ).

      lt_retorno-arquivo_gerado = 'X'.
      lt_retorno-link_arquivo = iv_url.

    ENDIF.

    "-----------------------------------------------------------------------------------
    " Tratar opção selecionada na tela
    "-----------------------------------------------------------------------------------
    CASE abap_true.

      WHEN p_json.

        CREATE DATA eo_output_data LIKE lt_retorno.
        ASSIGN eo_output_data->*  TO FIELD-SYMBOL(<ft_retorno>).
        <ft_retorno> = lt_retorno.

      WHEN p_csvtom.

        me->gerar_excel(
          EXPORTING
            lt_retorno = lt_retorno
          IMPORTING
            lv_zip     = lv_zip
        ).

        lo_report_run = /dpf/cl_tom_integration=>create_or_running(
          i_empresa     = p_bukrs
          i_filial      = p_branch
          i_periodo_ini = CONV #( sw_date-low )
          i_periodo_fin = CONV #( sw_date-high )
          i_report_id   =  me->mv_report_id
          i_run_id      = i_run_id
        ).

        TRY.
            /dpf/cl_tom_integration=>create_file(
              io_report_run     = lo_report_run
              file_name         = CONV #( 'FCI_produtos' )
              i_binary          = lv_zip
              iv_file_extension = '.zip'
            ).

            COMMIT WORK AND WAIT.

          CATCH cx_root INTO lo_root.
            lo_report_run = /tmf/cl_tom_metadata=>change_report_run_status(
              EXPORTING
                iv_run_id = lo_report_run->get_run_id( )
                iv_status = /tmf/cl_constants=>mo_tom->report_status-error
            ).

            RAISE EXCEPTION lo_root.
        ENDTRY.

    ENDCASE.

  ENDMETHOD.

  METHOD calculo_fci_atualizado.

    DATA: lt_itens_novos          TYPE ty_t_itens_novos,
          lt_cod_produto_saida    TYPE ty_t_cod_prod_sai,
          lv_contagem             TYPE i,
          lv_data_considerada_de  TYPE datum,
          lv_data_considerada_ate TYPE datum,
          lv_ano_cons             TYPE i,
          lv_mes_cons             TYPE i,
          lv_mes_char             TYPE c LENGTH 2,
          lv_ano_char             TYPE c LENGTH 4,
          lv_last_day             TYPE sy-datum,
          lt_relatorio_item       TYPE ty_t_rel_item.

    "----------------------------------------------------------------------------------------
    " PESQUISA OS PRODUTOS DE SAÍDA DO MÊS CONSIDERADO
    "----------------------------------------------------------------------------------------
    me->call_produtos_saida(
      EXPORTING
        iv_input_mandt         = iv_input_mandt
        iv_input_empresa       = iv_input_empresa
        iv_input_filial        = iv_input_filial
        iv_input_periodo_de    = iv_input_periodo_de "sw_date-low
        iv_input_periodo_ate   = iv_input_periodo_ate "sw_date-high
        iv_input_concatena     = iv_input_concatena
        iv_input_direct        = iv_input_direct
        iv_input_cod_produto   = iv_input_cod_produto
        iv_input_ncm           = iv_input_ncm
      CHANGING
        et_itens_novos         = lt_itens_novos
        et_cod_produto_saida   = lt_cod_produto_saida
        et_relatorio_item      = lt_relatorio_item
    ).

    CALL FUNCTION 'TH_REDISPATCH'.

    "----------------------------------------------------------------------------------------
    " LOOP DE 12 MESES PARA ENCONTRAR NOTAS DE SAÍDAS DOS PRODUTOS NOVOS - 10476
    "----------------------------------------------------------------------------------------
    IF lt_itens_novos IS NOT INITIAL.

      lv_contagem = 1.

      WHILE lv_contagem <= 12.

        lv_data_considerada_de  = iv_input_periodo_de.
        lv_data_considerada_ate = iv_input_periodo_ate.

        lv_mes_cons = lv_data_considerada_de+4(2).
        lv_ano_cons = lv_data_considerada_de+0(4).

        lv_mes_cons = lv_mes_cons - lv_contagem.

        IF lv_mes_cons <= 0 .
          lv_ano_cons = lv_ano_cons - 1.
          lv_mes_cons = lv_mes_cons + 12.
        ENDIF.

        lv_mes_char = lv_mes_cons.
        lv_ano_char = lv_ano_cons.

        IF lv_mes_cons <= 9.
          lv_mes_char = '0' && lv_mes_char.
        ENDIF.

        CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
          EXPORTING
            day_in       = CONV sy-datum( lv_ano_char && lv_mes_char && '01' )
          IMPORTING
            end_of_month = lv_last_day.

        lv_data_considerada_de  = lv_ano_char && lv_mes_char && lv_data_considerada_de+6(2).
        lv_data_considerada_ate = lv_ano_char && lv_mes_char && lv_last_day+6(2).

        me->call_mov_itens_novos(
          EXPORTING
            iv_input_mandt          = iv_input_mandt
            iv_input_empresa        = iv_input_empresa
            iv_input_filial         = iv_input_filial
            iv_input_periodo_de     = lv_data_considerada_de "sw_date-low
            iv_input_periodo_ate    = lv_data_considerada_ate "sw_date-high
            iv_input_concatena      = iv_input_concatena
            iv_input_direct         = iv_input_direct
            iv_input_cod_produto    = iv_input_cod_produto
            iv_input_ncm            = iv_input_ncm
            iv_input_meses_retorno  = lv_contagem
          CHANGING
            et_itens_novos          = lt_itens_novos
            et_cod_produto_saida    = lt_cod_produto_saida
            et_relatorio_item       = lt_relatorio_item
        ).

        CALL FUNCTION 'TH_REDISPATCH'.

        IF lt_itens_novos IS INITIAL.
          lv_contagem = 12.
        ENDIF.

        lv_contagem = lv_contagem + 1.

      ENDWHILE.

    ENDIF.

    "----------------------------------------------------------------------------------------
    " CONTINUA OS SELECTS DA PROCEDURE FCI
    "----------------------------------------------------------------------------------------
    me->call_calc_fci_atual(
      EXPORTING
        iv_input_mandt         = iv_input_mandt
        iv_input_empresa       = iv_input_empresa
        iv_input_filial        = iv_input_filial
        iv_input_periodo_de    = iv_input_periodo_de "sw_date-low
        iv_input_periodo_ate   = iv_input_periodo_ate "sw_date-high
        iv_input_concatena     = iv_input_concatena
        iv_input_direct        = iv_input_direct
        iv_input_cod_produto   = iv_input_cod_produto
        iv_input_ncm           = iv_input_ncm
        it_itens_novos         = lt_itens_novos
        it_cod_produto_saida   = lt_cod_produto_saida
        it_relatorio_item      = lt_relatorio_item
      CHANGING
        et_produto_saida       = et_produto_saida
        et_item_saida          = et_item_saida
        et_item_entrada        = et_item_entrada
        et_movimento_nota      = et_movimento_nota
    ).

    CLEAR lt_itens_novos.
    CLEAR lt_cod_produto_saida.
    CLEAR lt_relatorio_item.

    CALL FUNCTION 'TH_REDISPATCH'.

  ENDMETHOD.


  METHOD gerar_excel.

    DATA: lt_todos_produtos      TYPE TABLE OF string,
          lt_resumo              TYPE TABLE OF string,
          lt_entrada_saida       TYPE TABLE OF string, "Wander - 29/10/2020 - #10385
          lv_linha               TYPE string,
          lv_linha_resumo        TYPE string,
          lv_linha_resumo_origem TYPE string,
          lv_qtde                TYPE string,
          lv_valor               TYPE string,
          lv_file_content        TYPE xstring.

    DATA(lo_zipper) = NEW cl_abap_zip( ).

    CLEAR lt_resumo.
    CLEAR lv_linha.
    CLEAR lv_linha_resumo_origem.
    CLEAR lt_entrada_saida.

    lv_linha = 'MATERIAL; UND; VLR PARCELA IMPORTADA; VLR MEDIO SAIDA; CONTEUDO DE IMPORTACAO; ORIGEM ANTERIOR; NOVA ORIGEM; EMPRESA; FILIAL;'.
    APPEND lv_linha TO lt_resumo.

    LOOP AT lt_retorno-relatorios-conteudo_importacao ASSIGNING FIELD-SYMBOL(<fs_lista_produtos>).

      CLEAR lt_todos_produtos.
      CLEAR lv_linha.
      CLEAR lv_linha_resumo.

      lv_linha = 'REF: ' && lt_retorno-cabecalho-periodo_ref && ';FCI - Conferência do Cálculo;'.
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      lv_linha = 'Empresa; ' && lt_retorno-cabecalho-empresa && ';Filial; ' && lt_retorno-cabecalho-filial && ';'.
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      CLEAR lv_qtde.
      lv_qtde = CONV #( <fs_lista_produtos>-vlr_unit_ent ).
      TRANSLATE lv_qtde USING '.,'.

      CLEAR lv_valor.
      lv_valor = CONV #( <fs_lista_produtos>-vlr_unit_saida ).
      TRANSLATE lv_valor USING '.,'.

      DATA iv_perc_ci TYPE string.
      iv_perc_ci = CONV #( <fs_lista_produtos>-perc_ci ).

      TRANSLATE iv_perc_ci USING '.,'.

      lv_linha = 'MATERIAL; UNID. MEDIDA; VLR PARCELA IMPORTADA; VALOR MEDIO SAIDAS; CONTEUDO IMPORTACAO;'.
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      lv_linha = <fs_lista_produtos>-cod_item && ';' && <fs_lista_produtos>-unid_inv && ';'
        && lv_qtde && ';' && lv_valor && ';' && iv_perc_ci && ';'.
      APPEND lv_linha TO lt_todos_produtos.

      lv_linha_resumo = lv_linha.

      CLEAR lv_linha.
      lv_linha = '' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      lv_linha = 'Origem de Material' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      lv_linha = 'MATERIAL; ORIGEM ANTERIOR; COD MATRIZ; COD CONTRIBUINTE; NOVA ORIGEM DE MATERIAL; ' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      LOOP AT lt_retorno-relatorios-origem_material ASSIGNING FIELD-SYMBOL(<fs_origem_material>)
        WHERE cod_item = <fs_lista_produtos>-cod_item.

        lv_linha = <fs_origem_material>-cod_item && ';' && <fs_origem_material>-origem_material && ';' &&
                   <fs_origem_material>-empresa && ';' && <fs_origem_material>-estabelecimento && ';' &&
                   <fs_origem_material>-org_mat && ';'.
        APPEND lv_linha TO lt_todos_produtos.
        CLEAR lv_linha.

        CLEAR lv_linha_resumo_origem.
        lv_linha_resumo_origem = lv_linha_resumo && <fs_origem_material>-origem_material && ';' && <fs_origem_material>-org_mat && ';' &&
            <fs_origem_material>-empresa && ';' && <fs_origem_material>-estabelecimento && ';'.

        APPEND lv_linha_resumo_origem TO lt_resumo.

      ENDLOOP.

      lv_linha = '' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      lv_linha = 'Memoria de Saida' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      "Wander - 20/10/2020 - #10296 - Inclusão doc num.
*      lv_linha = 'MATERIAL; CFOP; NCM; NUM NF; DT EMISSAO; MEDIDA; PARTICIPANTE; QUANTIDADE TOTAL; VALOR ITEM TOTAL; ' .
      lv_linha = 'MATERIAL; CFOP; NCM; NUM NF; DOC NUM; DT EMISSAO; MEDIDA; PARTICIPANTE; QUANTIDADE TOTAL; VALOR ITEM TOTAL; ' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      LOOP AT lt_retorno-relatorios-memoria_saida ASSIGNING FIELD-SYMBOL(<fs_memoria_saida>)
        WHERE cod_item = <fs_lista_produtos>-cod_item.

        CLEAR lv_qtde.
        lv_qtde = CONV #( <fs_memoria_saida>-quantidade ).
        TRANSLATE lv_qtde USING '.,'.

        CLEAR lv_valor.
        lv_valor = CONV #( <fs_memoria_saida>-vl_item ).
        TRANSLATE lv_valor USING '.,'.

        lv_linha = <fs_memoria_saida>-cod_item && ';' && <fs_memoria_saida>-cfop && ';' &&
                   <fs_memoria_saida>-cod_ncm && ';' && <fs_memoria_saida>-numero_documento && ';' &&
                   <fs_memoria_saida>-nf_id && ';' && "Wander - 20/10/2020 - #10296
                   <fs_memoria_saida>-dt_doc && ';' &&
                   <fs_memoria_saida>-unid_medida && ';' && <fs_memoria_saida>-cod_part && ';' &&
                   lv_qtde && ';' && lv_valor && ';'.
        APPEND lv_linha TO lt_todos_produtos.
        CLEAR lv_linha.

      ENDLOOP.

      lv_linha = '' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      lv_linha = 'Memoria de Entrada' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      "Wander - 20/10/2020 - #10296 - Inclusão doc num.
*      lv_linha = 'MATERIAL; CFOP; NCM; NUM NF; DT EMISSAO; MEDIDA; PARTICIPANTE; QUANTIDADE; VALOR ITEM; FATOR; MTORG;' .
      lv_linha = 'MATERIAL; CFOP; NCM; NUM NF; DOC NUM; DT EMISSAO; MEDIDA; PARTICIPANTE; QUANTIDADE; VALOR ITEM; FATOR; MTORG;' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      LOOP AT lt_retorno-relatorios-memoria_entrada ASSIGNING FIELD-SYMBOL(<fs_memoria_entrada>)
        WHERE cod_item_pai = <fs_lista_produtos>-cod_item.

        CLEAR lv_qtde.
        lv_qtde = CONV #( <fs_memoria_entrada>-quantidade ).
        TRANSLATE lv_qtde USING '.,'.

        CLEAR lv_valor.
        lv_valor = CONV #( <fs_memoria_entrada>-vl_item ).
        TRANSLATE lv_valor USING '.,'.

        CLEAR iv_perc_ci.
        iv_perc_ci = CONV #( <fs_memoria_entrada>-coeficiente ).

        TRANSLATE iv_perc_ci USING '.,'.

        lv_linha = <fs_memoria_entrada>-cod_item && ';' && <fs_memoria_entrada>-cfop && ';' &&
                   <fs_memoria_entrada>-cod_ncm && ';' && <fs_memoria_entrada>-numero_documento && ';' &&
                   <fs_memoria_entrada>-nf_id && ';' && "Wander - 20/10/2020 - #10296
                   <fs_memoria_entrada>-dt_doc && ';' &&
                   <fs_memoria_entrada>-unid_medida && ';' && <fs_memoria_entrada>-cod_part && ';' &&
                   lv_qtde && ';' && lv_valor && ';' && iv_perc_ci && ';' && <fs_memoria_entrada>-mtorg && ';'.
        APPEND lv_linha TO lt_todos_produtos.
        CLEAR lv_linha.

      ENDLOOP.

      lv_linha = '' .
      APPEND lv_linha TO lt_todos_produtos.
      CLEAR lv_linha.

      lv_file_content = /dpf/cl_tom_integration=>create_binary(
            rel_table =  lt_todos_produtos
           ).

      lo_zipper->add(
        EXPORTING
          name    = <fs_lista_produtos>-cod_item && '.csv'
          content = lv_file_content
      ).

    ENDLOOP.

    lv_file_content = /dpf/cl_tom_integration=>create_binary(
      rel_table = lt_resumo
    ).

    lo_zipper->add(
      EXPORTING
        name    = 'Resumo.csv'
        content = lv_file_content
    ).

    "Wander - 29/10/2020 - #10385 - Início
    "Gerar um arquivo com a memória de entrada e saída
    APPEND 'TIPO; MATERIAL; CFOP; NCM; NUM NF; DOC NUM; DT EMISSAO; MEDIDA; PARTICIPANTE; QUANTIDADE; VALOR ITEM; FATOR; MTORG;'
      TO lt_entrada_saida.

    LOOP AT lt_retorno-relatorios-memoria_saida ASSIGNING <fs_memoria_saida>.
      lv_qtde = CONV #( <fs_memoria_saida>-quantidade ).
      TRANSLATE lv_qtde USING '.,'.

      lv_valor = CONV #( <fs_memoria_saida>-vl_item ).
      TRANSLATE lv_valor USING '.,'.

      APPEND 'Saída' && ';' &&
             <fs_memoria_saida>-cod_item && ';' &&
             <fs_memoria_saida>-cfop && ';' &&
             <fs_memoria_saida>-cod_ncm && ';' &&
             <fs_memoria_saida>-numero_documento && ';' &&
             <fs_memoria_saida>-nf_id && ';' &&
             <fs_memoria_saida>-dt_doc && ';' &&
             <fs_memoria_saida>-unid_medida && ';' &&
             <fs_memoria_saida>-cod_part && ';' &&
             lv_qtde && ';' &&
             lv_valor && ';' &&
             '' && ';' &&
             '' && ';'
             TO lt_entrada_saida.
    ENDLOOP.

    LOOP AT lt_retorno-relatorios-memoria_entrada ASSIGNING <fs_memoria_entrada>.
      lv_qtde = CONV #( <fs_memoria_entrada>-quantidade ).
      TRANSLATE lv_qtde USING '.,'.

      lv_valor = CONV #( <fs_memoria_entrada>-vl_item ).
      TRANSLATE lv_valor USING '.,'.

      iv_perc_ci = CONV #( <fs_memoria_entrada>-coeficiente ).
      TRANSLATE iv_perc_ci USING '.,'.

      APPEND 'Entrada' && ';' &&
             <fs_memoria_entrada>-cod_item && ';' &&
             <fs_memoria_entrada>-cfop && ';' &&
             <fs_memoria_entrada>-cod_ncm && ';' &&
             <fs_memoria_entrada>-numero_documento && ';' &&
             <fs_memoria_entrada>-nf_id && ';' &&
             <fs_memoria_entrada>-dt_doc && ';' &&
             <fs_memoria_entrada>-unid_medida && ';' &&
             <fs_memoria_entrada>-cod_part && ';' &&
             lv_qtde && ';' &&
             lv_valor && ';' &&
             iv_perc_ci && ';' &&
             <fs_memoria_entrada>-mtorg && ';'
             TO lt_entrada_saida.
    ENDLOOP.

    lv_file_content = /dpf/cl_tom_integration=>create_binary(
      rel_table =  lt_entrada_saida
    ).

    lo_zipper->add(
      EXPORTING
        name    = 'Memoria_Saidas_Entradas.csv'
        content = lv_file_content
    ).
    "Wander - 29/10/2020 - #10385 - Fim

    lv_zip = lo_zipper->save( ).

  ENDMETHOD.


  METHOD selecao_notas.

    DATA: lv_data_considerada_de   TYPE datum,
          lv_data_considerada_ate  TYPE datum,
          lv_ano_cons              TYPE i,
          lv_mes_cons              TYPE i,
          lv_ano_char              TYPE char4,
          lv_mes_char              TYPE char2,
          lw_itens_ne              TYPE ty_itens,
          lt_itens_nao_encontradas TYPE ty_t_itens,
          lt_itens_pesquisa        TYPE ty_t_itens,
          lt_notas_todas           TYPE ty_t_nf,
          lv_contagem              TYPE i,
          lv_last_day              TYPE sy-datum,
          lv_n_cont                TYPE i.

    lv_data_considerada_de  = iv_input_periodo_de.
    lv_data_considerada_ate = iv_input_periodo_ate.

    lv_contagem = 1.

    APPEND LINES OF iv_input_item TO lt_itens_nao_encontradas.

    WHILE lv_contagem <= 12.

      CLEAR lt_itens_pesquisa.

      APPEND LINES OF lt_itens_nao_encontradas TO lt_itens_pesquisa. "ITENS NÃO ENCONTRADOS NA PESQUISA ANTERIOR OU NO INICIO DA PESQUISA

      me->retorna_notas(
        EXPORTING
          iv_input_mandt          = iv_input_mandt
          iv_input_empresa        = iv_input_empresa
          iv_input_filial         = iv_input_filial
          iv_input_periodo_de     = lv_data_considerada_de
          iv_input_periodo_ate    = lv_data_considerada_ate
          iv_input_concatena      = iv_input_concatena
          iv_input_direct         = iv_input_direct
          iv_input_item           = lt_itens_pesquisa
        IMPORTING
          et_out_retorno          = DATA(lt_notas)
      ).

      CALL FUNCTION 'TH_REDISPATCH'.

      APPEND LINES OF lt_notas TO lt_notas_todas. " ADICIONA NOTAS NA LISTA

      SORT lt_notas BY cod_item. " ORDENA POR ITEM

      IF lt_notas IS NOT INITIAL.
        CLEAR lt_itens_nao_encontradas. " LIMPA ITENS NÃO ENCONTRADOS

        LOOP AT lt_itens_pesquisa INTO lw_itens_ne. " LOOP NOS ITENS PESQUISADOS
          READ TABLE lt_notas TRANSPORTING NO FIELDS BINARY SEARCH
            WITH KEY cod_item = lw_itens_ne-cod_item.

          IF sy-subrc IS NOT INITIAL.
            APPEND lw_itens_ne TO lt_itens_nao_encontradas. " SE NÃO FOR ENCONTRADA NOTAS PARA AQUELE ITEM É ADICIONADO NA LISTA DE NÃO ENCONTRADOS NOVAMENTE
          ENDIF.
        ENDLOOP.

        IF lt_itens_nao_encontradas IS INITIAL. " SE LISTA DE NÃO ENCONTRADOS FOR VAZIA, TODOS OS ITENS JÁ POSSUEM NOTAS
          lv_contagem = 12.
        ENDIF.
      ENDIF.

      lv_n_cont = 1.

      "----------------------------------------------------------------------------------------
      " MES ANTERIOR
      "----------------------------------------------------------------------------------------
      lv_mes_cons = lv_data_considerada_de+4(2).
      lv_ano_cons = lv_data_considerada_de+0(4).

      lv_mes_cons = lv_mes_cons - lv_n_cont.

      IF lv_mes_cons <= 0 .
        lv_ano_cons = lv_ano_cons - 1.
        lv_mes_cons = lv_mes_cons + 12.
      ENDIF.

      lv_ano_char = lv_ano_cons.
      lv_mes_char = lv_mes_cons.

      IF lv_mes_cons <= 9.
        lv_mes_char = '0' && lv_mes_char.
      ENDIF.


      CALL FUNCTION 'SN_LAST_DAY_OF_MONTH'
        EXPORTING
          day_in       = CONV sy-datum( lv_ano_char && lv_mes_char && '01' )
        IMPORTING
          end_of_month = lv_last_day.

      lv_data_considerada_de  = lv_ano_char && lv_mes_char && lv_data_considerada_de+6(2).
      lv_data_considerada_ate = lv_ano_char && lv_mes_char && lv_last_day+6(2).

      "----------------------------------------------------------------------------------------
      " AUMENTA A CONTAGEM DE MESES - MAX 12
      "----------------------------------------------------------------------------------------
      lv_contagem = lv_contagem + 1.

    ENDWHILE.

    et_itens_nao_encontrados = lt_itens_nao_encontradas.
    et_notas_total           = lt_notas_todas.

  ENDMETHOD.

  METHOD constructor.
    super->constructor( ).
  ENDMETHOD.


  METHOD calculo_custo_efetivo BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::CUSTO_EFETIVO" (
        -- IN
        p_mandt       => :iv_input_mandt,
        p_empresa     => :iv_input_empresa,
        p_filial      => :iv_input_filial,
        p_periodo_de  => :iv_input_periodo_de,
        p_recalc      => :iv_input_recalcula,
        p_relatorio   => :iv_input_relatorio,
        -- OUT
        calculo       => :et_calculo,
        relatorio     => :et_relatorio
    );

  ENDMETHOD.


  METHOD calculo_fci BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::CALCULO_FCI" (
        -- IN
        p_mandt         => :iv_input_mandt,
        p_empresa       => :iv_input_empresa,
        p_filial        => :iv_input_filial,
        p_periodo_de    => :iv_input_periodo_de,
        p_periodo_ate   => :iv_input_periodo_ate,
        p_concatena     => :iv_input_concatena,
        p_direct        => :iv_input_direct,
        p_cod_produto   => :iv_input_cod_produto,
        p_ncm           => :iv_input_ncm,
        -- OUT
        produto_saida   => :et_PRODUTO_SAIDA,
        item_saida      => :et_ITEM_SAIDA,
        item_entrada    => :et_ITEM_ENTRADA,
        movimento_nota  => :et_MOVIMENTO_NOTA
    );

  ENDMETHOD.

  METHOD call_calc_fci_atual BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::CALC_FCI_ATUAL" (
        -- IN
        p_mandt           => :iv_input_mandt,
        p_empresa         => :iv_input_empresa,
        p_filial          => :iv_input_filial,
        p_periodo_de      => :iv_input_periodo_de,
        p_periodo_ate     => :iv_input_periodo_ate,
        p_concatena       => :iv_input_concatena,
        p_direct          => :iv_input_direct,
        p_cod_produto     => :iv_input_cod_produto,
        p_ncm             => :iv_input_ncm,
        itens_novos       => :it_itens_novos,
        cod_produto_saida => :it_cod_produto_saida,
        relatorio_item    => :it_relatorio_item,
        -- OUT
        produto_saida     => :et_produto_saida,
        item_saida        => :et_item_saida,
        item_entrada      => :et_item_entrada,
        movimento_nota    => :et_movimento_nota
    );

  ENDMETHOD.

  METHOD call_produtos_saida BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::PRODUTOS_SAIDA" (
        -- IN
        p_mandt           => :iv_input_mandt,
        p_empresa         => :iv_input_empresa,
        p_filial          => :iv_input_filial,
        p_periodo_de      => :iv_input_periodo_de,
        p_periodo_ate     => :iv_input_periodo_ate,
        p_concatena       => :iv_input_concatena,
        p_direct          => :iv_input_direct,
        p_cod_produto     => :iv_input_cod_produto,
        p_ncm             => :iv_input_ncm,
        -- OUT
        itens_novos       => :et_ITENS_NOVOS,
        cod_produto_saida => :et_COD_PRODUTO_SAIDA,
        relatorio_item    => :et_RELATORIO_ITEM
    );

  ENDMETHOD.

  METHOD call_mov_itens_novos BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::MOV_ITENS_NOVOS" (
        -- IN
        p_mandt                 => :iv_input_mandt,
        p_empresa               => :iv_input_empresa,
        p_filial                => :iv_input_filial,
        p_periodo_de            => :iv_input_periodo_de,
        p_periodo_ate           => :iv_input_periodo_ate,
        p_concatena             => :iv_input_concatena,
        p_direct                => :iv_input_direct,
        p_cod_produto           => :iv_input_cod_produto,
        p_ncm                   => :iv_input_ncm,
        p_meses_retorno         => :iv_input_meses_retorno,
        itens_novos             => :et_ITENS_NOVOS,
        cod_produto_saida       => :et_COD_PRODUTO_SAIDA,
        relatorio_item          => :et_RELATORIO_ITEM,
        -- OUT
        novo_itens_novos        => :et_ITENS_NOVOS,
        novo_cod_produto_saida  => :et_COD_PRODUTO_SAIDA,
        novo_relatorio_item     => :et_RELATORIO_ITEM
    );

  ENDMETHOD.

  METHOD origem_material BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::ORIGEM_MATERIAL" (
        -- IN
        p_mandt         => :iv_input_mandt,
        calculo         => :iv_calculo,
        -- OUT
        origem          => :et_origem
    );

  ENDMETHOD.


  METHOD retorna_itens BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::ITENS" (
        -- IN
        p_mandt         => :iv_input_mandt,
        p_cod_produto   => :iv_input_cod_produto,
        p_ncm           => :iv_input_ncm,
        -- OUT
        itens           => :et_out_item
    );

  ENDMETHOD.


  METHOD retorna_notas BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::NFS" (
        -- IN
        p_mandt         => :iv_input_mandt,
        p_empresa       => :iv_input_empresa,
        p_filial        => :iv_input_filial,
        p_periodo_de    => :iv_input_periodo_de,
        p_periodo_ate   => :iv_input_periodo_ate,
        p_concatena     => :iv_input_concatena,
        p_direct        => :iv_input_direct,
        p_item          => :iv_input_item,
        -- OUT
        retorno         => :et_out_retorno
    );

  ENDMETHOD.


  METHOD calculo_movimento_nota BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::MOVIMENTO_NOTA" (
        -- IN
        p_mandt         => :iv_input_mandt,
        p_empresa       => :iv_input_empresa,
        p_filial        => :iv_input_filial,
        p_periodo_de    => :iv_input_periodo_de,
        p_recalc        => :iv_input_recalcula,
        p_relatorio     => :iv_input_relatorio,
        -- OUT
        calculo         => :et_calculo,
        relatorio       => :et_relatorio
    );

  ENDMETHOD.


  METHOD gerar_arquivo BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT.

    CALL "engdb.dpfisc.app.db.fci.procedures::GERAR_ARQUIVO" (
        -- IN
        p_mandt                 => :iv_input_mandt,
        p_empresa               => :iv_input_empresa,
        p_filial                => :iv_input_filial,
        p_periodo_de            => :iv_input_periodo_de,
        p_concatena             => :iv_input_concatena,
        -- OUT
        registro_tabela_5020    => :et_registro_tabela_5020,
        arquivo                 => :et_arquivo,
        dados                   => :et_dados
    );

  ENDMETHOD.

ENDCLASS.