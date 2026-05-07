---
status: stable
last_updated: 2026-05-07
---

# Fixed expenses — inserção mensal automática

Despesas recorrentes (Diarista, Plano de Saúde, Creche, etc.) são inseridas automaticamente na primeira compra de Cartão de cada fatura nova.

## Contexto

O usuário não precisa lançar manualmente despesas que ele sabe que vão acontecer todo mês. O webhook detecta "estou inserindo a primeira compra desta fatura nova" e antes disso insere o bloco de despesas fixas. Esse bloco também marca visualmente o início da fatura na planilha (linha azul).

## Regras

### Trigger

`appendMonthlyFixedIfNeeded_(sheet, invoiceClosing)` é chamado **dentro** de `handleWebhookBody_`, antes de inserir a linha da compra atual.

1. Lê todas as linhas existentes (cols A..E).
2. Se já existe alguma linha com `data === invoiceClosing` E `origem === "Cartão"` → **return** (não duplica).
3. Senão → insere o bloco abaixo no topo da planilha.

### Bloco inserido

Composto pelo array `FIXED_EXPENSES` em [FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs). Cada item:

```js
{
  refDay: <1-31>,
  description: <string>,
  value: <number>,
  origem: "Pix (contas)",
  categoria: "Contas",
  rateio: "Julio" | "Dani",
  acerto?: "Sim",  // se omitido = ""
}
```

Para cada item, o backend constrói uma row:

| Col | Valor |
|-----|-------|
| A | `invoiceClosing` (mesmo da compra que disparou) |
| B | `${dd}/${mm}/${yyyy}` onde `dd = refDay`, `mm/yyyy` = mês/ano da fatura |
| C | `description` |
| D | `value` |
| E | `origem` (sempre `"Pix (contas)"` na lista atual) |
| F | `categoria` |
| G | `rateio` |
| H | `""` (n/a para Pix) |
| I | `""` (despesas fixas nunca são parceladas) |
| J | `acerto || ""` |

### Layout no sheet

Bloco final inserido (top-down):

```
[blank row]
[fixed expense 1]
...
[fixed expense N]
[blank row]
[blank row — pintada de azul (#cfe2f3) para sinalizar início da fatura visualmente]
[blank row]
```

Inserido via `insertRowsBefore(2, block.length)` + `setValues`. Linha azul vai na **penúltima** posição do bloco — no código atual `block.length`, que com o offset de inserção a partir da linha 2 cai exatamente nessa posição.

### Lista atual de despesas fixas

| description | refDay | value | rateio | acerto |
|---|---|---|---|---|
| Diarista | 6 | 1500 | Dani | |
| Plano de Saúde (Dani) | 6 | 761,81 | Dani | |
| Plano de Saúde (Julio) | 6 | 761,81 | Julio | Sim |
| Mensalidade creche 1/2 | 7 | 1741,40 | Dani | Sim |
| Mensalidade creche 2/2 | 7 | 1741,40 | Julio | Sim |
| Ajuda de custo (Creche) | 5 | -620 | Dani | |
| Claro Internet | 6 | 0,01 | Dani | |
| Gás | 5 | 120,42 | Dani | Sim |
| Condomínio 1/2 | 10 | 1550 | Julio | Sim |
| Condomínio 1/2 | 10 | 0 | Dani | |
| Energia (débito automático) | 7 | 500 | Dani | |
| Guia de Previdência Social | 15 | 1300 | Julio | |
| Guia de Previdência Social (...) | 15 | 1300 | Dani | |
| Dízimo | 5 | 500 | Julio | |
| Dízimo | 5 | 500 | Dani | |

Mudanças nessa lista refletem na próxima fatura inserida. Não retroativo.

## Edge cases

- **Webhook chama duas vezes próximas (replay):** dedup do webhook ([webhook-dedup.md](webhook-dedup.md)) bloqueia o segundo. Se passar do dedup, `appendMonthlyFixedIfNeeded_` ainda checa por linha existente da mesma fatura/origem — não duplica.
- **Primeira compra de uma fatura é a 2ª compra do dia da fatura anterior:** edge raro; o filtro `data === invoiceClosing` casa só pela fatura atual, então o gating funciona.
- **Refday no fim do mês ausente** (ex.: refDay=31 em fevereiro): hoje gera string `"31/02/yyyy"` (inválido como data, mas válido como string). Funciona porque a col B é tratada como string. Tratamento ideal seria clamp para último dia válido do mês — não está implementado.
- **`value = 0`** (linha placeholder, ex. `"Condomínio 1/2 (Dani)"`): inserida igual; não polui totais (zero).

## Implementações

- **Backend (autoritativo):** [apps-script/webhook/FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs)
- **PWA / Flutter:** N/A (write-only do backend).

## Specs relacionadas

- [../api/webhook.md](../api/webhook.md)
- [invoice-closing-date.md](invoice-closing-date.md)
- [../data/despesas-sheet.md](../data/despesas-sheet.md)
