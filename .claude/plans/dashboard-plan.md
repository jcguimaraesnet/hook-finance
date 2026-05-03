# Plano — Dashboard HTML no Apps Script (hook-finance)

## Context

O webhook `hook-finance` já grava compras de cartão e despesas fixas mensais numa Google Sheet com colunas `Data | Data Referência | Descrição | Valor | Origem | Categoria | Rateio`. O usuário hoje consome esses dados num Looker Studio com KPIs/tabelas/gráficos pré-montados, mas quer migrar para uma página HTML hospedada no próprio Apps Script (Web App, mesma URL do webhook). Motivos: não criar infra nova, reaproveitar autenticação por token, manter tudo num só projeto/repo. A página replica o dashboard atual do Looker (imagem fornecida pelo usuário) com filtro de fatura, KPIs por pessoa, tabelas de breakdown e dois gráficos.

## Decisões (confirmadas com o usuário)

- **Auth**: mesmo `WEBHOOK_TOKEN` já existente (Script Properties). Página guarda em `localStorage` após primeira entrada manual; sem token → tela de login simples.
- **URL**: mesmo deployment `/exec`. `doGet(e)` faz branching:
  - `?action=data` → JSON com todas as linhas da planilha (validado por token).
  - sem parâmetros → renderiza HTML.
- **Frontend**: HTML estático servido por `HtmlService` + Chart.js via CDN (`cdn.jsdelivr.net`). Vanilla JS, sem build step. Aggregations todas client-side (volume baixo: ~20 linhas/fatura × 12 meses = ~240 linhas).
- **Layout**: réplica fiel da imagem do Looker enviada pelo usuário (ignorando o seletor de período da direita).

## Layout do dashboard (baseado na imagem)

```
┌──────────────────────────────────────────────────────────────┐
│ [Filtro Data ▾]  [Total cartão]  [Total parcelado]           │
├───────────────────────────┬──────────────────────────────────┤
│ Tabela "Júlio"            │ Tabela "Dani"                    │
│ Subtotal contas    R$  %  │ Subtotal cartão    R$  %         │
│ Subtotal cartão    R$  %  │ Subtotal contas    R$  %         │
│ Subtotal pessoal   R$  %  │ Subtotal pessoal   R$  %         │
│ Subtotal empregad. R$  %  │ Subtotal empregad. R$  %         │
│ Total geral        R$ 100 │ Total geral        R$ 100        │
│ [Cart/Cont] [Cart/Cont/Pes] [Diff Júlio]                     │
│ [Cart/Cont] [Cart/Cont/Pes] [Diff Dani]                      │
├───────────────────────────┬──────────────────────────────────┤
│ Cartão (por categoria)    │ Cartão (por pessoa)              │
│ Categoria | VlrCheio | Vlr│ [bar chart horizontal]           │
│ Mercado   | ...      | %  │ Metade ████████████              │
│ Viagem    | ...      | %  │ Dani   ███                       │
│ ...                       │ Julio  ██                        │
│                           │ Alzira █                         │
├──────────────────────────────────────────────────────────────┤
│ Histórico - Despesas Compartilhadas Totais                   │
│ [line chart: x=fatura, y=ValorCheio, sem Pessoal]            │
└──────────────────────────────────────────────────────────────┘
```

### Regras de agregação observadas na imagem

- **Filtro Data**: data de fechamento (coluna A). Default = mais recente.
- **Total cartão**: soma `Valor` onde `Origem=Cartão` na fatura selecionada.
- **Total parcelado**: marcador para futuro (não temos coluna de "parcelas" hoje — fica como placeholder ou somatório das compras com `Descrição` contendo padrão de parcelamento; a definir na implementação, default `0`).
- **Tabelas Júlio/Dani**: para cada origem (Contas, Cartão, Pessoal, Empregados):
  - Soma `Valor` distribuído pela regra de Rateio:
    - `Julio` → 100% Júlio
    - `Dani` → 100% Dani
    - `Metade` → 50% Júlio, 50% Dani
    - `Alzira` → 0 Júlio, 0 Dani (linha não conta nesta tabela; aparece em "Cartão por pessoa")
    - Outros (`Fernanda`, etc.) → 0 nas tabelas Júlio/Dani
  - `%` = subtotal / total geral da pessoa.
- **KPIs sob cada tabela**:
  - `Cartão/Contas` = soma das origens Cartão+Contas+Empregados (a imagem mostra essa soma incluindo Empregados — confirmar com usuário se for outra fórmula).
  - `Cartão/Contas/Pessoal` = `Cartão/Contas` + Pessoal.
  - `Diff` = `Cartão/Contas` Júlio − `Cartão/Contas` Dani (assinatura inversa para Dani).
- **Cartão (por categoria)**: filtra `Origem=Cartão`, agrupa por `Categoria`, ordena por % desc.
  - `ValorCheio` = soma do Valor sem aplicar Rateio.
  - `Valor` = soma do Valor após aplicar Rateio (acumula a parcela "compartilhada" — provavelmente a metade quando Rateio=Metade, valor inteiro quando Rateio=Julio/Dani).
  - `%` sobre `ValorCheio`.
- **Cartão (por pessoa)**: filtra `Origem=Cartão`, agrupa por `Rateio`, soma `Valor`. Bar chart horizontal ordenado desc.
- **Histórico**: agrupa por `Data` (fechamento), exclui `Origem=Pessoal`, soma `ValorCheio`. Line chart com até N últimas faturas (default 6).

> Observação: as fórmulas exatas do Looker (especialmente "Cartão/Contas" e a divisão `ValorCheio`/`Valor`) podem precisar de pequenos ajustes após o primeiro teste comparando com o Looker. Vamos espelhar o que a imagem sugere e iterar.

## Estrutura de arquivos

Reorganização para separar **webhook**, **dashboard** e código **compartilhado** em subpastas. clasp suporta subpastas dentro de `rootDir`: os arquivos viram `webhook/Code`, `dashboard/Index` etc. no editor do Apps Script (flat namespace, mas nomes prefixados, e a UI nova do editor agrupa como pastas). Tudo continua no mesmo deployment porque Apps Script roda todos os `.gs` no mesmo escopo global.

```
src/
├── appsscript.json                    # manifest (na raiz, exigido pelo clasp)
├── shared/
│   ├── Constants.gs                   # SHEET_ID, SHEET_NAME, ORIGEM, INVOICE_CLOSING_DAY
│   ├── Helpers.gs                     # jsonResponse_, formatBrDate_, parseBrazilNumber_, normalizeDate_, nextInvoiceClosingDate_
│   └── Setup.gs                       # setupToken (config manual no editor)
├── webhook/
│   ├── Webhook.gs                     # doPost, parsePurchase_, PURCHASE_RE
│   └── FixedExpenses.gs               # FIXED_EXPENSES + appendMonthlyFixedIfNeeded_
└── dashboard/
    ├── Dashboard.gs                   # doGet, getDataJson_, include_
    ├── Index.html
    ├── Stylesheet.html                # <style>...</style>
    └── Script.html                    # <script>...</script>
```

### Movimentação a partir da estrutura atual

- `src/Code.gs` é dividido:
  - `SHEET_ID`, `SHEET_NAME`, `ORIGEM`, `INVOICE_CLOSING_DAY` → `shared/Constants.gs`.
  - `jsonResponse_`, `formatBrDate_`, `parseBrazilNumber_`, `normalizeDate_`, `nextInvoiceClosingDate_` → `shared/Helpers.gs`.
  - `setupToken` → `shared/Setup.gs`.
  - `doPost`, `parsePurchase_`, `PURCHASE_RE` → `webhook/Webhook.gs`.
  - `appendMonthlyFixedIfNeeded_` → `webhook/FixedExpenses.gs` (junta com o `FIXED_EXPENSES` que já mora lá).
- `src/FixedExpenses.gs` → `src/webhook/FixedExpenses.gs`.
- Novos arquivos: tudo dentro de `dashboard/`.

> Apps Script só aceita `.gs`, `.html` e `appsscript.json`. `Stylesheet.html` e `Script.html` são wrappers `<style>...</style>` e `<script>...</script>`, incluídos via `include_('dashboard/Stylesheet')` no template do `Index.html`.

### Atenções na migração

- `include_()` precisa usar o nome completo: `include_('dashboard/Stylesheet')`.
- `HtmlService.createTemplateFromFile('dashboard/Index')` no `doGet`.
- Nada de `import`/`require`: o namespace global do Apps Script junta tudo automaticamente, então `jsonResponse_` chamado de `webhook/Webhook.gs` funciona mesmo morando em `shared/Helpers.gs`.
- `.clasp.json` continua com `rootDir: src` — clasp pega recursivamente.
- `.claspignore` precisa permitir os subdiretórios. O atual `!*.gs / !*.js / !*.html / !appsscript.json` cobre só o root do `rootDir`. Trocar por:
  ```
  **/node_modules/**
  ```
  (deixa clasp pegar tudo dentro de `src/` por default).

## Mudanças em arquivos

### `src/Code.gs`

Adicionar:

```js
function doGet(e) {
  if (e && e.parameter && e.parameter.action === "data") {
    return getDataJson_(e.parameter.token);
  }
  return HtmlService.createTemplateFromFile("Index")
    .evaluate()
    .setTitle("hook-finance dashboard")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function getDataJson_(token) {
  const expected = PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN");
  if (!expected || token !== expected) {
    return jsonResponse_({ ok: false, error: "unauthorized" });
  }
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  const last = sheet.getLastRow();
  if (last < 2) return jsonResponse_({ ok: true, rows: [] });
  const values = sheet.getRange(2, 1, last - 1, 7).getValues();
  const rows = values.map((r) => ({
    data: formatBrDate_(r[0]),
    dataRef: typeof r[1] === "string" ? r[1] : formatBrDate_(r[1]),
    descricao: String(r[2] || ""),
    valor: Number(r[3]) || 0,
    origem: String(r[4] || ""),
    categoria: String(r[5] || ""),
    rateio: String(r[6] || ""),
  }));
  return jsonResponse_({ ok: true, rows });
}

function include_(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
```

`jsonResponse_` e `formatBrDate_` já existem e são reutilizados.

### `src/Index.html` (novo)

Estrutura:

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>hook-finance</title>
  <?!= include_('Stylesheet') ?>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
</head>
<body>
  <div id="login" hidden>
    <h2>Token</h2>
    <input id="token-input" type="password" />
    <button id="token-submit">Entrar</button>
    <p id="login-error" class="error"></p>
  </div>

  <div id="dashboard" hidden>
    <header>
      <select id="filter-data"></select>
      <div class="kpi"><span>Total cartão</span><strong id="kpi-total-cartao">—</strong></div>
      <div class="kpi"><span>Total parcelado</span><strong id="kpi-total-parcelado">—</strong></div>
    </header>

    <section class="people">
      <div class="person" id="person-julio">
        <h3>Júlio</h3>
        <table class="origem-breakdown" data-person="Julio"></table>
        <div class="person-kpis"></div>
      </div>
      <div class="person" id="person-dani">
        <h3>Dani</h3>
        <table class="origem-breakdown" data-person="Dani"></table>
        <div class="person-kpis"></div>
      </div>
    </section>

    <section class="lower">
      <div class="card">
        <h3>Cartão (por categoria)</h3>
        <table id="categoria-table"></table>
      </div>
      <div class="card">
        <h3>Cartão (por pessoa)</h3>
        <canvas id="chart-rateio"></canvas>
      </div>
    </section>

    <section class="history">
      <h3>Histórico — Despesas Compartilhadas Totais (sem despesas pessoais)</h3>
      <canvas id="chart-historico"></canvas>
    </section>
  </div>

  <?!= include_('Script') ?>
</body>
</html>
```

### `src/dashboard/Stylesheet.html` (novo)

Wrapper `<style>...</style>`. CSS leve replicando paletas claras do Looker (header amarelo `#f4d35e`, números em destaque, tabelas com bordas sutis). Sem framework. **Mobile-first com CSS Grid + media queries**.

Estratégia responsiva:

```css
/* base mobile-first (≤640px) */
:root { --gap: 0.75rem; --pad: 0.75rem; }
body { font: 16px/1.4 system-ui; padding: var(--pad); }
header { display: grid; gap: var(--gap); }            /* stacked */
.people { display: grid; gap: var(--gap); }            /* Júlio embaixo de Dani */
.lower { display: grid; gap: var(--gap); }
.history canvas { height: 240px; }
table { width: 100%; border-collapse: collapse; font-variant-numeric: tabular-nums; }
.origem-breakdown td, .origem-breakdown th { padding: 0.4rem 0.5rem; font-size: 0.92rem; }
select, input, button { font-size: 16px; padding: 0.6rem; }  /* evita zoom no iOS */
.kpi { display: flex; flex-direction: column; padding: var(--pad); border: 1px solid #e2e2e2; border-radius: 8px; }
.kpi strong { font-size: 1.5rem; }
.card { border: 1px solid #e2e2e2; border-radius: 8px; padding: var(--pad); }
.scroll-x { overflow-x: auto; }                        /* tabelas largas em mobile */

/* tablet (≥640px): 2 colunas onde fizer sentido */
@media (min-width: 640px) {
  header { grid-template-columns: 1fr 1fr 1fr; align-items: end; }
  .people { grid-template-columns: 1fr 1fr; }
  .lower { grid-template-columns: 1fr 1fr; }
  .history canvas { height: 300px; }
}

/* desktop (≥1024px): paddings/fontes maiores */
@media (min-width: 1024px) {
  :root { --gap: 1rem; --pad: 1rem; }
  body { max-width: 1280px; margin: 0 auto; }
  .kpi strong { font-size: 1.8rem; }
}
```

Detalhes específicos pra mobile:
- Tabelas longas (categoria) ficam dentro de `<div class="scroll-x">` para permitir scroll horizontal sem quebrar layout.
- `<select id="filter-data">` ocupa 100% da largura e usa `font-size: 16px` (Safari iOS dá zoom em inputs <16px).
- Charts em `<canvas>` com `aspect-ratio` controlado via JS (`responsive: true, maintainAspectRatio: false`) para escalar corretamente.
- Sem hover-only — usa estados de tap/focus equivalentes em qualquer tooltip do Chart.js (default já cobre).

### `src/Script.html` (novo)
Wrapper `<script>...</script>`. Lógica:

1. Boot:
   - Lê `localStorage.token`. Se não existe → mostra `#login`.
   - Submit do login → faz fetch `?action=data&token=X`. Se `ok:true` → salva token, chama `boot()`. Se não → mostra erro.
2. `boot()`:
   - Faz fetch dos dados (com token).
   - Popula `<select id="filter-data">` com datas únicas (desc).
   - Define handler de change: re-renderiza tudo para a fatura selecionada.
   - Renderiza inicialmente com a fatura mais recente.
3. Funções de agregação (puras, recebem `rows` e `dataFatura`):
   - `kpis(rows, fatura)` → `{totalCartao, totalParcelado}`.
   - `personOrigemBreakdown(rows, fatura, person)` → `[{origem, valor, pct}]`.
   - `personKpis(rows, fatura, person)` → `{cartaoContas, cartaoContasPessoal, diff}`.
   - `categoriaTable(rows, fatura)` → `[{categoria, valorCheio, valor, pct}]`.
   - `rateioChart(rows, fatura)` → `[{rateio, valor}]`.
   - `historicoChart(rows)` → `[{fatura, valorCheio}]` (todas as datas, sem Pessoal).
4. Funções de render:
   - `renderTable`, `renderKpis`, `renderCharts` (Chart.js).
5. Helper `splitByRateio(row, person)`:
   - Se `row.rateio === person`: retorna `row.valor`.
   - Se `row.rateio === "Metade"` e `person ∈ {Julio, Dani}`: retorna `row.valor / 2`.
   - Caso contrário: 0.

### `src/appsscript.json`
Sem mudanças.

### `README.md`
Adicionar seção "Dashboard":
- URL: mesma do webhook (`/exec`) sem query params.
- Token: mesmo `WEBHOOK_TOKEN`. Solicitado no primeiro acesso e guardado em localStorage.
- Para limpar token: DevTools → Application → Local Storage → remover.
- Endpoint de dados: `/exec?action=data&token=<TOKEN>` (útil pra debug ou outra UI).

## Arquivos críticos

- [src/shared/Constants.gs](src/shared/Constants.gs), [src/shared/Helpers.gs](src/shared/Helpers.gs), [src/shared/Setup.gs](src/shared/Setup.gs) — código compartilhado entre webhook e dashboard.
- [src/webhook/Webhook.gs](src/webhook/Webhook.gs), [src/webhook/FixedExpenses.gs](src/webhook/FixedExpenses.gs) — handler do webhook.
- [src/dashboard/Dashboard.gs](src/dashboard/Dashboard.gs) — `doGet`, `getDataJson_`, `include_`.
- [src/dashboard/Index.html](src/dashboard/Index.html) — markup principal.
- [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html) — CSS responsivo (mobile-first).
- [src/dashboard/Script.html](src/dashboard/Script.html) — JS de agregação + Chart.js.
- [.claspignore](.claspignore) — ajuste para permitir subdiretórios.
- [README.md](README.md) — docs do dashboard.

## Passos pós-aprovação

1. Implementar mudanças nos arquivos acima.
2. `npx clasp push -f` + `clasp deploy -i AKfycby...`.
3. Abrir a URL `/exec` no navegador → input do token → dashboard renderiza.
4. Comparar números com o Looker; ajustar fórmulas (especialmente `Cartão/Contas` e a coluna `Valor` da tabela de categoria) se houver discrepância.

## Verificação end-to-end

- **Webhook ainda funciona**: após reorganização, disparar um POST e ver linha gravada (regressão zero).
- **Login**: abrir `/exec` em janela anônima → tela de token. Token errado → erro. Token correto → dashboard carrega.
- **Filtro**: trocar a fatura no `<select>` → todos os componentes recalculam (KPIs, tabelas, gráfico de rateio). Histórico não muda (é série temporal).
- **Totais**: somar manualmente a coluna Valor de uma fatura específica e comparar com `Total cartão` (filtrado por Origem=Cartão).
- **Símbolo Diff**: verificar que `Diff Júlio = -Diff Dani`.
- **Histórico**: aparecer pontos para cada fatura distinta da planilha.
- **API direta**: `curl '<WEB_URL>?action=data&token=<TOKEN>'` retorna JSON com `rows[]`. Sem token → `unauthorized`.
- **Responsivo**: testar em três larguras:
  - Desktop (≥1024px): layout em grid com tabelas Júlio/Dani lado a lado, categoria/rateio lado a lado.
  - Tablet (640–1023px): mesmo layout 2 colunas mas com paddings menores.
  - Mobile (<640px, ex.: DevTools "iPhone SE" 375px): tudo empilhado, KPIs em coluna única, tabela de categoria com scroll horizontal se overflowar, fontes legíveis sem zoom.
- **Touch**: tap no `<select>` abre nativo do SO; sem zoom indesejado em iOS Safari.
