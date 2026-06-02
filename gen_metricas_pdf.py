"""Generate PDF report: Métricas IA vs Desenvolvedor Sênior — ZTAX_FCI_CONV_UM"""

from fpdf import FPDF
import os

OUTPUT = os.path.join(os.path.expanduser("~"), "Downloads",
                      "Metricas_IA_vs_Dev_Senior_ZTAX_FCI_CONV_UM.pdf")

FONTS_DIR = os.path.join(os.environ.get("WINDIR", r"C:\Windows"), "Fonts")


class PDF(FPDF):
    def _register_fonts(self):
        self.add_font("Arial", "",  os.path.join(FONTS_DIR, "arial.ttf"))
        self.add_font("Arial", "B", os.path.join(FONTS_DIR, "arialbd.ttf"))
        self.add_font("Arial", "I", os.path.join(FONTS_DIR, "ariali.ttf"))
        self.add_font("Arial", "BI", os.path.join(FONTS_DIR, "arialbi.ttf"))

    def header(self):
        self.set_font("Arial", "B", 9)
        self.set_text_color(120, 120, 120)
        self.cell(0, 5,
                  "Métricas IA vs Desenvolvedor Sênior — ZTAX_FCI_CONV_UM",
                  align="R", new_x="LMARGIN", new_y="NEXT")
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(3)

    def footer(self):
        self.set_y(-15)
        self.set_font("Arial", "I", 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f"Página {self.page_no()}/{{nb}}", align="C")

    def section_title(self, num, title):
        self.ln(4)
        self.set_font("Arial", "B", 13)
        self.set_text_color(0, 70, 130)
        self.cell(0, 8, f"{num}. {title}",
                  new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(0, 70, 130)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(3)
        self.set_text_color(0, 0, 0)

    def sub_title(self, title):
        self.ln(2)
        self.set_font("Arial", "B", 11)
        self.set_text_color(50, 50, 50)
        self.cell(0, 7, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)
        self.set_text_color(0, 0, 0)

    def body(self, txt):
        self.set_font("Arial", "", 9)
        self.multi_cell(0, 4.5, txt)
        self.ln(1)

    def note(self, txt):
        self.set_font("Arial", "I", 8)
        self.set_text_color(80, 80, 80)
        self.multi_cell(0, 4, txt)
        self.set_text_color(0, 0, 0)
        self.ln(1)

    def bold_text(self, txt):
        self.set_font("Arial", "B", 9)
        self.multi_cell(0, 4.5, txt)
        self.set_font("Arial", "", 9)
        self.ln(1)

    def bullet_list(self, items):
        self.set_font("Arial", "", 8.5)
        for item in items:
            x = self.get_x()
            self.cell(3, 4.5, "")
            self.cell(0, 4.5, "- " + item, new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def table(self, headers, rows, col_widths=None, highlight_last=False):
        if col_widths is None:
            n = len(headers)
            col_widths = [190 / n] * n

        self.set_font("Arial", "B", 8)
        self.set_fill_color(0, 70, 130)
        self.set_text_color(255, 255, 255)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 6, h, border=1, fill=True, align="C")
        self.ln()

        self.set_font("Arial", "", 8)
        self.set_text_color(0, 0, 0)
        for ri, row in enumerate(rows):
            is_last = ri == len(rows) - 1
            if is_last and highlight_last:
                self.set_font("Arial", "B", 8)
                self.set_fill_color(230, 240, 250)
            elif ri % 2 == 1:
                self.set_fill_color(245, 245, 245)
            else:
                self.set_fill_color(255, 255, 255)

            for i, c in enumerate(row):
                self.cell(col_widths[i], 6, str(c), border=1,
                          fill=True, align="C" if i > 0 else "L")
            self.ln()
            if is_last and highlight_last:
                self.set_font("Arial", "", 8)
        self.ln(2)


def build():
    pdf = PDF(orientation="P", unit="mm", format="A4")
    pdf._register_fonts()
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.add_page()

    # ================================================================
    # COVER
    # ================================================================
    pdf.ln(25)
    pdf.set_font("Arial", "B", 22)
    pdf.set_text_color(0, 70, 130)
    pdf.cell(0, 12, "Métricas: IA vs Desenvolvedor Sênior", align="C",
             new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Arial", "B", 16)
    pdf.cell(0, 10, "Report ZTAX_FCI_CONV_UM", align="C",
             new_x="LMARGIN", new_y="NEXT")
    pdf.ln(5)
    pdf.set_font("Arial", "", 11)
    pdf.set_text_color(60, 60, 60)
    pdf.cell(0, 7, "Pré-processamento FCI — Conversão de Unidade de Medida",
             align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(10)

    info = [
        ("Projeto", "FCI — Pré-processamento Conversão Unidade de Medida"),
        ("Sistema", "TDD (manaus.group.pirelli.com:8001, client 210)"),
        ("EF", "EF-TAX-TDF v1.0 — 07/04/2026 — Laura Prado (9 páginas)"),
        ("Data da análise", "24/04/2026"),
        ("Ferramenta IA", "Cursor IDE + MCP SAP ADT (Claude)"),
        ("Request", "TDDK901617"),
        ("Pacote", "ZTAX_FCI_CONV"),
    ]
    pdf.set_font("Arial", "", 10)
    for label, val in info:
        pdf.set_font("Arial", "B", 10)
        pdf.set_text_color(0, 0, 0)
        pdf.cell(45, 6, label + ":", align="R")
        pdf.set_font("Arial", "", 10)
        pdf.set_text_color(60, 60, 60)
        pdf.cell(0, 6, "  " + val, new_x="LMARGIN", new_y="NEXT")
    pdf.set_text_color(0, 0, 0)

    # ================================================================
    # SECTION 1 — Inventário
    # ================================================================
    pdf.add_page()
    pdf.section_title("1", "Inventário do Objeto")
    pdf.table(
        ["Métrica", "Valor"],
        [
            ["Tipo", "Report ABAP (PROG)"],
            ["LOC (linhas de código)", "~680"],
            ["FORMs (sub-rotinas)", "14"],
            ["Queries HANA nativas (cl_sql_statement)", "8"],
            ["Views HANA consumidas", "6"],
            ["Tabelas SAP acessadas", "1 (STPO)"],
            ["Tabelas Z gravadas", "2"],
            ["CALL FUNCTION", "3"],
            ["IFs / CHECKs", "~25"],
            ["LOOPs", "~20"],
            ["TRY/CATCHs", "8"],
            ["Algoritmo recursivo (BOM)", "1 (até 20 níveis)"],
            ["Saída ALV (cl_salv_table)", "1"],
        ],
        col_widths=[100, 90],
    )
    pdf.bold_text(
        "Complexidade geral: ALTA — SQL HANA nativo, explosão recursiva de BOM "
        "multinível, lógica de conversão de unidades e gravação em múltiplas tabelas."
    )

    # ================================================================
    # SECTION 2 — Complexidade por Sub-rotina
    # ================================================================
    pdf.section_title("2", "Análise de Complexidade por Sub-rotina")
    cw2 = [8, 55, 15, 17, 14, 16, 13, 24, 28]
    pdf.table(
        ["#", "FORM", "LOC", "SQL", "IFs", "LOOPs", "TRY", "Compl.", "Detalhe"],
        [
            ["1", "f_montar_periodo", "~25", "0", "2", "0", "0", "Baixa", "Cálc. mês-2"],
            ["2", "f_buscar_cfop_saida", "~25", "1", "0", "0", "1", "Baixa", "Query HANA"],
            ["3", "f_buscar_cfop_entrada", "~25", "1", "0", "0", "1", "Baixa", "Query HANA"],
            ["4", "f_buscar_produtos_saida", "~65", "1", "3", "2", "1", "Média", "JOIN + filtros"],
            ["5", "f_buscar_produtos_entrada", "~55", "1", "2", "1", "1", "Média", "JOIN + filtros"],
            ["6", "f_buscar_consumo_especif.", "~50", "1", "1", "1", "1", "Média", "IN-list pares"],
            ["7", "f_explodir_bom", "~90", "1", "4", "5", "1", "ALTA", "Recursivo 20n"],
            ["8", "f_filtrar_por_notas_entr.", "~30", "0", "2", "2", "0", "Baixa", "Hash filter"],
            ["9", "f_filtrar_por_mtorg_imp.", "~60", "1", "2", "3", "1", "Média", "MBEW import."],
            ["10", "f_buscar_unid_item", "~45", "1", "1", "2", "1", "Média", "Lookup ITEM"],
            ["11", "f_buscar_meins_stpo", "~50", "1", "1", "2", "1", "Média", "Lookup STPO"],
            ["12", "f_processar_conversao", "~85", "0", "6", "1", "0", "ALTA", "G/KG + FM"],
            ["13", "f_verificar_conv_ant.", "~40", "0", "2", "2", "0", "Média", "ZENG_PRE_FCI"],
            ["14", "f_gravar_shadow", "~35", "0", "2", "1", "0", "Baixa", "MODIFY shadow"],
            ["15", "f_gravar_controle", "~35", "0", "2", "1", "0", "Baixa", "MODIFY ctrl"],
            ["16", "f_exibir_alv", "~60", "0", "0", "0", "1", "Média", "cl_salv_table"],
        ],
        col_widths=cw2,
    )
    pdf.body("Distribuição: 2 Alta | 8 Média | 6 Baixa")

    # ================================================================
    # SECTION 3 — Lacunas da EF
    # ================================================================
    pdf.add_page()
    pdf.section_title("3", "Lacunas da EF — Procedimentos Não Previstos")
    pdf.body(
        "A EF (9 páginas) cobre apenas o núcleo da regra de conversão: comparar "
        "STPO.MEINS vs ITEM.UNID_INV, converter G/KG dividindo ou multiplicando "
        "por 1000, e gravar na shadow /TMF/D_CONS_ESPC. Porém, durante o "
        "desenvolvimento, o desenvolvedor sênior precisou debugar o fluxo FCI "
        "existente (/TAX/CL_CALCULO_FCI) e descobrir diversos procedimentos "
        "adicionais necessários para que o report funcionasse corretamente no "
        "cenário real. Esses procedimentos NÃO constam na EF e exigiram "
        "análise, engenharia reversa e decisões técnicas do desenvolvedor."
    )

    pdf.sub_title("Procedimentos descobertos durante o desenvolvimento")
    pdf.table(
        ["#", "Procedimento não previsto na EF", "Impacto"],
        [
            ["1", "Filtragem CFOP saída/entrada (CV_FCI_CES)", "2 queries + lógica DIRECT"],
            ["2", "Busca produtos c/ NF no período (JOINs NF_ITEM/DOC)", "2 queries complexas (~120 LOC)"],
            ["3", "Explosão BOM multinível (até 20 níveis)", "Algoritmo recursivo (~90 LOC)"],
            ["4", "Proteção contra referências circulares na BOM", "Tabela hash de visitados"],
            ["5", "Filtro MTORG importado (CV_MBEW IN 1,2,3,8)", "Query + filtro hash (~60 LOC)"],
            ["6", "Filtro por notas de entrada no período", "Query + filtro hash (~30 LOC)"],
            ["7", "Verificação conversão anterior (ZENG_PRE_FCI)", "SELECT FAE + ícone vermelho"],
            ["8", "Tabela de controle ZENG_PRE_FCI", "Gravação + lógica anti-regravação"],
            ["9", "Modo Simulação vs Execução c/ popup", "Radio buttons + confirmação"],
            ["10", "Fallback UNIT_CONVERSION_SIMPLE (outras UMs)", "CALL FUNCTION genérico"],
            ["11", "Filtros NF canceladas/tipos específicos NF", "WHERE NOT IN (NFS,E2,J2...)"],
            ["12", "Select-Options COD_ITEM e COD_ITEM_COMP", "Parâmetros de tela adicionais"],
        ],
        col_widths=[8, 105, 77],
    )
    pdf.note(
        "Estimativa: ~50% do código final (aproximadamente 340 LOC de ~680 total) "
        "implementa procedimentos que não estavam previstos na EF original. "
        "O desenvolvedor sênior precisou debugar o fluxo FCI existente, entender "
        "a cadeia de dependências e propor as melhorias junto com a IA."
    )

    # ================================================================
    # SECTION 4 — Estimativa Dev Sênior (com Fase Extra)
    # ================================================================
    pdf.add_page()
    pdf.section_title("4", "Estimativa — Desenvolvedor ABAP Sênior (Humano)")

    pdf.body(
        "Premissas: Desenvolvedor ABAP sênior (5+ anos), experiência em HANA "
        "native SQL, familiaridade moderada com FCI/SmartTax. Produtividade: "
        "30-40 LOC/hora. Inclui análise da EF, estudo do sistema, codificação, "
        "debugging de procedimentos não previstos, testes e transporte."
    )

    pdf.sub_title("Fase 1 — Entendimento da EF e sistema existente")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Leitura e interpretação da EF (9 páginas)", "1,5h", "Regras de negócio implícitas"],
            ["Entendimento do problema (FCI > 100%)", "0,5h", "Análise do cenário da EF"],
            ["Estudo do fluxo FCI (/TAX/CL_CALCULO_FCI)", "3,0h", "Replicar lógica de período/filtros"],
            ["Estudo modelo de dados HANA (6 views)", "3,0h", "Views HANA não-standard"],
            ["Esclarecimentos com equipe funcional", "1,0h", "Cenários G->KG, outras UMs"],
            ["Subtotal Fase 1", "9,0h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase 2 — Design técnico")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Design do pipeline (14 etapas)", "2,0h", "Ordem: saída->consumo->BOM->entrada->conv."],
            ["Design queries HANA native SQL", "2,0h", "8 queries com JOINs e filtros dinâmicos"],
            ["Design explosão BOM recursiva", "2,0h", "20 níveis, proteção circular"],
            ["Design ALV + modos simulação/execução", "1,0h", "Ícones, popup, gravação condicional"],
            ["Subtotal Fase 2", "7,0h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase 3 — Codificação (~680 LOC)")
    pdf.table(
        ["Componente", "LOC", "Horas", "Justificativa"],
        [
            ["Tipos, dados globais, tela de seleção", "~75", "2,0h", "7 tipos + selection-screen"],
            ["START-OF-SELECTION + popup", "~30", "1,0h", "Pipeline + confirmação"],
            ["f_montar_periodo", "~25", "1,0h", "Mês-2 com virada de ano"],
            ["f_buscar_cfop_saida/entrada", "~50", "1,5h", "2 queries HANA simples"],
            ["f_buscar_produtos_saida/entrada", "~120", "4,0h", "Queries complexas com JOINs"],
            ["f_buscar_consumo_especifico", "~50", "2,0h", "IN-list pares (COD_ITEM,CENTRO)"],
            ["f_explodir_bom", "~90", "5,0h", "Recursivo 20 níveis + hash visitados"],
            ["f_filtrar (entrada + MTORG)", "~90", "2,5h", "Filtros com tabela hash"],
            ["f_buscar_unid_item/meins_stpo", "~95", "2,0h", "2 queries de lookup"],
            ["f_processar_conversao", "~85", "3,0h", "CASE G/KG + FM fallback"],
            ["f_verificar_conversao_anterior", "~40", "1,5h", "SELECT FAE + BINARY SEARCH"],
            ["f_gravar_shadow/controle", "~70", "2,0h", "MODIFY + COMMIT/ROLLBACK"],
            ["f_exibir_alv", "~60", "2,0h", "cl_salv_table + 15 colunas"],
            ["Subtotal Fase 3", "~680", "29,5h", ""],
        ],
        col_widths=[65, 15, 15, 95],
        highlight_last=True,
    )

    pdf.sub_title("Fase 4 — Testes e depuração")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Testes unitários (modo simulação)", "3,0h", "Validar cada etapa do pipeline"],
            ["Testes de integração (modo execução)", "4,0h", "Gravar shadow + ZENG_PRE_FCI"],
            ["Depuração e correção de bugs", "3,5h", "Debug, ajuste queries, edge cases"],
            ["Teste de re-execução", "1,0h", "Ícone vermelho impede regravação"],
            ["Subtotal Fase 4", "11,5h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase EXTRA — Debugging e melhorias não previstas na EF")
    pdf.body(
        "Durante o desenvolvimento, o desenvolvedor sênior precisou debugar o "
        "fluxo FCI existente e realizar engenharia reversa para descobrir "
        "procedimentos que a EF não documentava. Após entender cada procedimento, "
        "precisou implementar as melhorias e testar os cenários adicionais."
    )
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Debug/engenharia reversa do FCI existente", "5,0h", "Rastrear fluxo real no SAP via SE80/debug"],
            ["Descobrir filtros não previstos na EF", "4,0h", "CFOP, NF período, BOM, MTORG, ZENG_PRE_FCI"],
            ["Implementar melhorias além da EF", "6,0h", "Simulação/execução, popup, BOM circular, FM"],
            ["Testes adicionais das melhorias", "3,0h", "Testar cenários não cobertos pela EF"],
            ["Subtotal Fase Extra", "18,0h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase 5 — Finalização")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Transporte (TDDK901617)", "0,5h", "Associar objetos e liberar"],
            ["Code review / preparação", "1,0h", "Auto-revisão"],
            ["Documentação técnica", "0,5h", "Complementar a EF"],
            ["Subtotal Fase 5", "2,0h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    # Senior: 9 + 7 + 29.5 + 11.5 + 18 + 2 = 77h
    pdf.sub_title("Resumo — Desenvolvedor Sênior")
    pdf.table(
        ["Fase", "Horas", "%"],
        [
            ["1. Entendimento da EF e sistema", "9,0h", "12%"],
            ["2. Design técnico", "7,0h", "9%"],
            ["3. Codificação", "29,5h", "38%"],
            ["4. Testes e depuração", "11,5h", "15%"],
            ["EXTRA. Debugging + melhorias não previstas", "18,0h", "23%"],
            ["5. Finalização", "2,0h", "3%"],
            ["Total Desenvolvedor Sênior", "77,0h", "100%"],
        ],
        col_widths=[85, 55, 50],
        highlight_last=True,
    )
    pdf.note("77 horas = 9,6 dias úteis = ~1,9 semanas (8h/dia)")

    # ================================================================
    # SECTION 5 — Estimativa IA (com Fase Extra)
    # ================================================================
    pdf.add_page()
    pdf.section_title("5", "Estimativa — IA (Cursor + MCP SAP ADT)")

    pdf.body(
        "Premissas: IA recebe EF (PDF) como contexto. Deploy direto via MCP. "
        "IA lê código existente via sap_read_source. Produtividade: ~150-250 LOC/hora. "
        "O desenvolvedor sênior ainda é necessário para debugar procedimentos "
        "não previstos na EF, mas a IA acelera a implementação das melhorias."
    )

    pdf.sub_title("Fase 1 — Entendimento da EF e sistema")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["IA lê e interpreta a EF (PDF)", "0,1h", "9 páginas em segundos"],
            ["IA lê código FCI existente via MCP", "0,3h", "Leitura automatizada"],
            ["IA analisa modelo de dados HANA", "0,3h", "Pesquisa automatizada"],
            ["Humano valida entendimento da IA", "0,8h", "Revisão e alinhamento"],
            ["Subtotal Fase 1", "1,5h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase 2 — Design técnico")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["IA propõe pipeline completo", "0,2h", "Geração instantânea"],
            ["Humano revisa e ajusta", "0,5h", "Validação de decisões"],
            ["Subtotal Fase 2", "0,7h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase 3 — Codificação (~680 LOC)")
    pdf.table(
        ["Componente", "Horas", "Justificativa"],
        [
            ["Geração completa do report (1a iteração)", "1,5h", "Report inteiro a partir da EF"],
            ["Revisão humana + solicitação de ajustes", "1,0h", "Leitura e identificação de ajustes"],
            ["IA aplica correções (2a-3a iteração)", "0,8h", "Queries HANA, BOM, filtros"],
            ["Deploy via MCP (write + activate)", "0,2h", "Automatizado"],
            ["Subtotal Fase 3", "3,5h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase 4 — Testes e depuração")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Teste modo simulação (humano)", "2,5h", "Execução real no SAP"],
            ["IA corrige bugs encontrados", "1,0h", "Lê log, ajusta, redeploy via MCP"],
            ["Teste integração (modo execução)", "1,5h", "Shadow + ZENG_PRE_FCI"],
            ["Teste re-execução", "0,5h", "Proteção contra regravação"],
            ["Subtotal Fase 4", "5,5h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase EXTRA — Debugging e melhorias não previstas na EF")
    pdf.body(
        "O desenvolvedor sênior ainda precisa debugar o fluxo FCI existente no "
        "SAP e realizar engenharia reversa — esta é uma atividade humana "
        "insubstituível. Porém, após descobrir os requisitos faltantes, a "
        "comunicação com a IA e a implementação conjunta são significativamente "
        "mais rápidas do que codificar sozinho."
    )
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Dev sênior debugar fluxo FCI no SAP", "5,0h", "Trabalho humano puro (SE80/debugger)"],
            ["Dev comunicar requisitos descobertos à IA", "1,5h", "Descrever filtros, BOM, MTORG etc."],
            ["IA implementar melhorias c/ supervisão", "2,0h", "IA gera código, dev valida lógica"],
            ["Testes adicionais (humano + IA)", "2,0h", "Dev testa cenários, IA corrige via MCP"],
            ["Subtotal Fase Extra", "10,5h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    pdf.sub_title("Fase 5 — Finalização")
    pdf.table(
        ["Atividade", "Horas", "Justificativa"],
        [
            ["Transporte + documentação (IA-assistida)", "0,3h", "Via MCP"],
            ["Subtotal Fase 5", "0,3h", ""],
        ],
        col_widths=[85, 15, 90],
        highlight_last=True,
    )

    # IA: 1.5 + 0.7 + 3.5 + 5.5 + 10.5 + 0.3 = 22.0h
    pdf.sub_title("Resumo — IA + Revisão Humana")
    pdf.table(
        ["Fase", "Horas", "%"],
        [
            ["1. Entendimento da EF e sistema", "1,5h", "7%"],
            ["2. Design técnico", "0,7h", "3%"],
            ["3. Codificação", "3,5h", "16%"],
            ["4. Testes e depuração", "5,5h", "25%"],
            ["EXTRA. Debugging + melhorias não previstas", "10,5h", "48%"],
            ["5. Finalização", "0,3h", "1%"],
            ["Total IA + Revisão Humana", "22,0h", "100%"],
        ],
        col_widths=[85, 55, 50],
        highlight_last=True,
    )
    pdf.note("22 horas = 2,75 dias úteis (8h/dia)")

    # ================================================================
    # SECTION 6 — Comparativo Consolidado
    # ================================================================
    pdf.add_page()
    pdf.section_title("6", "Comparativo Consolidado")

    pdf.sub_title("6.1 Comparativo por Fase")
    # Senior: 77h, IA: 22h, economy: 55h, 71%
    pdf.table(
        ["Fase", "Dev Sênior", "IA + Revisão", "Economia (h)", "Economia %"],
        [
            ["Entendimento da EF", "9,0h", "1,5h", "7,5h", "83%"],
            ["Design técnico", "7,0h", "0,7h", "6,3h", "90%"],
            ["Codificação", "29,5h", "3,5h", "26,0h", "88%"],
            ["Testes e depuração", "11,5h", "5,5h", "6,0h", "52%"],
            ["EXTRA: Debug + melhorias", "18,0h", "10,5h", "7,5h", "42%"],
            ["Finalização", "2,0h", "0,3h", "1,7h", "85%"],
            ["TOTAL", "77,0h", "22,0h", "55,0h", "71%"],
        ],
        col_widths=[50, 28, 28, 34, 30],
        highlight_last=True,
    )

    pdf.sub_title("6.2 Impacto da Fase Extra nos Totais")
    pdf.table(
        ["Cenário", "Dev Sênior", "IA + Revisão", "Economia %"],
        [
            ["Sem fase extra (só EF)", "59,0h", "11,5h", "81%"],
            ["Com fase extra (cenário real)", "77,0h", "22,0h", "71%"],
            ["Diferença adicionada", "+18,0h", "+10,5h", "-10 p.p."],
        ],
        col_widths=[55, 40, 40, 40],
        highlight_last=True,
    )
    pdf.note(
        "A fase extra reduz a economia de 81% para 71%, pois o debugging e "
        "engenharia reversa no SAP é trabalho essencialmente humano. Mesmo com "
        "a IA, o desenvolvedor sênior gasta 5h debugando — a mesma quantidade "
        "que gastaria sozinho. A economia na fase extra vem da implementação: "
        "a IA codifica as melhorias 3x mais rápido (2h vs 6h do dev sozinho)."
    )


    # ================================================================
    # SECTION 7 — Análise da Fase Extra
    # ================================================================
    pdf.section_title("7", "Análise da Fase Extra — Debug e Melhorias")

    pdf.sub_title("7.1 O que muda com a fase extra")
    pdf.body(
        "A inclusão da fase extra reflete o cenário real de desenvolvimento: "
        "a EF raramente cobre 100% dos requisitos. O desenvolvedor sênior "
        "precisou atuar em três frentes durante esta fase:"
    )
    pdf.bullet_list([
        "Debugging: rastrear o fluxo FCI existente via SE80/debugger para entender lógicas não documentadas",
        "Engenharia reversa: descobrir filtros, validações e dependências que a EF não mencionava",
        "Implementação conjunta com IA: após entender os requisitos, orientar a IA para codificar as melhorias",
    ])

    pdf.sub_title("7.2 Onde a IA NÃO economiza na fase extra")
    pdf.table(
        ["Atividade", "Dev sozinho", "Dev + IA", "Economia"],
        [
            ["Debugging no SAP (SE80/debugger)", "5,0h", "5,0h", "0% (humano puro)"],
            ["Descoberta de requisitos faltantes", "4,0h", "1,5h", "63% (IA lê código)"],
        ],
        col_widths=[60, 35, 35, 60],
    )
    pdf.note(
        "O debugging no SAP é o gargalo: a IA não tem acesso ao debugger "
        "interativo (breakpoints, variáveis em runtime). O desenvolvedor precisa "
        "executar o FCI no SAP, parar em breakpoints e rastrear o fluxo real."
    )

    pdf.sub_title("7.3 Onde a IA ECONOMIZA na fase extra")
    pdf.table(
        ["Atividade", "Dev sozinho", "Dev + IA", "Economia"],
        [
            ["Implementar melhorias (código)", "6,0h", "2,0h", "67% (IA gera código)"],
            ["Testes das melhorias", "3,0h", "2,0h", "33% (IA corrige rápido)"],
        ],
        col_widths=[60, 35, 35, 60],
    )
    pdf.note(
        "Após o desenvolvedor entender o que precisa ser feito, comunicar para "
        "a IA é rápido (1,5h). A IA então implementa as ~340 LOC de melhorias "
        "em ~2h, enquanto o desenvolvedor sozinho levaria ~6h."
    )

    # ================================================================
    # SECTION 8 — Onde a IA Mais Economizou
    # ================================================================
    pdf.add_page()
    pdf.section_title("8", "Onde a IA Mais Economizou")
    pdf.table(
        ["Tipo de tarefa", "Economia", "Justificativa"],
        [
            ["Leitura/interpretação da EF (PDF)", "95%", "IA processa 9 páginas em segundos"],
            ["Estudo do código existente (FCI)", "90%", "IA lê via MCP instantaneamente"],
            ["Queries HANA native SQL", "85%", "Padrão cl_sql_statement bem conhecido"],
            ["Explosão BOM recursiva", "80%", "Algoritmo recursivo + proteção circular"],
            ["Lógica de conversão G/KG", "90%", "Regra explícita na EF"],
            ["ALV com cl_salv_table", "85%", "Padrão extremamente repetitivo"],
            ["Deploy no SAP", "90%", "MCP elimina Eclipse/SAP GUI"],
            ["Implementar melhorias (pós-debug)", "67%", "IA codifica 3x mais rápido após orientação"],
            ["Debugging no SAP (SE80/debugger)", "0%", "Trabalho humano puro - IA não substitui"],
            ["Testes com dados reais", "52%", "Humano executa e valida no SAP"],
        ],
        col_widths=[68, 22, 100],
    )

    # ================================================================
    # SECTION 9 — Onde o Humano é Insubstituível
    # ================================================================
    pdf.section_title("9", "Onde o Humano é Insubstituível")
    pdf.table(
        ["Dimensão", "Justificativa"],
        [
            ["Debugging no SAP (SE80/debugger)", "Breakpoints, variáveis em runtime, fluxo real"],
            ["Engenharia reversa de fluxos complexos", "Entender dependências não documentadas"],
            ["Validação funcional com dados reais", "Executar no SAP e confirmar FCI correto"],
            ["Domínio fiscal (FCI, CFOP, MTORG)", "IA implementa a regra, humano valida cenário"],
            ["Decisões de escopo (G/KG vs todas UMs)", "Humano decide se fallback era necessário"],
            ["Testes de regressão", "Garantir que conversão não quebra o FCI existente"],
        ],
        col_widths=[70, 120],
    )

    # ================================================================
    # SECTION 10 — Conclusão
    # ================================================================
    pdf.add_page()
    pdf.section_title("10", "Conclusão")

    pdf.table(
        ["Indicador", "Valor"],
        [
            ["Ganho de produtividade com IA", "71% (55 horas economizadas)"],
            ["Fator de aceleração", "3,5x mais rápido"],
            ["Maior ganho (fases previstas na EF)", "Entendimento + codificação (83-90%)"],
            ["Fase extra (não prevista na EF)", "+18h dev / +10,5h IA (42% economia)"],
            ["Gargalo principal", "Debugging no SAP (0% economia com IA)"],
            ["ROI deste projeto", "R$ 10.850 / R$ 150 = 72x"],
        ],
        col_widths=[70, 120],
    )

    pdf.ln(3)
    pdf.body(
        "Com a inclusão da fase extra de debugging e melhorias não previstas na EF, "
        "a economia cai de 81% para 71% — uma redução de 10 pontos percentuais. "
        "Isso reflete o cenário real: EFs raramente cobrem 100% dos requisitos, e "
        "o desenvolvedor sênior precisa investir tempo significativo em debugging "
        "e engenharia reversa no SAP."
    )

    pdf.ln(1)
    pdf.body(
        "Mesmo assim, a economia de 71% (55 horas / ~6,85 dias úteis por projeto) "
        "permanece muito expressiva. O principal insight é que a IA economiza "
        "massivamente nas fases de entendimento, design e codificação (83-90%), "
        "mas tem impacto limitado no debugging interativo no SAP (0%). A fase "
        "extra representa 23% do tempo total do dev sênior — e 48% do tempo com IA — "
        "tornando-se o principal gargalo quando se usa IA."
    )

    pdf.ln(1)
    pdf.body(
        "O modelo ideal de trabalho é: desenvolvedor sênior faz o debugging e "
        "engenharia reversa, depois comunica os requisitos descobertos para a IA, "
        "que implementa as melhorias rapidamente. Esse fluxo colaborativo "
        "\"humano descobre + IA implementa\" é o que viabiliza a economia de "
        "67% na implementação de melhorias dentro da fase extra."
    )

    pdf.ln(3)
    pdf.note(
        "Nota metodológica: As estimativas do desenvolvedor sênior baseiam-se em "
        "produtividade de 30-40 LOC/h para ABAP com HANA native SQL (benchmark "
        "ISBSG/SAP Community). A fase extra foi estimada com base na experiência "
        "real do desenvolvimento deste report, onde o desenvolvedor precisou "
        "debugar o fluxo /TAX/CL_CALCULO_FCI para descobrir 12 procedimentos "
        "não documentados na EF. As estimativas da IA baseiam-se na experiência "
        "prática via Cursor IDE + MCP SAP ADT."
    )

    # ---- Save ----
    pdf.output(OUTPUT)
    print(f"PDF gerado com sucesso: {OUTPUT}")


if __name__ == "__main__":
    build()
