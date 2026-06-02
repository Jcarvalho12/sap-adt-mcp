/**
 * Cliente da API web do agent_consultor_E05
 */

const $ = (sel, root = document) => root.querySelector(sel);

const state = {
  lastAnalysis: null,
};

function showToast(message, kind = "ok") {
  const el = $("#toast");
  el.textContent = message;
  el.hidden = false;
  el.classList.remove("toast--error", "toast--ok");
  el.classList.add(kind === "error" ? "toast--error" : "toast--ok");
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => {
    el.hidden = true;
  }, 5200);
}

async function fetchJson(url, options = {}) {
  const res = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { detail: text };
  }
  if (!res.ok) {
    const msg = data.detail || data.message || res.statusText || "Erro na requisição";
    const err = new Error(typeof msg === "string" ? msg : JSON.stringify(msg));
    err.status = res.status;
    throw err;
  }
  return data;
}

function setLoading(btn, loading) {
  const sp = $(".btn__spinner", btn);
  const tx = $(".btn__text", btn);
  btn.disabled = loading;
  if (sp) sp.hidden = !loading;
  if (tx) tx.style.opacity = loading ? "0.85" : "";
}

function activateTab(name) {
  document.querySelectorAll(".tab").forEach((t) => {
    const on = t.dataset.tab === name;
    t.classList.toggle("is-active", on);
    t.setAttribute("aria-selected", on ? "true" : "false");
  });
  document.querySelectorAll(".tab-panel").forEach((p) => {
    const id = p.id.replace("panel-", "");
    const on = id === name;
    p.classList.toggle("is-active", on);
    p.hidden = !on;
  });
}

function simpleMarkdownToHtml(md) {
  if (!md) return "<p>(sem achados)</p>";
  const esc = (s) =>
    s
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  const lines = md.split(/\r?\n/);
  let html = "";
  let inList = false;
  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith("### ")) {
      if (inList) {
        html += "</ul>";
        inList = false;
      }
      html += `<h3>${esc(t.slice(4))}</h3>`;
    } else if (t.startsWith("## ")) {
      if (inList) {
        html += "</ul>";
        inList = false;
      }
      html += `<h2>${esc(t.slice(3))}</h2>`;
    } else if (t.startsWith("- ") || t.startsWith("* ")) {
      if (!inList) {
        html += "<ul>";
        inList = true;
      }
      html += `<li>${esc(t.slice(2))}</li>`;
    } else if (t === "") {
      if (inList) {
        html += "</ul>";
        inList = false;
      }
      html += "<br/>";
    } else {
      if (inList) {
        html += "</ul>";
        inList = false;
      }
      html += `<p>${esc(line)}</p>`;
    }
  }
  if (inList) html += "</ul>";
  return html || `<p>${esc(md)}</p>`;
}

async function checkHealth() {
  const pill = $("#health-pill");
  try {
    await fetchJson("/health");
    pill.textContent = "Servidor OK";
    pill.classList.remove("pill--muted", "pill--err");
    pill.classList.add("pill--ok");
  } catch {
    pill.textContent = "Servidor indisponível";
    pill.classList.remove("pill--muted", "pill--ok");
    pill.classList.add("pill--err");
  }
}

$("#analyze-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const form = e.target;
  const fd = new FormData(form);
  const body = {
    object_name: (fd.get("object_name") || "").trim(),
    object_type: (fd.get("object_type") || "").trim(),
    include_name: (fd.get("include_name") || "").trim() || null,
    system_id: (fd.get("system_id") || "").trim() || null,
    password: (fd.get("password") || "").trim() || null,
  };

  const btn = $("#btn-analyze");
  setLoading(btn, true);
  try {
    const data = await fetchJson("/api/analyze", {
      method: "POST",
      body: JSON.stringify(body),
    });
    state.lastAnalysis = data;

    $("#results-panel").hidden = false;
    $("#scope-hint").textContent = `Escopo: ${data.scope_name} · Tipo ADT efetivo: ${data.effective_type} · Pacote (hint): ${data.discovery?.package_hint || "—"}`;

    $("#findings-md").innerHTML = simpleMarkdownToHtml(data.findings_markdown || "");
    $("#twocol-pre").textContent = data.two_column_preview || "";
    $("#unified-pre").textContent =
      (data.unified_diff || "") + (data.unified_diff_truncated ? "\n\n… (truncado; ver terminal para diff completo)" : "");

    const meta = {
      connect_message: data.connect_message,
      discovery: data.discovery,
      metadata: data.metadata,
      dependency_map: data.dependency_map,
      resolved_adt_type: data.resolved_adt_type,
      temp_dir: data.temp_dir || null,
      saved_source_file: data.saved_source_file || null,
    };
    $("#meta-pre").textContent = JSON.stringify(meta, null, 2);

    const fileInfo = $("#source-file-info");
    if (fileInfo && data.saved_source_file) {
      fileInfo.textContent = `Arquivo fonte salvo: ${data.saved_source_file}`;
      fileInfo.hidden = false;
    } else if (fileInfo) {
      fileInfo.hidden = true;
    }

    activateTab("findings");
    $("#clone-log").hidden = true;
    showToast("Análise concluída. Revise os achados e o diff antes de clonar.");
  } catch (err) {
    showToast(err.message || String(err), "error");
  } finally {
    setLoading(btn, false);
  }
});

$("#clone-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  if (!state.lastAnalysis) {
    showToast("Execute a análise antes de clonar.", "error");
    return;
  }
  const fd = new FormData(e.target);
  const analyzeForm = $("#analyze-form");
  const afd = new FormData(analyzeForm);

  const body = {
    scope_name: state.lastAnalysis.scope_name,
    effective_type: state.lastAnalysis.effective_type,
    improved: state.lastAnalysis.improved,
    new_name: (fd.get("new_name") || "").trim(),
    package: (fd.get("package") || "").trim(),
    transport: (fd.get("transport") || "").trim(),
    transport_description: (fd.get("transport_description") || "").trim() || null,
    system_id: (afd.get("system_id") || "").trim() || null,
    password: (afd.get("password") || "").trim() || null,
  };

  const btn = $("#btn-clone");
  setLoading(btn, true);
  const logEl = $("#clone-log");
  try {
    const data = await fetchJson("/api/clone", {
      method: "POST",
      body: JSON.stringify(body),
    });
    logEl.hidden = false;
    logEl.textContent = JSON.stringify(data, null, 2);
    if (data.ok) {
      const fileMsg = data.improved_file ? ` | Arquivo: ${data.improved_file}` : "";
      showToast(`Objeto ${data.new_name} criado. Transporte: ${data.transport || "n/a"}${fileMsg}`);
    } else {
      const msg = [data.hint, data.message, data.error].filter(Boolean).join(" — ");
      showToast(msg || "Falha no clone", "error");
    }
  } catch (err) {
    logEl.hidden = false;
    logEl.textContent = err.message || String(err);
    showToast(err.message || String(err), "error");
  } finally {
    setLoading(btn, false);
  }
});

document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => activateTab(tab.dataset.tab));
});

checkHealth();
setInterval(checkHealth, 30000);
