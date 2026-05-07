---
status: stable
last_updated: 2026-05-07
---

# Webhook (Tasker / IFTTT)

Recebe notificações de compra do app de notificação Android e insere uma linha em `Despesas`. Reusa `doPost` global do Apps Script.

## Contexto

Banco/cartão envia push notification ao Android. Tasker (ou IFTTT) detecta o título/texto e dispara `POST` para o Apps Script. O Apps Script extrai descrição, valor, data, e final do cartão da string e insere no topo da planilha. A primeira compra de cada fatura nova também dispara a inserção das despesas fixas mensais — ver [../rules/fixed-expenses.md](../rules/fixed-expenses.md).

## Regras

- **Endpoint:** mesmo `doPost` do REST. Distinção: body tem `title` E `text`.
- **Body esperado:**
  ```json
  {
    "title": "Compra aprovada",
    "text": "Compra de R$ 89,50 no cartão final 1018, em 03/04/2026, 14:32, em MERCADO ABC, aprovada",
    "token": "<WEBHOOK_TOKEN>"
  }
  ```
- **Token:** mesmo `WEBHOOK_TOKEN` dos endpoints REST. Verificado por igualdade exata.
- **Sem token / token inválido:** `{ ok: false, error: "unauthorized" }`.
- **`title` ou `text` vazio:** `{ ok: false, error: "missing_fields" }`.
- **Lock:** `LockService.getScriptLock().tryLock(10000)`. Timeout → `{ ok: false, error: "lock_timeout" }`.
- **Dedup:** SHA-256 de `title + "\n" + text` é guardado em `CacheService.getScriptCache()` por 300s. Hit → `{ ok: true, deduped: true }` (sem inserir). Ver [../rules/webhook-dedup.md](../rules/webhook-dedup.md).
- **Parser:** [../rules/webhook-parser.md](../rules/webhook-parser.md) extrai cinco campos via `PURCHASE_RE`. Se não casar, descricao/valor/data ficam vazios mas a linha é inserida mesmo assim com `Data` (col A) e `Origem = "Cartão"`.
- **Inserção:**
  - col A (Data): `nextInvoiceClosingDate_()`.
  - col B (Data Referência): `"DD/MM/YYYY HH:MM"` ou só data se hora indisponível.
  - col C (Descrição): texto extraído.
  - col D (Valor): número extraído.
  - col E (Origem): `"Cartão"` (constante `ORIGEM`).
  - col F/G (Categoria/Rateio): inferidos por `classifyFromHistory_` — ver [../rules/classifier.md](../rules/classifier.md). Vazios se score < `CLASSIFY_THRESHOLD`.
  - col H (Cartão): `cardLast4` extraído.
  - col I/J (Parcela/Acerto): vazios.
- **Despesas fixas:** antes de inserir a compra nova, `appendMonthlyFixedIfNeeded_(sheet, invoiceClosing)` insere o bloco mensal se ainda não existe linha desta fatura — ver [../rules/fixed-expenses.md](../rules/fixed-expenses.md).

## Edge cases

- **Lock timeout:** o cliente (Tasker) deve fazer retry; conteúdo idempotente via dedup.
- **Notificação reenviada (replay):** dedup descarta; resposta `ok: true, deduped: true`.
- **Texto que não casa com `PURCHASE_RE`:** linha entra com campos vazios. Útil pra detectar regex stale.
- **Nova fatura no mesmo dia que outra compra:** `appendMonthlyFixedIfNeeded_` checa por `Data === invoiceClosing AND Origem === "Cartão"` — se essa for a 2ª compra, fixed já existem e não duplicam.
- **Cartão final desconhecido:** insere mesmo assim com `cardLast4` literal. PWA/Flutter devem tratar `cardLast4` ausente do mapping.

## Implementações

- **Backend (autoritativo):** [apps-script/webhook/Webhook.gs](../../../apps-script/webhook/Webhook.gs)
- **PWA/Flutter:** não consomem este endpoint diretamente (write-only do Tasker).

## Specs relacionadas

- [../rules/webhook-parser.md](../rules/webhook-parser.md)
- [../rules/webhook-dedup.md](../rules/webhook-dedup.md)
- [../rules/classifier.md](../rules/classifier.md)
- [../rules/invoice-closing-date.md](../rules/invoice-closing-date.md)
- [../rules/fixed-expenses.md](../rules/fixed-expenses.md)
- [endpoints.md](endpoints.md)
