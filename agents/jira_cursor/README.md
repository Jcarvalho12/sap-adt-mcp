# jira_cursor

Agente que se conecta ao Atlassian Jira Cloud (https://engsmartdesk.atlassian.net), lê o histórico completo de um chamado — incluindo o **conteúdo dos anexos** (PDFs, imagens, documentos) — e gera um relatório de análise com os principais pontos e sugestões de onde pode estar o problema.

## O que o agente faz

1. **Conecta** ao Jira Cloud via API REST v3 com autenticação por API Token
2. **Coleta** todos os dados do chamado: descrição, comentários, transições de status, reatribuições, anexos, links e subtasks
3. **Analisa o conteúdo dos anexos**: faz download e extrai texto de PDFs (EFs, relatórios), imagens (OCR), documentos Word, planilhas Excel e arquivos de texto
4. **Analisa** o histórico identificando padrões (reaberturas, gaps de inatividade, escalações, discussões extensas)
5. **Extrai** pontos-chave dos comentários e dos anexos (menções a erros, dumps, timeouts, soluções parciais, requisitos de EF)
6. **Sugere** possíveis causas raiz baseadas nos dados coletados **e no conteúdo dos anexos**
7. **Recomenda** próximos passos para resolução com base em toda a evidência disponível

## Pré-requisitos

- Python 3.10+
- Bibliotecas: `requests`, `PyYAML`, `PyPDF2`, `python-docx`, `openpyxl`, `Pillow`, `pytesseract`
- Conta Atlassian com acesso ao Jira em https://engsmartdesk.atlassian.net
- API Token gerado em https://id.atlassian.com/manage-profile/security/api-tokens
- (Opcional) Tesseract OCR instalado para análise de imagens — [Download Windows](https://github.com/UB-Mannheim/tesseract/wiki)

## Configuração

### 1. Variáveis de ambiente (recomendado)

```powershell
$env:JIRA_EMAIL = "seu.email@empresa.com"
$env:JIRA_API_TOKEN = "seu-token-aqui"
```

### 2. Ou edite `config.yaml`

```yaml
jira:
  base_url: "https://engsmartdesk.atlassian.net"
  email: "seu.email@empresa.com"
  api_token: "seu-token-aqui"
```

> **Segurança**: Nunca faça commit de tokens. Prefira variáveis de ambiente.

## Como executar

### Modo interativo (pede o chamado via terminal)

```powershell
cd agents\jira_cursor
.\run_agent.ps1
```

Ou diretamente:

```powershell
python agent.py
```

### Análise direta de um chamado

```powershell
.\run_agent.ps1 -Issue "SD-456"
```

Ou:

```powershell
python agent.py --issue SD-456
```

### Saída em JSON (para integração com outros sistemas)

```powershell
python agent.py --issue SD-456 --json
```

### Análise em lote (múltiplos chamados)

```powershell
python agent.py --batch SD-100 SD-101 SD-102
```

## Estrutura do relatório gerado

O agente retorna um relatório Markdown contendo:

| Seção | Descrição |
|-------|-----------|
| Métricas | Dias aberto, comentários, transições, reaberturas, participantes |
| Padrões Identificados | Reaberturas, gaps, escalações, discussão excessiva |
| Pontos-Chave | Trechos relevantes de comentários e anexos (erros, soluções, decisões, requisitos) |
| Possíveis Causas | Sugestões baseadas no histórico **e conteúdo dos anexos** |
| Próximos Passos | Ações recomendadas para resolução |
| Issues Relacionadas | Links com outros chamados |
| **Análise de Anexos** | **Descobertas nos PDFs, imagens e documentos anexados** |
| **Conteúdo Extraído** | **Trechos relevantes do texto extraído dos anexos** |
| Cronologia | Últimos 20 eventos em ordem temporal |

## Análise de Anexos

O agente faz download automático dos anexos e extrai conteúdo textual:

| Formato | Suporte | Biblioteca |
|---------|---------|------------|
| PDF | Texto completo de todas as páginas | PyPDF2 / pdfplumber |
| DOCX | Parágrafos e tabelas | python-docx |
| XLSX | Dados de todas as abas | openpyxl |
| Imagens (PNG, JPG, etc.) | OCR — extrai texto de screenshots | pytesseract + Pillow |
| Texto (TXT, LOG, CSV, XML, JSON) | Leitura direta | built-in |

O conteúdo extraído é usado para:
- Identificar mensagens de erro em dumps e screenshots
- Ler requisitos e regras de negócio em EFs (Especificações Funcionais)
- Detectar referências SAP (transações, function modules, notas)
- Enriquecer as sugestões de causa raiz com evidências dos anexos

### Configuração

No `config.yaml`:

```yaml
analysis:
  analyze_attachment_content: true   # habilitar/desabilitar
  max_attachments_to_analyze: 20     # máximo de anexos por issue
  max_attachment_text: 200000        # limite total de texto (chars)
```

### Instalando Tesseract OCR (para imagens)

**Windows:**
1. Baixe o instalador em https://github.com/UB-Mannheim/tesseract/wiki
2. Instale e adicione ao PATH (ex: `C:\Program Files\Tesseract-OCR`)
3. O agente detecta automaticamente se Tesseract está disponível

Sem Tesseract, PDFs e documentos ainda são analisados normalmente. Apenas imagens terão análise limitada.

## Arquivos

| Arquivo | Função |
|---------|--------|
| `agent.py` | CLI principal — modos interativo, single e batch |
| `jira_client.py` | Cliente REST para API v3 do Jira Cloud |
| `analyzer.py` | Motor de análise: timeline, padrões, causa raiz |
| `attachment_analyzer.py` | Download e extração de conteúdo de anexos (PDF, DOCX, imagens, etc.) |
| `prompts.py` | Templates de formatação do relatório |
| `config.yaml` | Configuração de conexão e parâmetros de análise |
| `requirements.txt` | Dependências Python |
| `run_agent.ps1` | Script PowerShell para execução rápida |

## Exemplo de saída

```
# 📋 Análise do Chamado SD-456

**Resumo:** Sistema apresenta timeout ao gerar relatório fiscal
**Tipo:** Bug | **Status:** In Progress | **Prioridade:** High

## 📊 Métricas

| Métrica | Valor |
|---------|-------|
| Dias aberto | 15 |
| Comentários | 12 |
| Transições | 8 |
| Reaberturas | 1 |

## 🔍 Padrões Identificados

- 🔄 Chamado reaberto 1x — indica resolução incompleta
- ⏳ Maior gap de inatividade: 5 dias

## 🎯 Possíveis Causas / Onde Investigar

1. Possível problema de performance/timeout — verificar queries, locks de banco...

## ✅ Próximos Passos Sugeridos

1. Coletar traces/logs de performance no momento da ocorrência
2. Documentar o cenário de reprodução com dados de teste
```

## Gerar API Token do Jira

1. Acesse https://id.atlassian.com/manage-profile/security/api-tokens
2. Clique em "Create API token"
3. Dê um nome descritivo (ex: "jira_cursor agent")
4. Copie o token gerado e defina em `JIRA_API_TOKEN`
