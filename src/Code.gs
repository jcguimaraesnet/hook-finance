const SHEET_ID = "1IbxnOnBuhLIj5i8nqepk-Bva1IhmKalyuLXIyN56V8k";
const SHEET_NAME = "sheet-teste";

const CARDS = {
  "1018": "Eu",
  "4750": "Esposa",
};

const PURCHASE_RE =
  /Compra no cart[ãa]o final (\d+), de R\$\s*([\d.,]+), em (\d{2}\/\d{2}\/\d{2,4}), [àa]s (\d{2}:\d{2}), em (.+?), aprovada/i;

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

    const today = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "dd/MM/yyyy");
    const parsed = parsePurchase_(text);
    sheet.appendRow([
      today,
      parsed.refDate,
      parsed.refTime,
      parsed.cardOwner,
      parsed.cardLast4,
      parsed.description,
      parsed.value,
      title,
      text,
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
  const empty = {
    refDate: "",
    refTime: "",
    cardOwner: "",
    cardLast4: "",
    description: "",
    value: "",
  };
  const m = text.match(PURCHASE_RE);
  if (!m) return empty;
  const cardLast4 = m[1];
  return {
    refDate: normalizeDate_(m[3]),
    refTime: m[4],
    cardOwner: CARDS[cardLast4] || "",
    cardLast4: cardLast4,
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

// Rode esta função UMA VEZ no editor do Apps Script para definir o token.
// Depois, troque o valor abaixo por um placeholder e não comite o token real.
function setupToken() {
  PropertiesService.getScriptProperties().setProperty(
    "WEBHOOK_TOKEN",
    "TROCAR_POR_TOKEN_FORTE",
  );
}
