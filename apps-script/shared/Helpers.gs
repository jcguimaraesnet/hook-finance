function jsonResponse_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(
    ContentService.MimeType.JSON,
  );
}

function parseBrazilNumber_(s) {
  const n = parseFloat(s.replace(/\./g, "").replace(",", "."));
  return isNaN(n) ? "" : n;
}

function normalizeDate_(d) {
  const parts = d.split("/");
  if (parts.length === 3 && parts[2].length === 2) parts[2] = "20" + parts[2];
  return parts.join("/");
}

function formatBrDate_(v) {
  if (v instanceof Date) {
    return Utilities.formatDate(v, Session.getScriptTimeZone(), "dd/MM/yyyy");
  }
  return String(v).trim();
}

function parseBrDate_(s) {
  const parts = String(s || "").split("/");
  if (parts.length !== 3) return new Date(0);
  const d = parseInt(parts[0], 10) || 1;
  const m = parseInt(parts[1], 10) || 1;
  const y = parseInt(parts[2], 10) || 1970;
  return new Date(y, m - 1, d);
}

function insertRowsAtTop_(sheet, rows) {
  if (!rows || rows.length === 0) return;
  sheet.insertRowsBefore(2, rows.length);
  sheet.getRange(2, 1, rows.length, rows[0].length).setValues(rows);
}

function nextInvoiceClosingDate_() {
  const tz = Session.getScriptTimeZone();
  const now = new Date();
  const year = parseInt(Utilities.formatDate(now, tz, "yyyy"), 10);
  const month = parseInt(Utilities.formatDate(now, tz, "MM"), 10);
  let nextMonth = month + 1;
  let nextYear = year;
  if (nextMonth > 12) {
    nextMonth = 1;
    nextYear += 1;
  }
  const dd = ("0" + INVOICE_CLOSING_DAY).slice(-2);
  const mm = ("0" + nextMonth).slice(-2);
  return dd + "/" + mm + "/" + nextYear;
}

// Acha a fatura anterior (a mais recente com data STRICTLY LESS THAN newClosing).
// Retorna { closing: "DD/MM/YYYY", rows: [{ rowIndex, values }] } ou null.
// rowIndex é 1-indexed (linha real na planilha).
function findCurrentInvoice_(sheet, newClosing) {
  const last = sheet.getLastRow();
  if (last < 2) return null;
  const data = sheet.getRange(2, 1, last - 1, 10).getValues();
  const newDate = parseBrDate_(newClosing);

  let bestClosing = null;
  let bestDate = null;
  for (let i = 0; i < data.length; i++) {
    const closing = formatBrDate_(data[i][0]);
    if (!closing) continue;
    const d = parseBrDate_(closing);
    if (d >= newDate) continue;
    if (bestDate === null || d > bestDate) {
      bestDate = d;
      bestClosing = closing;
    }
  }
  if (!bestClosing) return null;

  const rows = [];
  for (let i = 0; i < data.length; i++) {
    if (formatBrDate_(data[i][0]) === bestClosing) {
      rows.push({ rowIndex: i + 2, values: data[i] });
    }
  }
  return { closing: bestClosing, rows: rows };
}

// Rola uma linha de parcela para a fatura nova. Pula se col I não bate
// /^\d+\/\d+$/, ou se X >= Y, ou se col I vazia.
// Retorna array de 10 valores (nova linha) ou null.
function rolloverParcelaRow_(rowValues, newClosing) {
  const parcela = String(rowValues[8] || "").trim();
  const m = parcela.match(/^(\d+)\/(\d+)$/);
  if (!m) return null;
  const x = parseInt(m[1], 10);
  const y = parseInt(m[2], 10);
  if (!(x < y)) return null;
  return [
    newClosing,       // A — fatura nova
    rowValues[1],     // B — DataRef original (audit trail)
    rowValues[2],     // C — descrição
    rowValues[3],     // D — valor
    rowValues[4],     // E — origem
    rowValues[5],     // F — categoria
    rowValues[6],     // G — rateio
    rowValues[7],     // H — cartão
    (x + 1) + "/" + y, // I — próxima parcela
    rowValues[9],     // J — acerto
  ];
}
