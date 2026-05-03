const PURCHASE_RE =
  /Compra.+?final\s+(\d+),.+?R\$\s*(-?[\d.,]+),.+?em\s+(\d{2}\/\d{2}\/\d{2,4}),.+?(\d{2}:\d{2}),\s*em\s+(.+?),\s*aprovada/i;

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
    const invoiceClosing = nextInvoiceClosingDate_();
    appendMonthlyFixedIfNeeded_(sheet, invoiceClosing);
    const classification = classifyFromHistory_(sheet, parsed.description);
    insertRowsAtTop_(sheet, [
      [
        invoiceClosing,
        refDateTime,
        parsed.description,
        parsed.value,
        ORIGEM,
        classification.categoria,
        classification.rateio,
        parsed.cardLast4,
      ],
    ]);
    return jsonResponse_({ ok: true });
  } catch (err) {
    return jsonResponse_({
      ok: false,
      error: String((err && err.message) || err),
    });
  }
}

function parsePurchase_(text) {
  const empty = {
    refDate: "",
    refTime: "",
    description: "",
    value: "",
    cardLast4: "",
  };
  const m = text.match(PURCHASE_RE);
  if (!m) return empty;
  return {
    refDate: normalizeDate_(m[3]),
    refTime: m[4],
    description: m[5].trim(),
    value: parseBrazilNumber_(m[2]),
    cardLast4: m[1],
  };
}
