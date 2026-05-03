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
