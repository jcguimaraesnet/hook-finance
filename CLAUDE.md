# hook-finance — Project Notes for Claude

Personal finance dashboard built as a Google Apps Script web app + webhook. All data lives in a single Google Sheet; the web app reads/writes to it via Apps Script.

## Architecture

- **Backend** (`src/dashboard/Dashboard.gs`, `src/webhook/*.gs`, `src/shared/*.gs`): Apps Script `.gs` files. Exposed functions (no trailing underscore) are callable from the client via `google.script.run`.
- **Frontend** (`src/dashboard/Index.html`, `Stylesheet.html`, `Script.html`): single page rendered server-side via `HtmlService.createTemplateFromFile`. Includes via `include_('dashboard/Stylesheet')` etc.
- **Webhook** (`src/webhook/Webhook.gs`): receives POSTs from a phone notification automation (Tasker/IFTTT) on credit card purchases; classifies via [Classifier](src/webhook/Classifier.gs) and inserts at top via [Helpers.insertRowsAtTop_](src/shared/Helpers.gs).
- **Deploy**: GitHub Action triggered on push to `main` → `clasp push -f` + `clasp deploy -i <PROD_DEPLOYMENT_ID>` ([.github/workflows/deploy.yml](.github/workflows/deploy.yml)). Local development: `./node_modules/.bin/clasp.cmd push -f` (use `.cmd` on Windows; clasp not installed globally).

## Spreadsheet schema (`Despesas` sheet)

Columns A–J (10 columns). Rows are inserted at the top (row 2 = newest).

| # | Header | Notes |
|---|---|---|
| A (1) | Data | Invoice closing date `DD/MM/YYYY`. Set by webhook via `nextInvoiceClosingDate_()`. |
| B (2) | Data Referência | Purchase date+time `DD/MM/YYYY HH:MM` parsed from notification text. |
| C (3) | Descrição | Establishment name extracted via `PURCHASE_RE`. |
| D (4) | Valor | Numeric. |
| E (5) | Origem | `Cartão`, `Pix (contas)`, `Pessoal`, `Empregados`, `Contas`. Webhook always writes `Cartão` (the constant `ORIGEM`). |
| F (6) | Categoria | Free-text. Inferred via `Classifier` (Jaccard similarity). Common values: `Alimentação`, `Pessoal`, `Contas`, `Saúde`, etc. |
| G (7) | Rateio | `Julio`, `Dani`, `Metade`, `Alzira`, or empty. |
| H (8) | Cartão | Last 4 digits. `1018`, `9727` → Julio; `4750`, `0784` → Dani. |
| I (9) | Parcela | String no formato `parcela_atual/total` (ex: `1/3` = 1ª parcela de 3). Vazio quando à vista. Editável via Lançamento tab — o stepper edita só o total; a parcela atual é sempre gravada como `1`. |
| J (10) | Acerto | `Sim` if the row counts in "Acerto Final" tab. Otherwise empty. |

When reading from the sheet, use `String(r[8] || "")` for Parcela (string format) and `String(r[9] || "")` for Acerto. To extract the total of installments from `"X/Y"`, use the client-side helper `parcelaTotal_(p)` in [Script.html](src/dashboard/Script.html). A row counts as "parcelado" when its Parcela field has total `> 1`.

## Backend exposed endpoints (callable via `google.script.run`)

- `getMonthData(token, month?)` — returns rows of the most recent month (or specified month).
- `getHistoricalSummary(token)` — pre-aggregated 12-month totals + months list. Reads only cols A,D,E,F,G.
- `getLastEntries(token, n)` — last N rows for the Lançamento list (with `row` index for editing).
- `updateEntry(token, row, fields)` — writes cols 3, 4, 6, 7, 9 (descricao, valor, categoria, rateio, parcela).
- `deleteEntry(token, row)` — removes a row.

All endpoints validate the token via `checkToken_(token)` against `PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN")`.

Optimization: `Utilities.formatDate` is expensive (per-call IPC). For functions that loop over many rows, cache by `Date.getTime()` — see `getMonthData` in [Dashboard.gs](src/dashboard/Dashboard.gs).

## Frontend structure (`Script.html`)

Single-page app with primary nav (Consulta / Detalhe / Lançamento / Acerto Final) and, inside Consulta, sub-tabs (Mês / Categoria / Pessoal / Histórico).

### Responsive breakpoints

- **Mobile** (`<640px`): bottom-fixed primary nav; Consulta sub-tabs visible; cards stack 1-col.
- **Tablet** (`640–749px`): top primary nav; Consulta sub-tabs; cards 2-col; body max-width 880px centered.
- **PC Web** (`≥750px`): top primary nav; Consulta **without sub-tabs** (all panels visible at once); cards 2-col; body max-width 880px.

Acerto Final cards are **always 2-col side-by-side** regardless of viewport.

### State (localStorage keys)

- `hook-finance-token` — webhook token for authenticated requests.
- `hook-finance-tab` — last active sub-tab in Consulta.
- `hook-finance-page` — last active primary nav page.
- `hook-finance-diff-{julio,dani}` — Δ button toggle state per person.

### Loading flow

1. Skeleton renders immediately.
2. `getMonthData(token)` (most recent month) → render Consulta tiles + cards.
3. `getHistoricalSummary(token)` in background → render history charts + populate selector with all 12 months.
4. Charts are lazy-rendered: only drawn when their sub-tab becomes active (or always in PC Web).

### Charts

Chart.js v4 + `chartjs-plugin-datalabels`. Use `moneyK_(v)` for compact axis ticks (e.g., `2k`, `1,5k`). For line charts, x-axis ticks alternate (every other label visible) and format as `MM/YYYY`.

## Conventions

- All UI text in pt-BR.
- Money formatted via `Money` (`Intl.NumberFormat pt-BR`); display as `R$ X` (prefix added inline).
- Internal data keys (e.g., `byOrigem`) match the column value verbatim (e.g., `"Pix (contas)"`, not a renamed alias).
- Functions ending in `_` are private to Apps Script (not exposed via `google.script.run`).
- Comments only when WHY is non-obvious; never describe WHAT the code does.

## Plan + spec docs

- Plans go in `.claude/plans/YYYY-MM-DD-<feature>.md`.
- Specs go in `.claude/specs/YYYY-MM-DD-<feature>-design.md`.
- `.superpowers/` is gitignored (visual brainstorming workspace).
