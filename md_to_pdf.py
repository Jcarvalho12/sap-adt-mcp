import markdown2
import subprocess
import os
import sys
import tempfile

MD_PATH  = r"c:\Users\Jhon Carvalho\Documents\ENGDB\Cursor-MCP\Metricas_IA_vs_Dev_Senior_ZTAX_FCI_CONV_UM_v2.md"
PDF_PATH = r"c:\Users\Jhon Carvalho\Documents\ENGDB\Cursor-MCP\Metricas_IA_vs_Dev_Senior_ZTAX_FCI_CONV_UM_v2.pdf"

CSS = """
@page {
    size: A4;
    margin: 20mm 18mm 20mm 18mm;
    @bottom-center { content: "Página " counter(page) " / " counter(pages); font-size: 9px; color: #666; }
}
body {
    font-family: 'Segoe UI', Calibri, Arial, sans-serif;
    font-size: 11px;
    line-height: 1.5;
    color: #1a1a1a;
}
h1 { font-size: 20px; color: #003366; border-bottom: 3px solid #003366; padding-bottom: 6px; margin-top: 0; }
h2 { font-size: 16px; color: #003366; border-bottom: 1px solid #ccc; padding-bottom: 4px; margin-top: 22px; }
h3 { font-size: 13px; color: #005599; margin-top: 16px; }
table { border-collapse: collapse; width: 100%; margin: 10px 0 16px 0; font-size: 10.5px; }
th { background: #003366; color: #fff; padding: 6px 8px; text-align: left; font-weight: 600; }
td { padding: 5px 8px; border-bottom: 1px solid #ddd; }
tr:nth-child(even) td { background: #f4f7fb; }
strong { color: #003366; }
blockquote { border-left: 4px solid #003366; margin: 12px 0; padding: 8px 14px; background: #f0f4fa; font-size: 10.5px; }
hr { border: none; border-top: 2px solid #003366; margin: 24px 0; }
code { background: #eef; padding: 1px 4px; border-radius: 3px; font-size: 10px; }
"""

with open(MD_PATH, encoding="utf-8") as f:
    md_text = f.read()

html_body = markdown2.markdown(md_text, extras=["tables", "fenced-code-blocks", "cuddled-lists"])

full_html = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"><style>{CSS}</style></head>
<body>{html_body}</body>
</html>"""

try:
    from weasyprint import HTML
    HTML(string=full_html).write_pdf(PDF_PATH)
    print(f"PDF gerado com weasyprint: {PDF_PATH}")
    sys.exit(0)
except ImportError:
    pass

html_tmp = os.path.join(tempfile.gettempdir(), "metricas_v2.html")
with open(html_tmp, "w", encoding="utf-8") as f:
    f.write(full_html)

edge = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if not os.path.isfile(edge):
    edge = r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"
chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

browser = None
if os.path.isfile(edge):
    browser = edge
elif os.path.isfile(chrome):
    browser = chrome

if browser:
    cmd = [
        browser,
        "--headless",
        "--disable-gpu",
        f"--print-to-pdf={PDF_PATH}",
        "--no-pdf-header-footer",
        "--print-to-pdf-no-header",
        f"file:///{html_tmp.replace(os.sep, '/')}"
    ]
    result = subprocess.run(cmd, capture_output=True, timeout=30)
    if os.path.isfile(PDF_PATH) and os.path.getsize(PDF_PATH) > 1000:
        print(f"PDF gerado com {os.path.basename(browser)}: {PDF_PATH}")
        sys.exit(0)
    else:
        print(f"Falha com {os.path.basename(browser)}, tentando alternativa...")

print(f"HTML salvo em: {html_tmp}")
print("Instale weasyprint (python -m pip install weasyprint) ou abra o HTML e imprima como PDF.")
sys.exit(1)
