---
status: stable
last_updated: 2026-05-26
---

# Webhook (Tasker / IFTTT)

Recebe notificações de compra do app de notificação Android e insere uma linha em `Despesas`. Reusa `doPost` global do Apps Script.

## Contexto

Banco/cartão envia push notification ao Android. Tasker (ou IFTTT) detecta o título/texto e dispara `POST` para o Apps Script. O Apps Script extrai descrição, valor, data, e final do cartão da string e insere no topo da planilha **na última fatura já registrada na planilha**.

> Webhook NÃO cria mais o bloco de "início de fatura" (despesas fixas + linha azul). Esse bloco é criado **apenas** pelo gatilho manual Nova fatura — ver [../rules/new-invoice.md](../rules/new-invoice.md). Fluxo esperado: usuário clica Nova fatura no início do mês → bloco criado → webhook empilha as compras nessa fatura ao longo do mês.

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
  - col A (Data): `latestInvoiceClosingInSheet_(sheet)` (string da fatura mais recente já na planilha) → convertido para `Date` via `parseBrDate_`. Fallback para `nextInvoiceClosingDate_()` apenas se a planilha estiver vazia. Force `setNumberFormat("dd/MM/yyyy")` após insert.
  - col B (Data Referência): `"DD/MM/YYYY HH:MM"` ou só data se hora indisponível.
  - col C (Descrição): texto extraído.
  - col D (Valor): número extraído.
  - col E (Origem): `"Cartão"` (constante `ORIGEM`).
  - col F/G (Categoria/Rateio): inferidos por `classifyFromHistory_` — ver [../rules/classifier.md](../rules/classifier.md). Vazios se score < `CLASSIFY_THRESHOLD`.
  - col H (Cartão): `cardLast4` extraído.
  - col I/J (Parcela/Acerto): vazios.
- **Despesas fixas:** webhook não cria mais bloco. Use Nova fatura ([../rules/new-invoice.md](../rules/new-invoice.md)) para criar o bloco antes de receber compras de uma nova fatura.

## Edge cases

- **Lock timeout:** o cliente (Tasker) deve fazer retry; conteúdo idempotente via dedup.
- **Notificação reenviada (replay):** dedup descarta; resposta `ok: true, deduped: true`.
- **Texto que não casa com `PURCHASE_RE`:** linha entra com campos vazios. Útil pra detectar regex stale.
- **Planilha vazia (degenerado):** fallback para `nextInvoiceClosingDate_()`. Compra entra na fatura computada de hoje, mas sem despesas fixas (webhook não cria bloco). Usuário deve rodar Nova fatura assim que possível.
- **Última fatura registrada é antiga (ex.: 06/05 e hoje é 26/05):** compra entra em 06/05 (fatura já fechada). Usuário deve rodar Nova fatura para criar 06/06 — depois disso webhook escreve em 06/06.
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
