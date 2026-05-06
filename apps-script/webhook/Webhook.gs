const PURCHASE_RE =
  /Compra.+?final\s+(\d+),.+?R\$\s*(-?[\d.,]+),.+?em\s+(\d{2}\/\d{2}\/\d{2,4}),.+?(\d{2}:\d{2}),\s*em\s+(.+?),\s*aprovada/i;

// Handler do payload de webhook (Tasker/IFTTT). Chamado a partir do doPost
// global em Dashboard.gs quando o body tem `title`+`text`.
function handleWebhookBody_(body) {
  try {
    const expectedToken =
      PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN");
    if (!expectedToken || body.token !== expectedToken) {
      return { ok: false, error: "unauthorized" };
    }

    const title = typeof body.title === "string" ? body.title.trim() : "";
    const text = typeof body.text === "string" ? body.text.trim() : "";
    if (!title || !text) {
      return { ok: false, error: "missing_fields" };
    }

    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    if (!sheet) {
      return { ok: false, error: "sheet_not_found" };
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
        "", // Parcela (vazio = à vista; se parcelado, usuário marca via modal "1/N")
        "", // Acerto (não aplicável a compras de Cartão)
      ],
    ]);
    return { ok: true };
  } catch (err) {
    return { ok: false, error: String((err && err.message) || err) };
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
