function doGet(e) {
  if (e && e.parameter && e.parameter.action === "data") {
    return getDataJson_(e.parameter.token);
  }
  return HtmlService.createTemplateFromFile("dashboard/Index")
    .evaluate()
    .setTitle("hook-finance")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

// Exposto para google.script.run (sem trailing underscore = público).
function getDataForDashboard(token) {
  return readData_(token);
}

function getDataJson_(token) {
  return jsonResponse_(readData_(token));
}

function readData_(token) {
  const expected = PropertiesService.getScriptProperties().getProperty(
    "WEBHOOK_TOKEN",
  );
  if (!expected || token !== expected) {
    return { ok: false, error: "unauthorized" };
  }
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  const last = sheet.getLastRow();
  if (last < 2) return { ok: true, rows: [] };
  const values = sheet.getRange(2, 1, last - 1, 8).getValues();
  const rows = values.map((r) => ({
    data: formatBrDate_(r[0]),
    dataRef: typeof r[1] === "string" ? r[1] : formatBrDate_(r[1]),
    descricao: String(r[2] || ""),
    valor: Number(r[3]) || 0,
    origem: String(r[4] || ""),
    categoria: String(r[5] || ""),
    rateio: String(r[6] || ""),
    cardLast4: String(r[7] || ""),
  }));
  return { ok: true, rows: rows };
}

function include_(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
