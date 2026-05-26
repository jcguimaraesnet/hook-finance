const PURCHASE_RE =
  /Compra.+?final\s+(\d+),.+?R\$\s*(-?[\d.,]+),.+?em\s+(\d{2}\/\d{2}\/\d{2,4}),.+?(\d{2}:\d{2}),\s*em\s+(.+?),\s*aprovada/i;

// Janela de dedup (segundos). O app de notificação às vezes redispara o mesmo
// payload 2-3 vezes em poucos segundos; descartamos repetições nesse intervalo.
const DEDUP_WINDOW_SECONDS = 300;

// Handler do payload de webhook (Tasker/IFTTT). Chamado a partir do doPost
// global em Dashboard.gs quando o body tem `title`+`text`.
function handleWebhookBody_(body) {
  const lock = LockService.getScriptLock();
  try {
    if (!lock.tryLock(10000)) {
      return { ok: false, error: "lock_timeout" };
    }

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

    // Dedup por hash da notificação. Se o mesmo title+text chegar dentro da
    // janela, retorna ok=true (sem inserir) pra evitar replay do app.
    const cache = CacheService.getScriptCache();
    const cacheKey = "wh:" + fingerprint_(title, text);
    if (cache.get(cacheKey)) {
      return { ok: true, deduped: true };
    }
    cache.put(cacheKey, "1", DEDUP_WINDOW_SECONDS);

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
    // Webhook usa SEMPRE a última fatura registrada na planilha. Bloco de fatura
    // (despesas fixas + linha azul) é criado apenas pelo gatilho manual
    // "Nova fatura" (ver docs/specs/rules/new-invoice.md). Fallback para
    // nextInvoiceClosingDate_ só se a planilha estiver vazia (degenerado).
    const invoiceClosing =
      latestInvoiceClosingInSheet_(sheet) || nextInvoiceClosingDate_();
    const classification = classifyFromHistory_(sheet, parsed.description);
    insertRowsAtTop_(sheet, [
      [
        parseBrDate_(invoiceClosing),
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
    // Garante formato Date na col A (sobrescreve @ herdado de updateEntry vizinho).
    sheet.getRange(2, 1, 1, 1).setNumberFormat("dd/MM/yyyy");
    return { ok: true };
  } catch (err) {
    return { ok: false, error: String((err && err.message) || err) };
  } finally {
    try {
      lock.releaseLock();
    } catch (_) {
      // ignora
    }
  }
}

function fingerprint_(title, text) {
  const bytes = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    (title || "") + "\n" + (text || ""),
  );
  let hex = "";
  for (let i = 0; i < bytes.length; i++) {
    const b = bytes[i] < 0 ? bytes[i] + 256 : bytes[i];
    hex += ("0" + b.toString(16)).slice(-2);
  }
  return hex;
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
