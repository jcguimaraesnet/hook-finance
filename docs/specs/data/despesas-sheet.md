---
status: stable
last_updated: 2026-05-26
---

# Despesas — schema da planilha

Planilha única, aba `Despesas`. Todas as codebases (PWA, Flutter, backend) consomem esse mesmo modelo. Linhas novas são inseridas no **topo** (linha 2 = mais recente).

## Contexto

A planilha é o único banco de dados. Nenhum estado vive fora dela (exceto cache transitório do CacheService para dedup do webhook). Schema estável desde o início; mudanças aqui exigem migração da planilha **antes** de mexer no código.

## Regras

### Colunas (10 total)

| # | Letra | Header | Tipo | Notas |
|---|-------|--------|------|-------|
| 1 | A | Data | Date (formato `dd/MM/yyyy`) | Fechamento da fatura. Webhook usa `latestInvoiceClosingInSheet_(sheet)` (mais recente já registrada). Nova fatura usa `newInvoiceClosingDate_()`. Backend sempre escreve `Date` object + force `setNumberFormat("dd/MM/yyyy")`. Reads usam `formatBrDate_` que aceita Date OU string (compatível com linhas legadas). |
| 2 | B | Data Referência | string `DD/MM/YYYY HH:MM` | Data+hora real da compra (extraída do texto da notificação). |
| 3 | C | Descrição | string | Estabelecimento. Extraído via `PURCHASE_RE`. |
| 4 | D | Valor | number | Numérico, com 2 casas. Pode ser negativo (estornos, ajustes). |
| 5 | E | Origem | string enum | `Cartão` \| `Pix (contas)` \| `Pessoal` \| `Empregados` \| `Contas`. Webhook **sempre** escreve `Cartão` (constante `ORIGEM`). |
| 6 | F | Categoria | string | Texto livre. Sugerido por `Classifier` (Jaccard). Comuns: `Alimentação`, `Pessoal`, `Contas`, `Saúde`. |
| 7 | G | Rateio | string | `Julio` \| `Dani` \| `Metade` \| `Alzira` \| `""`. Vazio = não rateado. |
| 8 | H | Cartão | string `XXXX` | Últimos 4 dígitos. Mapping em [card-to-person.md](../rules/card-to-person.md). |
| 9 | I | Parcela | string | `"X/Y"` (ex.: `"1/3"` = 1ª de 3). Vazio = à vista. Editável só via modal de Lançamento. Ver [parcela-format.md](../rules/parcela-format.md). |
| 10 | J | Acerto | string | `"Sim"` se a linha conta para o "Acerto Final". Vazio caso contrário. |

### Leitura

- Linha 1 = headers; ignorar ao processar dados.
- Tipos de retorno do backend (`mapRow_`) são todos string exceto `valor` que é number — ver [api/endpoints.md](../api/endpoints.md).
- Para `Parcela` ler `String(r[8] || "").trim()` (formato preservado como texto).
- Para `Acerto` ler `String(r[9] || "")`.

### Inserção

- Webhook insere no **topo** (`insertRowsBefore(2, n)`), não no fim.
- Bloco de "início de fatura" (despesas fixas + linha azul + rollover de parcelas) é criado **apenas** pelo gatilho manual Nova fatura — ver [../rules/new-invoice.md](../rules/new-invoice.md). Webhook não cria mais bloco; só grava a compra na última fatura existente.
- Coluna A (Data) é Date object. Force `setNumberFormat("dd/MM/yyyy")` após inserção pra sobrescrever `@` que pode ter sido herdado de `updateEntry` em linha vizinha.
- O write em coluna `I (Parcela)` deve forçar `setNumberFormat("@")` antes do `setValue` para impedir o Sheets de auto-parsear `"1/3"` como data.

## Edge cases

- **Linha sem data** (col A vazia): pode aparecer em blocos brancos do "Fixed expenses block". Backend filtra com `if (!d) continue` em loops por mês.
- **Valor negativo:** legítimo (ajustes/estornos como `Ajuda de custo`). Não filtrar.
- **Rateio em branco + Origem Cartão:** linha aparece em `RateioChart` como `"(sem rateio)"`. Não bate com nenhuma regra de splitForPerson, então não aparece nos PersonCard.
- **`Cartão` (col H) vazio:** não usado por nenhuma regra de UI; só informativo.
- **Sheet vazia (só headers):** backend retorna `{ ok: true, rows: [] }`.

## Implementações

- **Backend (autoritativo):**
  - [apps-script/dashboard/Dashboard.gs:294-307](../../../apps-script/dashboard/Dashboard.gs) — `mapRow_(r)` define o contrato linha → JSON.
  - [apps-script/shared/Constants.gs](../../../apps-script/shared/Constants.gs) — `SHEET_ID`, `SHEET_NAME`, `INVOICE_CLOSING_DAY`, `ORIGEM`, `CARDS`.
- **PWA tipos:** `web/src/core/types.ts` (após Onda 2; hoje em `web/src/api/types.ts`).
- **Flutter tipos:** `app/lib/core/types.dart` (após Onda 4).

## Specs relacionadas

- [../api/endpoints.md](../api/endpoints.md) — formato de leitura via REST
- [../rules/parcela-format.md](../rules/parcela-format.md) — interpretação de `"X/Y"`
- [../rules/card-to-person.md](../rules/card-to-person.md) — mapping de col H
- [../rules/fixed-expenses.md](../rules/fixed-expenses.md) — inserção automática
