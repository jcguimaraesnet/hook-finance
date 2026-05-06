// One-shot migration: popula a coluna Parcela (col I) das compras parceladas
// já presentes na fatura com fechamento em 06/05/2026.
//
// USO (manual via editor Apps Script):
//   1) Faça `clasp push -f` (ou aguarde o GH Action) para subir este arquivo.
//   2) No editor Apps Script, selecione a função `syncParcelas20260506` e clique em "Executar".
//   3) Confira o log (Ver > Logs / Execution log) — deve listar 33 atualizações.
//   4) DELETE este arquivo (e faça push) — a função existe só pra esta migração pontual.

const PARCELAS_TARGET_CYCLE = "06/05/2026";

const PARCELAS_20260506 = [
  // JULIO C R GUIMARAES — final 9727
  { card: "9727", date: "08/04", valor: 103.23, desc: "UNIDAS LOCADORA FLN6", parcela: "1/3" },

  // JULIO C R GUIMARA — final 1018
  { card: "1018", date: "14/01", valor: 164.81, desc: "PORTO SEGURO CIA SEG G", parcela: "4/10" },
  { card: "1018", date: "28/02", valor: 353.29, desc: "MP *LOJAMIRANTE", parcela: "2/2" },
  { card: "1018", date: "28/02", valor: 209.00, desc: "DIEGOJOAQUIMVIDAL", parcela: "2/2" },
  { card: "1018", date: "28/02", valor: 105.00, desc: "MERCADO*MERCADOLIVRE", parcela: "2/2" },
  { card: "1018", date: "02/03", valor: 82.79, desc: "MERCADO*MERCADOLIVRE", parcela: "2/2" },
  { card: "1018", date: "03/03", valor: 149.95, desc: "PAYPAL *LAVIBORA", parcela: "2/2" },
  { card: "1018", date: "10/03", valor: 368.04, desc: "RENTCARS", parcela: "2/3" },
  { card: "1018", date: "14/03", valor: 163.33, desc: "TRADICIONAL", parcela: "2/3" },
  { card: "1018", date: "15/03", valor: 59.90, desc: "AVENTURAJURASSICAEC", parcela: "2/2" },
  { card: "1018", date: "15/03", valor: 52.82, desc: "MERCADO*MERCADOLIVRE", parcela: "2/3" },
  { card: "1018", date: "18/03", valor: 73.33, desc: "DIEGOJOAQUIMVIDAL", parcela: "2/3" },
  { card: "1018", date: "19/03", valor: 149.85, desc: "PG *PL- KARAZAN E O C", parcela: "2/2" },
  { card: "1018", date: "24/03", valor: 674.55, desc: "ON SPORTSWEAR", parcela: "1/2" },
  { card: "1018", date: "09/04", valor: 125.30, desc: "BETO CARRERO WORLD", parcela: "1/3" },
  { card: "1018", date: "09/04", valor: 66.34, desc: "BETO CARRERO WORLD", parcela: "1/3" },
  { card: "1018", date: "10/04", valor: 67.34, desc: "BETO CARRERO WORLD", parcela: "1/3" },
  { card: "1018", date: "11/04", valor: 50.00, desc: "ALLES PARK ECOTURISMO", parcela: "1/2" },
  { card: "1018", date: "13/04", valor: 54.94, desc: "AVENTURA JURASSICA", parcela: "1/3" },
  { card: "1018", date: "15/04", valor: 61.30, desc: "DROGARIAS PACHECO S A", parcela: "1/2" },
  { card: "1018", date: "23/04", valor: 185.99, desc: "RI HAPPY", parcela: "1/2" },

  // DANIELLE LORETO — final 0784
  { card: "0784", date: "20/02", valor: 490.00, desc: "BARRA SMILE", parcela: "3/5" },
  { card: "0784", date: "19/03", valor: 161.55, desc: "PEAHI - JACAREPAGUA", parcela: "2/3" },
  { card: "0784", date: "27/03", valor: 151.70, desc: "PEAHI - JACAREPAGUA", parcela: "1/3" },
  { card: "0784", date: "12/04", valor: 199.30, desc: "BIANCA LARICA BARBIE", parcela: "1/2" },
  { card: "0784", date: "14/04", valor: 178.09, desc: "DUFRY DO BRASIL DUTY F", parcela: "1/3" },

  // DANIELLE LORETO — final 4750
  { card: "4750", date: "06/03", valor: 122.16, desc: "VIA MIA", parcela: "2/2" },
  { card: "4750", date: "11/03", valor: 191.90, desc: "AIRBNB * HM2NZF4MHN", parcela: "2/3" },
  { card: "4750", date: "16/03", valor: 177.38, desc: "SPG*CONSELHOREGIONALDE", parcela: "2/4" },
  { card: "4750", date: "17/03", valor: 502.58, desc: "BETO CARRERO*BETO CARR", parcela: "2/3" },
  { card: "4750", date: "17/03", valor: 69.39, desc: "SPG*CONSELHOREGIONALDE", parcela: "2/9" },
  { card: "4750", date: "01/04", valor: 85.50, desc: "ALLES PARK", parcela: "1/3" },
  { card: "4750", date: "01/04", valor: 31.00, desc: "ZOO POMERODE", parcela: "1/3" },
];

function syncParcelas20260506() {
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) { Logger.log("ERRO: planilha não encontrada."); return; }
  const last = sheet.getLastRow();
  if (last < 2) { Logger.log("Planilha vazia."); return; }

  const tz = Session.getScriptTimeZone();

  function fmtDate(v) {
    if (v instanceof Date) return Utilities.formatDate(v, tz, "dd/MM/yyyy");
    return String(v || "").trim();
  }
  function fmtDateTime(v) {
    if (v instanceof Date) return Utilities.formatDate(v, tz, "dd/MM/yyyy HH:mm");
    return String(v || "").trim();
  }
  function normalizeCard_(v) {
    // Aceita número (784) ou string ("0784", "0784 ") e devolve sempre "0784" com 4 dígitos.
    const digits = String(v || "").replace(/\D/g, "");
    if (!digits) return "";
    return digits.length >= 4 ? digits : ("0000" + digits).slice(-4);
  }
  function normalizeValor_(v) {
    if (typeof v === "number") return v;
    const s = String(v || "").trim().replace(/\./g, "").replace(",", ".");
    const n = parseFloat(s);
    return isNaN(n) ? 0 : n;
  }
  function normalizeDescPart_(s) {
    // Remove tudo exceto letras/dígitos pra match tolerante a espaços, asteriscos e pontuação.
    return String(s || "").toUpperCase().replace(/[^A-Z0-9]/g, "");
  }
  function dateMatchesDDMM_(dataRef, ddmm) {
    // ddmm = "08/04". Considera com ou sem zero à esquerda no dia/mês.
    const s = String(dataRef || "").trim();
    if (!s) return false;
    const norm = ddmm; // "08/04"
    const noZero = ddmm.split("/").map((p) => String(parseInt(p, 10))).join("/"); // "8/4"
    return s.indexOf(norm + "/") === 0 || s.indexOf(noZero + "/") === 0
      || s.indexOf(norm + " ") === 0 || s.indexOf(noZero + " ") === 0
      || s === norm || s === noZero;
  }

  // 1) Localiza o range de linhas do ciclo alvo (col A).
  const dataCol = sheet.getRange(2, 1, last - 1, 1).getValues();
  const matchIndexes = [];
  for (let i = 0; i < dataCol.length; i++) {
    if (fmtDate(dataCol[i][0]) === PARCELAS_TARGET_CYCLE) matchIndexes.push(i + 2);
  }
  if (matchIndexes.length === 0) {
    Logger.log("Nenhuma linha encontrada para fatura " + PARCELAS_TARGET_CYCLE);
    return;
  }
  const minRow = matchIndexes[0];
  const maxRow = matchIndexes[matchIndexes.length - 1];
  const slab = sheet.getRange(minRow, 1, maxRow - minRow + 1, 9).getValues();

  Logger.log("Range do ciclo " + PARCELAS_TARGET_CYCLE + ": linhas " + minRow + ".." + maxRow);
  Logger.log("Total de linhas no ciclo: " + matchIndexes.length);

  // 2) Diagnóstico: imprime as primeiras 3 linhas pra ver tipos/formatos reais.
  Logger.log("=== Sample slab rows (primeiras 3 do ciclo) ===");
  for (let i = 0; i < Math.min(3, slab.length); i++) {
    const r = slab[i];
    Logger.log(
      "Row " + (minRow + i) +
      "\n  A data:    typeof=" + typeof r[0] + " val=" + (r[0] instanceof Date ? "Date " + r[0].toISOString() : ("'" + r[0] + "'")) +
      "\n  B dataRef: typeof=" + typeof r[1] + " val=" + (r[1] instanceof Date ? "Date " + r[1].toISOString() : ("'" + r[1] + "'")) + " | fmtDateTime='" + fmtDateTime(r[1]) + "'" +
      "\n  C descr:   '" + r[2] + "'" +
      "\n  D valor:   typeof=" + typeof r[3] + " val=" + r[3] + " | norm=" + normalizeValor_(r[3]) +
      "\n  H card:    typeof=" + typeof r[7] + " val=" + r[7] + " | norm='" + normalizeCard_(r[7]) + "'"
    );
  }

  // 3) Casa cada entry contra as linhas do slab.
  const claimed = new Set();
  const updates = [];
  const unmatched = [];

  for (const entry of PARCELAS_20260506) {
    const descPart = normalizeDescPart_(entry.desc);
    const targetCard = normalizeCard_(entry.card);
    let foundRow = -1;
    let matchTrace = { card: 0, valor: 0, date: 0, desc: 0 };
    for (let i = 0; i < slab.length; i++) {
      const absRow = minRow + i;
      if (claimed.has(absRow)) continue;
      const r = slab[i];
      if (fmtDate(r[0]) !== PARCELAS_TARGET_CYCLE) continue;
      const card = normalizeCard_(r[7]);
      if (card !== targetCard) continue;
      matchTrace.card++;
      const valor = normalizeValor_(r[3]);
      if (Math.abs(valor - entry.valor) > 0.01) continue;
      matchTrace.valor++;
      const dataRef = fmtDateTime(r[1]);
      if (!dateMatchesDDMM_(dataRef, entry.date)) continue;
      matchTrace.date++;
      const desc = normalizeDescPart_(r[2]);
      if (desc.indexOf(descPart) === -1) continue;
      matchTrace.desc++;
      foundRow = absRow;
      break;
    }
    if (foundRow > 0) {
      claimed.add(foundRow);
      updates.push({ row: foundRow, parcela: entry.parcela, entry: entry });
    } else {
      unmatched.push({ entry: entry, trace: matchTrace });
    }
  }

  Logger.log("=== Casados: " + updates.length + " ===");
  for (const u of updates) {
    Logger.log(
      "row " + u.row + " ← " + u.parcela +
      "  [" + u.entry.card + " " + u.entry.date + " " + u.entry.valor + " " + u.entry.desc + "]"
    );
  }

  Logger.log("=== Não casados: " + unmatched.length + " ===");
  for (const u of unmatched) {
    const e = u.entry;
    Logger.log(
      "MISS  [" + e.card + " " + e.date + " " + e.valor + " " + e.desc + "] " +
      "trace card=" + u.trace.card + " valor=" + u.trace.valor + " date=" + u.trace.date
    );
  }

  // 4) Aplica os updates na col 9 (Parcela).
  for (const u of updates) {
    sheet.getRange(u.row, 9).setValue(u.parcela);
  }

  Logger.log("DONE. " + updates.length + " linhas atualizadas. " +
    unmatched.length + " entries não encontradas.");
}
