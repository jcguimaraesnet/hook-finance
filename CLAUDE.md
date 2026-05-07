# hook-finance — Project Notes for Claude

Personal finance monorepo. Backend is Google Apps Script (REST + webhook); frontend is a React PWA hosted on Azure Static Web Apps; an Azure Function proxy bridges the two. All data lives in a single Google Sheet.

## Monorepo (pnpm workspace)

```
hook-finance/
├── apps-script/                # Backend GAS (REST dispatcher + webhook)
├── web/                        # React PWA (Vite + TS + Tailwind v4)
├── web/api/                    # Azure Function /api/proxy (CORS bridge)
├── .github/workflows/
│   ├── deploy-apps-script.yml  # clasp push + deploy on push to main
│   └── deploy-web.yml          # Azure SWA build + deploy
├── pnpm-workspace.yaml
└── package.json                # root scripts: dev, build, preview, lint
```

Use `pnpm install` at root to install all packages. `pnpm dev` runs the React PWA dev server.

## Architecture

- **Backend** (`apps-script/`): single `doGet` and `doPost` global handlers in [Dashboard.gs](apps-script/dashboard/Dashboard.gs) dispatch by `?action=` (GET) or `body.action` (POST). Webhook (Tasker/IFTTT) reuses the same `doPost` — when body has `title`+`text`, delegates to `handleWebhookBody_` in [Webhook.gs](apps-script/webhook/Webhook.gs). The legacy HTML frontend was removed in Phase G cutover; `GET /exec` with no `action` returns `{ok:false,error:"unknown_action"}`.
- **Frontend PWA** (`web/`): React 18 + TypeScript + Vite 5 + Tailwind v4 (CSS-first via `@theme`) + vite-plugin-pwa (manifest + workbox SW with NetworkFirst cache for `/api/proxy?action=monthData|historicalSummary`) + React Router v7 + Zustand (persist token/UI prefs) + Tanstack Query (data) + Chart.js + react-chartjs-2 (charts).
- **API proxy** (`web/api/`): single Azure Function v4 at `/api/proxy` (GET + POST). Forwards to `APPS_SCRIPT_URL` (env var); returns body verbatim. Hosted by Azure SWA same-origin so the React app calls `/api/proxy` without CORS.
- **Deploy**:
  - Apps Script: GH Action `deploy-apps-script.yml` runs `clasp push -f` + `clasp deploy -i <PROD_ID>` on push to `main` when `apps-script/**` or related files change.
  - Web PWA: GH Action `deploy-web.yml` runs `pnpm build` for `web` + `web/api`, then uses `Azure/static-web-apps-deploy@v1` (token in secret `AZURE_STATIC_WEB_APPS_API_TOKEN`).
  - Local clasp: `./node_modules/.bin/clasp.cmd push -f` on Windows.

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

When reading from the sheet, use `String(r[8] || "")` for Parcela (string format) and `String(r[9] || "")` for Acerto. To extract the total of installments from `"X/Y"`, use the client-side helper `parcelaTotal(p)` in [web/src/utils/format.ts](web/src/utils/format.ts). A row counts as "parcelado" when its Parcela field is non-empty.

## Person-card aggregation rules

These are the canonical rules for how each row's `valor` rolls into the labels shown on the PersonCard / AcertoCard / RateioChart / HistoricoChart "Pessoal". The grouping key is **`rateio`** (column G), not `categoria`. `categoria` is irrelevant for these rules.

For the **selected month's invoice** (filtered by column A = invoice closing date):

| UI label | Filter rule | Value attributed to Júlio | Value attributed to Dani |
|---|---|---|---|
| **Cartão (compartilhado)** | `origem = Cartão` AND `rateio = Metade` | `valor / 2` | `valor / 2` |
| **Cartão (pessoal)** | `origem = Cartão` AND `rateio ∈ {Julio, Dani}` | `valor` if `rateio = Julio`, else `0` | `valor` if `rateio = Dani`, else `0` |

Every component below must follow these rules:

- **PersonCard** ([web/src/components/PersonCard.tsx](web/src/components/PersonCard.tsx)) on Consulta — rows "Cartão (compartilhado)" and "Cartão (pessoal)".
- **AcertoCard** ([web/src/pages/AcertoPage.tsx](web/src/pages/AcertoPage.tsx)) — rows "Cartão (compartilhado)" and "Cartão (pessoal)".
- **RateioChart** ([web/src/components/RateioChart.tsx](web/src/components/RateioChart.tsx)) "Cartão (por pessoa)" — bar `Compartilhado` follows rule 1; bars `Júlio`/`Dani` follow rule 2.
- **HistoricoChart** "Histórico — Pessoal" series — same as rule 2 (sum of Cartão rows where `rateio ∈ {Julio, Dani}`, attributed to that person).

The shared splitter [web/src/utils/splitForPerson.ts](web/src/utils/splitForPerson.ts) already encodes the per-person value math (full when `rateio === person`, half when `rateio === Metade`, else 0). What the components must NOT do is bucket by `categoria`; bucket by `rateio` instead.

## Backend REST endpoints (called via `/api/proxy` from the PWA)

- `GET ?action=monthData&token&month?` → rows of the specified month (or most recent if omitted).
- `GET ?action=historicalSummary&token` → pre-aggregated 12-month totals + months list. Reads only cols A,D,E,F,G.
- `GET ?action=lastEntries&token&n` → last N rows for the Lançamento list (with `row` index for editing).
- `POST { action:"updateEntry", token, row, fields }` → writes cols 3, 4, 6, 7, 9 (descricao, valor, categoria, rateio, parcela).
- `POST { action:"deleteEntry", token, row }` → removes a row.
- `GET /exec` (no `action`) → `{ ok: false, error: "unknown_action" }`. The legacy HTML dashboard was removed and there is no public landing page; the backend is JSON-only.
- `POST { title, text, token }` → webhook path (Tasker/IFTTT) handled by `handleWebhookBody_`.

All endpoints validate the token via `checkToken_(token)` against `PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN")`.

Optimization: `Utilities.formatDate` is expensive (per-call IPC). For functions that loop over many rows, cache by `Date.getTime()` — see `getMonthData` in [Dashboard.gs](apps-script/dashboard/Dashboard.gs).

## Frontend structure (PWA — `web/`)

React Router routes: `/consulta`, `/detalhe`, `/lancamento`, `/acerto`. Consulta has sub-tabs (Mês / Categoria / Pessoal / Histórico) on viewports below PC.

### Responsive breakpoints

- **Mobile** (`<640px`): bottom-fixed primary nav; Consulta sub-tabs visible; cards stack 1-col; HistoricoChart shows last 6 months only.
- **Tablet** (`640–749px`): top primary nav (sticky alongside the 4 tiles); Consulta sub-tabs; cards 2-col; body max-width 880px centered.
- **PC Web** (`≥750px`): top primary nav; Consulta **without sub-tabs** (all panels visible at once); cards 2-col.

Acerto Final cards always stack on mobile and go 2-col from tablet+ matching Consulta person cards exactly.

### Persisted state

- **Zustand `hook-finance-store` (localStorage)**: `token`, `activePage`, `activeTab`, `acertoPixJulio`. `currentMonth` and `allMonths` are session-only (not persisted).
- **`hook-finance-diff-{Julio,Dani}` (sessionStorage)**: Δ toggle visibility per person; default true (visible). Survives reloads in the same tab; resets when the tab closes.
- **`hook-finance-install-dismissed` (localStorage)**: `1` once user dismisses the install banner; suppresses it on subsequent visits.

### Loading flow

1. Login screen calls `validateToken(candidate)` (probes `lastEntries(n=1)`); only stores token if `ok: true`.
2. After login, `StickyHeader` (hoisted to AppShell) fetches `monthData` for `currentMonth`. Tiles render with skeleton fallback.
3. ConsultaPage fetches `historicalSummary` in background → populates `allMonths` + history charts.
4. The shared StickyHeader instance persists across Consulta/Detalhe/Acerto navigations; Lançamento gets a separate disabled instance pinned to the latest invoice month.

### Charts

Chart.js v4 + `chartjs-plugin-datalabels`. `moneyK(v)` for compact ticks (e.g., `2k`, `1,5k`). HistoricoChart: tooltip mode `index` with a custom dashed vertical hover-line plugin; Y-axis ticks alternate (every other one). RateioChart: name label inside each bar (white), value outside at the right (dark).

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
