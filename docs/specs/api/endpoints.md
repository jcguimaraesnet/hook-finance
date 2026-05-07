---
status: stable
last_updated: 2026-05-07
---

# API endpoints

Apps Script único como backend. Frontend (PWA + Flutter) acessa via `/api/proxy` no PWA (Azure Function bridge — ver [proxy.md](proxy.md)) ou via URL direta `https://script.google.com/macros/s/.../exec` no Flutter.

## Contexto

`doGet`/`doPost` em [Dashboard.gs](../../../apps-script/dashboard/Dashboard.gs) despacham por `action`. Webhook (Tasker/IFTTT) reusa o mesmo `doPost` — ver [webhook.md](webhook.md). Todo endpoint exige token (exceto resposta de erro de unknown_action).

## Regras

### Autenticação

- Token único, guardado em `PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN")`.
- Verificado por `checkToken_(token)` em todo endpoint.
- Token é o mesmo do webhook — não há separação entre auth de leitura/escrita/webhook.
- Sem token / token inválido → `{ ok: false, error: "unauthorized" }` (HTTP 200; o erro vem no body).
- `validateToken(candidate)` no PWA testa via `lastEntries(n=1)`.

### GET endpoints (querystring)

| `action` | Params | Resposta | Descrição |
|---|---|---|---|
| `monthData` | `token`, `month?` (`"DD/MM/YYYY"`) | `{ ok, month, rows[] }` | Linhas do mês especificado, ou do mais recente se omitido. |
| `historicalSummary` | `token` | `{ ok, months[], history: { months[], totals[], julioPessoal[], daniPessoal[] } }` | Agregado pré-computado dos últimos 12 meses. |
| `lastEntries` | `token`, `n` (default 10) | `{ ok, entries[] }` | Últimas N linhas inseridas (com `row` 1-indexed para edit/delete). |
| `(none)` ou desconhecido | — | `{ ok: false, error: "unknown_action" }` | Não há landing page; backend é JSON-only. |

### POST endpoints (body JSON, `Content-Type: text/plain` para evitar preflight CORS)

| `body.action` | Body extra | Resposta | Descrição |
|---|---|---|---|
| `updateEntry` | `row` (number, 1-indexed), `fields: { descricao, valor, categoria, rateio, parcela }` | `{ ok, row }` | Edita colunas C(3), D(4), F(6), G(7), I(9). **Não** edita A, B, E, H, J. |
| `deleteEntry` | `row` (number) | `{ ok }` | Remove a linha. |
| `(webhook)` | `title`, `text` | `{ ok }` ou `{ ok: true, deduped: true }` | Caminho legado — ver [webhook.md](webhook.md). |

### Estrutura de `Row` (resposta de `monthData`)

```json
{
  "data": "06/05/2026",
  "dataRef": "03/04/2026 14:32",
  "descricao": "MERCADO ABC",
  "valor": 89.50,
  "origem": "Cartão",
  "categoria": "Alimentação",
  "rateio": "Metade",
  "cardLast4": "1018",
  "parcela": "",
  "acerto": ""
}
```

### Estrutura de `Entry` (resposta de `lastEntries`)

`Row` + campo `row: number` (1-indexed da planilha; necessário para `updateEntry`/`deleteEntry`).

### Estrutura de `historicalSummary.history`

- `months: string[]` — últimos 12 meses **ascendente** (`"DD/MM/YYYY"`).
- `totals: number[]` — total geral por mês, **excluindo** linhas com `origem === "Pessoal"`.
- `julioPessoal: number[]` — soma de `valor` onde `origem === "Cartão"` E `rateio === "Julio"`. Valor cheio (não dividido).
- `daniPessoal: number[]` — soma de `valor` onde `origem === "Cartão"` E `rateio === "Dani"`. Valor cheio.
- Top-level `months` (não `history.months`): **todos** os meses distintos, **descendente** — usado pelo dropdown de filtro do StickyHeader.

## Edge cases

- **Sheet vazia (só headers):** todo endpoint retorna `{ ok: true, ...estrutura vazia... }`. Não erro.
- **`monthData` com `month` que não existe:** retorna `{ ok: true, month: <valor recebido>, rows: [] }`.
- **`monthData` sem `month` E sheet vazia:** retorna `{ ok: true, month: null, rows: [] }`.
- **`updateEntry`/`deleteEntry` com `row < 2`:** `{ ok: false, error: "invalid_row" }`.
- **`updateEntry`/`deleteEntry` com `row > lastRow`:** `{ ok: false, error: "row_out_of_range" }`.
- **`historicalSummary` quando há menos que 12 meses:** retorna o que houver, do mais antigo ao mais recente.
- **Parcela:** `updateEntry` força `setNumberFormat("@")` na célula antes de gravar para impedir Sheets auto-parsear `"1/3"` como data.

## Performance

- `Utilities.formatDate` é caro (IPC por chamada). `getMonthData` e `getHistoricalSummary` cacheiam por `Date.getTime()`. Manter esse padrão em qualquer endpoint que itere linhas.
- `historicalSummary` lê só A..G do slab que cobre 12 meses, não a planilha inteira.
- `lastEntries` lê só as primeiras `n` linhas (planilha é descendente por inserção).

## Implementações

- **Backend (autoritativo):** [apps-script/dashboard/Dashboard.gs](../../../apps-script/dashboard/Dashboard.gs)
- **PWA cliente:** [web/src/api/client.ts](../../../web/src/api/client.ts) + [web/src/api/endpoints.ts](../../../web/src/api/endpoints.ts)
- **PWA proxy:** [web/api/proxy/index.js](../../../web/api/) (Azure Function)
- **PWA hooks (cache layer):** `web/src/hooks/useMonthData.ts`, `useHistoricalSummary.ts`, `useLastEntries.ts`
- **Flutter cliente (futuro):** `app/lib/api/client.dart` + `app/lib/api/endpoints.dart`

## Specs relacionadas

- [proxy.md](proxy.md)
- [webhook.md](webhook.md)
- [../data/despesas-sheet.md](../data/despesas-sheet.md)
