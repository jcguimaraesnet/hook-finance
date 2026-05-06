// Diagnóstico one-shot (READ-ONLY): para cada lançamento parcelado da fatura 06/05/2026
// que ainda tem parcela a pagar (parcela_atual < total), verifica se já existe um
// lançamento correspondente na fatura posterior 06/06/2026.
//
// Não grava nada. Apenas loga.
//
// USO: rode `checkMissingParcelas` no editor Apps Script. Após verificar, delete o arquivo.

function checkMissingParcelas() {
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) { Logger.log("ERRO: planilha não encontrada."); return; }
  const last = sheet.getLastRow();
  if (last < 2) { Logger.log("Planilha vazia."); return; }

  const tz = Session.getScriptTimeZone();
  const SOURCE_CYCLE = "06/05/2026";
  const TARGET_CYCLE = "06/06/2026";

  function fmtDate(v) {
    if (v instanceof Date) return Utilities.formatDate(v, tz, "dd/MM/yyyy");
    return String(v || "").trim();
  }
  function normalizeValor_(v) {
    if (typeof v === "number") return v;
    const s = String(v || "").trim().replace(/\./g, "").replace(",", ".");
    const n = parseFloat(s);
    return isNaN(n) ? 0 : n;
  }
  function normalizeCard_(v) {
    const digits = String(v || "").replace(/\D/g, "");
    if (!digits) return "";
    return digits.length >= 4 ? digits : ("0000" + digits).slice(-4);
  }
  function stripParcelaSuffix_(s) {
    return String(s || "").replace(/\s*\(\s*\d+\s*\/\s*\d+\s*\)\s*$/, "").trim();
  }
  function normalizeDescPart_(s) {
    return String(s || "").toUpperCase().replace(/[^A-Z0-9]/g, "");
  }
  function parsePAtualTotal_(parcelaCell) {
    if (parcelaCell instanceof Date) {
      // Caso ainda haja célula como Date (caso fix migration não tenha rodado para essa célula).
      const day = parseInt(Utilities.formatDate(parcelaCell, tz, "d"), 10);
      const month = parseInt(Utilities.formatDate(parcelaCell, tz, "M"), 10);
      return { atual: day, total: month };
    }
    const s = String(parcelaCell || "").trim();
    if (!s || s.indexOf("/") === -1) return null;
    const parts = s.split("/");
    const atual = parseInt(parts[0], 10);
    const total = parseInt(parts[1], 10);
    if (!atual || !total) return null;
    return { atual: atual, total: total };
  }

  // Lê o sheet inteiro uma vez (10 cols).
  const all = sheet.getRange(2, 1, last - 1, 10).getValues();
  const sourceRows = [];
  const targetRows = [];
  for (let i = 0; i < all.length; i++) {
    const r = all[i];
    const cycle = fmtDate(r[0]);
    if (cycle === SOURCE_CYCLE) {
      sourceRows.push({ absRow: i + 2, raw: r });
    } else if (cycle === TARGET_CYCLE) {
      targetRows.push({ absRow: i + 2, raw: r });
    }
  }

  Logger.log("Linhas em " + SOURCE_CYCLE + ": " + sourceRows.length);
  Logger.log("Linhas em " + TARGET_CYCLE + ": " + targetRows.length);

  if (sourceRows.length === 0) {
    Logger.log("Nenhuma linha encontrada em " + SOURCE_CYCLE);
    return;
  }

  // Filtra os parcelados da fatura origem com parcela_atual < total.
  const pendingFromSource = [];
  for (const item of sourceRows) {
    const r = item.raw;
    const p = parsePAtualTotal_(r[8]);
    if (!p) continue;
    if (p.atual >= p.total) continue; // já é a última parcela
    pendingFromSource.push({
      absRow: item.absRow,
      descRaw: String(r[2] || ""),
      descNorm: normalizeDescPart_(stripParcelaSuffix_(r[2])),
      valor: normalizeValor_(r[3]),
      card: normalizeCard_(r[7]),
      parcelaAtual: p.atual,
      parcelaTotal: p.total,
      proximaParcela: (p.atual + 1) + "/" + p.total,
    });
  }

  Logger.log("Parcelados em " + SOURCE_CYCLE + " com parcela a pagar: " + pendingFromSource.length);

  if (pendingFromSource.length === 0) {
    Logger.log("Nada a verificar (todos os parcelados de " + SOURCE_CYCLE + " já estão na última parcela).");
    return;
  }

  // Pré-processa target rows pra match.
  const targetIndexed = targetRows.map((item) => ({
    absRow: item.absRow,
    descRaw: String(item.raw[2] || ""),
    descNorm: normalizeDescPart_(stripParcelaSuffix_(item.raw[2])),
    valor: normalizeValor_(item.raw[3]),
    card: normalizeCard_(item.raw[7]),
    parcela: String(item.raw[8] || "").trim(),
  }));

  // Para cada pending, busca na fatura alvo.
  const found = [];
  const missing = [];
  const claimedTarget = new Set();
  for (const p of pendingFromSource) {
    let matchedTarget = null;
    for (const t of targetIndexed) {
      if (claimedTarget.has(t.absRow)) continue;
      if (Math.abs(t.valor - p.valor) > 0.01) continue;
      if (p.card && t.card && p.card !== t.card) continue;
      // Match de desc: prefix bidirecional
      const a = t.descNorm;
      const b = p.descNorm;
      if (!a || !b) continue;
      const descOk = a === b || a.indexOf(b) === 0 || b.indexOf(a) === 0 || a.indexOf(b) !== -1 || b.indexOf(a) !== -1;
      if (!descOk) continue;
      matchedTarget = t;
      break;
    }
    if (matchedTarget) {
      claimedTarget.add(matchedTarget.absRow);
      found.push({ pending: p, target: matchedTarget });
    } else {
      missing.push(p);
    }
  }

  Logger.log("=== Parcelados PRESENTES na fatura " + TARGET_CYCLE + " (" + found.length + ") ===");
  for (const f of found) {
    Logger.log(
      "src row " + f.pending.absRow + " (" + f.pending.parcelaAtual + "/" + f.pending.parcelaTotal + ") " +
      "→ tgt row " + f.target.absRow + " | desc='" + f.target.descRaw + "' valor=" + f.target.valor +
      " parcela_alvo='" + f.target.parcela + "'"
    );
  }

  Logger.log("=== Parcelados FALTANDO em " + TARGET_CYCLE + " (" + missing.length + ") ===");
  for (const m of missing) {
    Logger.log(
      "row " + m.absRow + " | '" + m.descRaw + "' | R$ " + m.valor +
      " | card '" + m.card + "' | atual " + m.parcelaAtual + "/" + m.parcelaTotal +
      " | esperado em " + TARGET_CYCLE + ": " + m.proximaParcela
    );
  }

  Logger.log("DONE. Source pending=" + pendingFromSource.length +
    " | Found=" + found.length + " | Missing=" + missing.length);
}
