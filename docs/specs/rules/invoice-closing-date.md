---
status: stable
last_updated: 2026-05-26
---

# Invoice closing date — `nextInvoiceClosingDate_` e `newInvoiceClosingDate_`

Duas funções com semântica diferente:

- **`nextInvoiceClosingDate_`** — fatura **atual acumulando** (próxima a fechar). Usada pelo webhook ao gravar uma compra: a compra entra na fatura que ainda está aberta.
- **`newInvoiceClosingDate_`** — fatura **DEPOIS da acumulando**. Usada pelo gatilho manual "Nova fatura" (ver [new-invoice.md](new-invoice.md)) — o usuário cria explicitamente a próxima fatura que ainda nem começou.

## Contexto

A col A não é a data da compra (essa fica em col B, `dataRef`). É o **fechamento da fatura** em que a linha entra.

Ex.: hoje = `26/05/2026`, `INVOICE_CLOSING_DAY = 6`.
- Compras feitas hoje vão para a fatura que fecha em `06/06/2026` (a acumulando). `nextInvoiceClosingDate_` retorna `06/06/2026`.
- "Nova fatura" (manual) cria a fatura que fecha em `06/07/2026` (ainda não começou). `newInvoiceClosingDate_` retorna `06/07/2026`.

A diferença vem do gatilho:
- Webhook reage a um evento real (compra) — a compra precisa entrar na fatura que está acumulando.
- "Nova fatura" antecipa: o usuário cria o esqueleto da próxima fatura para que despesas fixas e parcelas roladas já estejam lá quando essa fatura começar.

## Regras

### `nextInvoiceClosingDate_() → string "DD/MM/YYYY"`

1. `now` = data atual no timezone do script.
2. `year`, `month` = ano/mês atual.
3. `nextMonth = month + 1`. Se `> 12`, `nextMonth = 1`, `nextYear = year + 1`. (Senão `nextYear = year`.)
4. `dd` = `INVOICE_CLOSING_DAY` zero-padded a 2 dígitos.
5. `mm` = `nextMonth` zero-padded.
6. Retorna `"${dd}/${mm}/${nextYear}"`.

### `newInvoiceClosingDate_() → string "DD/MM/YYYY"`

Um mês após `nextInvoiceClosingDate_`:

1. Obtém `current = nextInvoiceClosingDate_()`.
2. `mm = parseInt(current.split("/")[1]) + 1`. Se `> 12`, `mm = 1`, `yyyy += 1`.
3. Retorna `"${dd}/${mm}/${yyyy}"`.

`INVOICE_CLOSING_DAY` é uma constante (atualmente `6`). Trocar de banco/cartão pode exigir ajuste — mudar a constante é o ponto único.

## Edge cases

- **Compra exatamente no dia de fechamento:** segundo essa regra, ainda entra na fatura do mês seguinte. Se na prática o banco trata diferente, o usuário pode editar a col A manualmente; mas o webhook não sabe distinguir.
- **Mudança de timezone do script:** afeta `now`. O timezone é configurado no Apps Script (Project Settings); padrão `America/Sao_Paulo`.
- **Cartão com data de fechamento diferente por bandeira:** não suportado. Mudar a regra para multi-cartão exigiria lookup por `cardLast4` no [card-to-person.md](card-to-person.md). Não está em escopo.

## Implementações

- **Backend (autoritativo):** [apps-script/shared/Helpers.gs](../../../apps-script/shared/Helpers.gs) — ambas as funções.
- **Constante:** [apps-script/shared/Constants.gs](../../../apps-script/shared/Constants.gs) — `INVOICE_CLOSING_DAY`.
- **Flutter:** [app/lib/core/rules/invoice_closing.dart](../../../app/lib/core/rules/invoice_closing.dart) — portas Dart `nextInvoiceClosingDate` e `newInvoiceClosingDate`. Usada pelo dialog de Nova fatura.
- **PWA legacy (React):** N/A.

## Specs relacionadas

- [../api/webhook.md](../api/webhook.md)
- [../data/despesas-sheet.md](../data/despesas-sheet.md) — col A
- [fixed-expenses.md](fixed-expenses.md) — usa o mesmo `invoiceClosing` para detectar fatura nova
- [new-invoice.md](new-invoice.md) — usa `newInvoiceClosingDate_` (semântica diferente do webhook)
