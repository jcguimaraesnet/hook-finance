const SHEET_ID = "1IbxnOnBuhLIj5i8nqepk-Bva1IhmKalyuLXIyN56V8k";
const SHEET_NAME = "sheet-teste";

const PURCHASE_RE =
  /Compra.+?final\s+(\d+),.+?R\$\s*([\d.,]+),.+?em\s+(\d{2}\/\d{2}\/\d{2,4}),.+?(\d{2}:\d{2}),\s*em\s+(.+?),\s*aprovada/i;

const INVOICE_CLOSING_DAY = 6;
const ORIGEM = "Cartão";

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

    const parsed = parsePurchase_(text);
    const refDateTime = parsed.refDate
      ? parsed.refTime
        ? parsed.refDate + " " + parsed.refTime
        : parsed.refDate
      : "";
    sheet.appendRow([
      nextInvoiceClosingDate_(), // Data (fechamento da fatura)
      refDateTime, // Data Referência
      parsed.description, // Descrição
      parsed.value, // Valor
      ORIGEM, // Origem
      "", // Categoria (regras virão depois)
      "", // Rateio (regras virão depois)
    ]);
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

function parsePurchase_(text) {
  const empty = { refDate: "", refTime: "", description: "", value: "" };
  const m = text.match(PURCHASE_RE);
  if (!m) return empty;
  return {
    refDate: normalizeDate_(m[3]),
    refTime: m[4],
    description: m[5].trim(),
    value: parseBrazilNumber_(m[2]),
  };
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

// Rode esta função UMA VEZ no editor do Apps Script para definir o token.
// Depois, troque o valor abaixo por um placeholder e não comite o token real.
function setupToken() {
  PropertiesService.getScriptProperties().setProperty(
    "WEBHOOK_TOKEN",
    "TROCAR_POR_TOKEN_FORTE",
  );
}
