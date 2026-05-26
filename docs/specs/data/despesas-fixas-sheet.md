---
status: stable
last_updated: 2026-05-26
---

# Despesas-fixas — schema da aba

Aba de configuração na mesma planilha. Contém o template das despesas que o backend insere automaticamente no topo de `Despesas` na primeira compra de cartão de cada fatura nova. Spec da regra: [../rules/fixed-expenses.md](../rules/fixed-expenses.md).

## Contexto

Antes era constante hard-coded (`FIXED_EXPENSES` em `apps-script/webhook/FixedExpenses.gs`). Migrado para aba em 2026-05-26 para permitir edição sem deploy. Lida em `loadFixedExpenses_()` toda vez que uma fatura nova começa.

## Regras

### Colunas (7 total)

| # | Letra | Header | Tipo | Validação |
|---|-------|--------|------|-----------|
| 1 | A | `Dia` | number int | 1–31 |
| 2 | B | `Descrição` | string | não-vazia |
| 3 | C | `Valor` | number | qualquer (negativos legítimos para ajustes/estornos) |
| 4 | D | `Origem` | string | não-vazia (atualmente todas `Pix (contas)`) |
| 5 | E | `Categoria` | string | não-vazia (atualmente todas `Contas`) |
| 6 | F | `Rateio` | string enum | `Julio` \| `Dani` \| `Metade` \| `Alzira` |
| 7 | G | `Acerto` | string | `""` \| `"Sim"` |

### Leitura

- Linha 1 = headers. Backend lê de `A2:G{last}`.
- Toda linha é validada — qualquer violação lança erro com prefixo `despesas-fixas L{N}:` e webhook retorna 500.
- A ordem das linhas na aba determina a ordem visual do bloco inserido na aba `Despesas`.

### Escrita

- Edição manual via Google Sheets.
- Função utilitária `seedFixedExpenses_()` em `apps-script/webhook/FixedExpenses.gs` popula a aba inicialmente. Idempotente — aborta se a aba já tem dados.

## Edge cases

- **Aba ausente:** `loadFixedExpenses_()` lança `aba "despesas-fixas" não existe`.
- **Aba só com headers:** lança `aba "despesas-fixas" está vazia`.
- **Linha malformada (qualquer campo):** lança erro identificando o número da linha e o campo. Webhook 500 — primeira compra da fatura não entra até a aba ser corrigida.
- **`Valor = 0`:** legítimo (linha placeholder, ex.: `"Condomínio 1/2"` da Dani). Inserida igual; não polui totais.
- **Linhas em branco no meio:** quebram a leitura (cair em validação de `dia`). Manter sem linhas em branco entre dados.

## Implementações

- **Backend (autoritativo):** [apps-script/webhook/FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs) — `loadFixedExpenses_()` lê e valida; `seedFixedExpenses_()` popula one-shot.
- **Constante do nome da aba:** `FIXED_SHEET_NAME` em [apps-script/shared/Constants.gs](../../../apps-script/shared/Constants.gs).

## Specs relacionadas

- [../rules/fixed-expenses.md](../rules/fixed-expenses.md) — regra de inserção automática.
- [despesas-sheet.md](despesas-sheet.md) — aba destino das linhas geradas.
