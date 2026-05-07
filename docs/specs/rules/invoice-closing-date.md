---
status: stable
last_updated: 2026-05-07
---

# Invoice closing date — `nextInvoiceClosingDate_`

Calcula a data de fechamento da **próxima** fatura, usada para preencher a col A (Data) de toda compra de Cartão.

## Contexto

A col A não é a data da compra (essa fica em col B, `dataRef`). É o **fechamento da fatura** em que essa compra entra. Toda compra do mês corrente entra na fatura que fecha **no mês seguinte**, no dia configurado por `INVOICE_CLOSING_DAY`.

## Regras

`nextInvoiceClosingDate_() → string "DD/MM/YYYY"`:

1. `now` = data atual no timezone do script.
2. `year`, `month` = ano/mês atual.
3. `nextMonth = month + 1`. Se `> 12`, `nextMonth = 1`, `nextYear = year + 1`. (Senão `nextYear = year`.)
4. `dd` = `INVOICE_CLOSING_DAY` zero-padded a 2 dígitos.
5. `mm` = `nextMonth` zero-padded.
6. Retorna `"${dd}/${mm}/${nextYear}"`.

`INVOICE_CLOSING_DAY` é uma constante (atualmente `6`). Trocar de banco/cartão pode exigir ajuste — mudar a constante é o ponto único.

## Edge cases

- **Compra exatamente no dia de fechamento:** segundo essa regra, ainda entra na fatura do mês seguinte. Se na prática o banco trata diferente, o usuário pode editar a col A manualmente; mas o webhook não sabe distinguir.
- **Mudança de timezone do script:** afeta `now`. O timezone é configurado no Apps Script (Project Settings); padrão `America/Sao_Paulo`.
- **Cartão com data de fechamento diferente por bandeira:** não suportado. Mudar a regra para multi-cartão exigiria lookup por `cardLast4` no [card-to-person.md](card-to-person.md). Não está em escopo.

## Implementações

- **Backend (autoritativo):** [apps-script/shared/Helpers.gs:40-54](../../../apps-script/shared/Helpers.gs)
- **Constante:** [apps-script/shared/Constants.gs](../../../apps-script/shared/Constants.gs) — `INVOICE_CLOSING_DAY`.
- **PWA / Flutter:** N/A.

## Specs relacionadas

- [../api/webhook.md](../api/webhook.md)
- [../data/despesas-sheet.md](../data/despesas-sheet.md) — col A
- [fixed-expenses.md](fixed-expenses.md) — usa o mesmo `invoiceClosing` para detectar fatura nova
