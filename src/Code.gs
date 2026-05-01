const SHEET_ID = "1IbxnOnBuhLIj5i8nqepk-Bva1IhmKalyuLXIyN56V8k";
const SHEET_NAME = "sheet-teste";

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return jsonResponse_({ ok: false, error: "empty_body" });
    }

    const body = JSON.parse(e.postData.contents);

    const expectedToken =
      PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN");
    if (!expectedToken || body.token !== expectedToken) {
      return jsonResponse_({ ok: false, error: "unauthorized" });
    }

    const title = typeof body.title === "string" ? body.title.trim() : "";
    const text = typeof body.text === "string" ? body.text.trim() : "";
    if (!title || !text) {
      return jsonResponse_({ ok: false, error: "missing_fields" });
    }

    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    if (!sheet) {
      return jsonResponse_({ ok: false, error: "sheet_not_found" });
    }

    sheet.appendRow([new Date().toISOString(), title, text]);
    return jsonResponse_({ ok: true });
  } catch (err) {
    return jsonResponse_({
      ok: false,
      error: String((err && err.message) || err),
    });
  }
}

function jsonResponse_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(
    ContentService.MimeType.JSON,
  );
}

// Rode esta função UMA VEZ no editor do Apps Script para definir o token.
// Depois, troque o valor abaixo por um placeholder e não comite o token real.
function setupToken() {
  PropertiesService.getScriptProperties().setProperty(
    "WEBHOOK_TOKEN",
    "TROCAR_POR_TOKEN_FORTE",
  );
}
