# Carregamento modular do dashboard em 3 passos

## Context

A dashboard hoje demora ~10s até ficar utilizável. A causa raiz é uma única chamada monolítica:

- [src/dashboard/Script.html:71-91](src/dashboard/Script.html#L71-L91) faz `google.script.run.getDataForDashboard(token)`.
- [src/dashboard/Dashboard.gs:12-39](src/dashboard/Dashboard.gs#L12-L39) → `readData_` lê **todas** as linhas da aba "Despesas" (8 colunas, ~600–1200 linhas hoje, crescendo).
- O cliente só renderiza qualquer coisa **depois** de receber o payload completo, e o `renderHistorico` ainda varre `allRows` 3× para montar as séries dos últimos 12 meses.

Objetivo: substituir o carregamento monolítico por 3 passos para que o usuário tenha o dashboard interativo em ~1–2s e os gráficos históricos cheguem em background.

## Strategy

**Passo 1 — Skeleton imediato (0ms após login):** após o submit do token, exibir o layout final preenchido com placeholders animados (shimmer). Sem chamadas ao backend.

**Passo 2 — Mês mais recente (~1–2s):** chamar novo endpoint `getMonthData(token)` que descobre o ciclo mais recente e retorna **só as linhas daquele mês** (~50–100). Renderiza os 3 tiles e os 4 quadros. Seletor aparece com **uma única opção** (mês recente), `disabled`, ainda mostrando os 2 gráficos históricos como skeleton.

**Passo 3 — Histórico (background, ~3–5s):** após o passo 2 resolver, disparar `getHistoricalSummary(token)`. O backend agrega os últimos 12 meses no servidor (não devolve linhas cruas) e devolve também a lista completa de meses para o seletor. Renderiza os 2 gráficos históricos e habilita o seletor com todas as opções.

**Troca de mês no seletor:** quando o usuário escolhe um mês diferente, fazer fetch sob demanda via `getMonthData(token, mes)`. Memoizar no cliente (`monthCache`). **Os gráficos históricos NÃO são re-renderizados** ao trocar mês.

**Não inclui nesta entrega (decidido):** `CacheService` server-side fica para uma melhoria futura.

## Files

**Modificar:**
- [src/dashboard/Dashboard.gs](src/dashboard/Dashboard.gs) — substituir `getDataForDashboard` por 2 endpoints; manter `readData_` como helper privado.
- [src/dashboard/Script.html](src/dashboard/Script.html) — refatorar `init`, `loadData`, `bootDashboard`, `render` para fluxo em 3 passos; novo `monthCache`; novo handler para mudança de mês com fetch sob demanda; `renderHistorico` consumindo séries pré-agregadas.
- [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html) — adicionar regras `.skeleton`, `.skeleton-text`, `.skeleton-bar`, `.skeleton-chart` com animação shimmer; remover/ajustar `.loading`.
- [src/dashboard/Index.html](src/dashboard/Index.html) — envolver placeholders dos tiles/quadros/gráficos em wrappers de skeleton; remover o splash `#loading` "Carregando…".

**Reusar (já existem, manter):**
- `splitForPerson`, `renderTotals`, `renderPerson`, `renderCategoria`, `renderRateioChart` em Script.html — continuam recebendo `inFatura` (rows do mês). Não mudam.
- `formatBrDate_` em Helpers.gs — para o backend.
- `SHEET_ID`, `SHEET_NAME` em Constants.gs.

---

## Backend

### Endpoint 1: `getMonthData(token, month)`

Em [src/dashboard/Dashboard.gs](src/dashboard/Dashboard.gs):

```javascript
function getMonthData(token, month) {
  if (PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN") !== token) {
    return { ok: false, error: "unauthorized" };
  }
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  const last = sheet.getLastRow();
  if (last < 2) return { ok: true, month: null, rows: [] };

  // 1) Lê só coluna A (data) para descobrir mês alvo e o range de linhas
  const dataCol = sheet.getRange(2, 1, last - 1, 1).getValues().map(r => formatBrDate_(r[0]));
  const targetMonth = month || dataCol.reduce((max, d) => parseBrDate_(d) > parseBrDate_(max) ? d : max, dataCol[0]);

  // 2) Encontra o range contínuo (ou linhas esparsas) do mês alvo
  const matchIndexes = [];
  for (let i = 0; i < dataCol.length; i++) {
    if (dataCol[i] === targetMonth) matchIndexes.push(i + 2); // +2 = offset de cabeçalho
  }
  if (matchIndexes.length === 0) return { ok: true, month: targetMonth, rows: [] };

  // 3) Lê só as linhas do mês (8 colunas) — em range contínuo se possível
  const minRow = matchIndexes[0];
  const maxRow = matchIndexes[matchIndexes.length - 1];
  const slab = sheet.getRange(minRow, 1, maxRow - minRow + 1, 8).getValues();
  const rows = slab
    .map((r, idx) => ({ absRow: minRow + idx, raw: r }))
    .filter(x => formatBrDate_(x.raw[0]) === targetMonth)
    .map(x => ({
      data: formatBrDate_(x.raw[0]),
      dataRef: typeof x.raw[1] === "string" ? x.raw[1] : formatBrDate_(x.raw[1]),
      descricao: String(x.raw[2] || ""),
      valor: Number(x.raw[3]) || 0,
      origem: String(x.raw[4] || ""),
      categoria: String(x.raw[5] || ""),
      rateio: String(x.raw[6] || ""),
      cardLast4: String(x.raw[7] || ""),
    }));

  return { ok: true, month: targetMonth, rows: rows };
}
```

Helper novo em [src/shared/Helpers.gs](src/shared/Helpers.gs):

```javascript
function parseBrDate_(s) {
  // "DD/MM/YYYY" -> Date (para comparação cronológica)
  const [d, m, y] = String(s).split("/").map(Number);
  return new Date(y, (m || 1) - 1, d || 1);
}
```

### Endpoint 2: `getHistoricalSummary(token)`

Em [src/dashboard/Dashboard.gs](src/dashboard/Dashboard.gs):

```javascript
function getHistoricalSummary(token) {
  if (PropertiesService.getScriptProperties().getProperty("WEBHOOK_TOKEN") !== token) {
    return { ok: false, error: "unauthorized" };
  }
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  const last = sheet.getLastRow();
  if (last < 2) return { ok: true, months: [], history: { months: [], totals: [], julioPessoal: [], daniPessoal: [] } };

  // Lê apenas as colunas necessárias: data(A), valor(D), origem(E), categoria(F), rateio(G)
  const values = sheet.getRange(2, 1, last - 1, 7).getValues();

  // Agrupa por mês (string DD/MM/YYYY), preservando ordem cronológica decrescente
  const byMonth = {};
  for (const r of values) {
    const data = formatBrDate_(r[0]);
    if (!data) continue;
    const valor = Number(r[3]) || 0;
    const origem = String(r[4] || "");
    const categoria = String(r[5] || "");
    const rateio = String(r[6] || "");
    if (!byMonth[data]) byMonth[data] = { total: 0, julioPessoal: 0, daniPessoal: 0 };
    if (origem !== "Pessoal") byMonth[data].total += valor;
    if (categoria === "Pessoal") {
      if (rateio === "Julio") byMonth[data].julioPessoal += valor;
      else if (rateio === "Dani") byMonth[data].daniPessoal += valor;
    }
  }

  const monthsDesc = Object.keys(byMonth).sort((a, b) => parseBrDate_(b) - parseBrDate_(a));
  const last12 = monthsDesc.slice(0, 12).reverse(); // cronológico ascendente para o gráfico

  return {
    ok: true,
    months: monthsDesc, // todos os meses para popular o seletor
    history: {
      months: last12,
      totals: last12.map(m => byMonth[m].total),
      julioPessoal: last12.map(m => byMonth[m].julioPessoal),
      daniPessoal: last12.map(m => byMonth[m].daniPessoal),
    },
  };
}
```

> **Nota:** confirmar nas funções existentes `renderHistorico` quais filtros estão aplicados (origem !== "Pessoal" para total; categoria === "Pessoal" + rateio para personal). Os agregados acima devem espelhar EXATAMENTE a mesma lógica de [src/dashboard/Script.html:343-357](src/dashboard/Script.html#L343-L357).

### Limpar

- Remover `getDataForDashboard` e `readAllForApi_` se não tiverem outros consumidores (verificar `doGet` com `action=data`). Se `doGet?action=data` for usado externamente, manter `readAllForApi_` apontando para uma união nova ou o `readData_` original.

---

## Frontend

### Skeleton CSS

Em [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html):

```css
@keyframes shimmer {
  0% { background-position: -400px 0; }
  100% { background-position: 400px 0; }
}
.skeleton {
  background: linear-gradient(90deg, #2a2a2a 0px, #3a3a3a 200px, #2a2a2a 400px);
  background-size: 800px 100%;
  animation: shimmer 1.4s infinite linear;
  border-radius: 4px;
  color: transparent !important;
  pointer-events: none;
}
.skeleton-text   { display: inline-block; width: 6ch; height: 1em; }
.skeleton-bar    { height: 12px; margin: 6px 0; }
.skeleton-chart  { width: 100%; height: 220px; }
```

### Markup com skeleton

Em [src/dashboard/Index.html](src/dashboard/Index.html):
- Remover o bloco `#loading` "Carregando…".
- Os elementos dos tiles, tabelas e canvases já existem; basta adicionar a classe `skeleton` inicial onde apropriado, ou inserir wrappers `<div class="skeleton skeleton-bar">` para tabelas vazias.
- Para os 2 canvases de histórico, manter o `<canvas>` mas exibir um irmão `.skeleton.skeleton-chart` por padrão; o JS troca a visibilidade ao terminar o passo 3.

### Refatoração do Script.html

Substituir o bloco atual `init`/`loadData`/`bootDashboard`/`render` em [src/dashboard/Script.html:51-115](src/dashboard/Script.html#L51-L115):

```javascript
let currentMonth = null;
let currentMonthRows = [];
const monthCache = Object.create(null); // { "DD/MM/YYYY": rows[] }

function init() {
  $("token-submit").addEventListener("click", handleLogin);
  $("token-input").addEventListener("keydown", (e) => { if (e.key === "Enter") handleLogin(); });
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) startDashboard(token); else showLogin();
}

function startDashboard(token) {
  showSkeleton();           // Passo 1
  loadCurrentMonth(token);  // Passo 2 -> dispara passo 3 no sucesso
}

function loadCurrentMonth(token) {
  google.script.run
    .withSuccessHandler((res) => {
      if (!res.ok) return showLogin("Falha: " + (res.error || "desconhecido"));
      currentMonth = res.month;
      currentMonthRows = res.rows;
      monthCache[res.month] = res.rows;
      renderCurrentMonth(res.month, res.rows);  // tiles + 4 quadros
      seedSelector(res.month);                  // 1 opção, disabled
      loadHistorical(token);                    // Passo 3 em background
    })
    .withFailureHandler((err) => showLogin("Falha: " + err.message))
    .getMonthData(token, null);
}

function loadHistorical(token) {
  google.script.run
    .withSuccessHandler((res) => {
      if (!res.ok) return showHistoricalError(res.error);
      renderHistoricoFromSummary(res.history); // remove skeleton dos 2 charts
      expandSelector(res.months);              // todos os meses + enable
    })
    .withFailureHandler((err) => showHistoricalError(err.message))
    .getHistoricalSummary(token);
}

function onMonthChange(novoMes) {
  if (novoMes === currentMonth) return;
  if (monthCache[novoMes]) {
    currentMonth = novoMes;
    currentMonthRows = monthCache[novoMes];
    renderCurrentMonth(novoMes, currentMonthRows);
    return;
  }
  showCurrentMonthSkeleton(); // re-skeleton só dos tiles/quadros
  google.script.run
    .withSuccessHandler((res) => {
      if (!res.ok) return; // tratar erro inline
      monthCache[res.month] = res.rows;
      currentMonth = res.month;
      currentMonthRows = res.rows;
      renderCurrentMonth(res.month, res.rows);
    })
    .getMonthData(localStorage.getItem(TOKEN_KEY), novoMes);
}
```

Helpers a implementar em Script.html:
- `showSkeleton()` — esconde `#login`, mostra `#dashboard` com elementos em estado skeleton.
- `renderCurrentMonth(mes, rows)` — chama `renderTotals(rows)`, `renderPerson("Julio", rows)`, `renderPerson("Dani", rows)`, `renderCategoria(rows)`, `renderRateioChart(rows)` e remove classes `.skeleton` desses blocos.
- `seedSelector(mes)` — popula `#filter-data` com 1 opção e seta `disabled = true`.
- `expandSelector(meses)` — substitui as opções por `meses` (já em ordem desc), `disabled = false`, e adiciona listener `change` chamando `onMonthChange(sel.value)`.
- `renderHistoricoFromSummary(history)` — substitui `renderHistorico` atual; recebe `{ months, totals, julioPessoal, daniPessoal }` direto e chama `drawLineChart_` 2×; remove skeleton dos 2 canvases.
- `showHistoricalError(msg)` — substitui skeleton dos charts por uma mensagem inline; tiles/quadros continuam funcionando.
- `showCurrentMonthSkeleton()` — re-aplica skeleton nos tiles/quadros durante fetch sob demanda.

### Limpar

- Remover `bootDashboard`, `render` (substituído por `renderCurrentMonth`), `renderHistorico` (substituído por `renderHistoricoFromSummary`), `allRows` global e `loadData`.

---

## Tasks

1. **Backend — `parseBrDate_` em Helpers.gs.** Adicionar helper.
2. **Backend — `getMonthData(token, month)` em Dashboard.gs.** Inclui leitura otimizada (col A primeiro, depois slab do range).
3. **Backend — `getHistoricalSummary(token)` em Dashboard.gs.** Espelhar exatamente a lógica de filtro de [Script.html:343-357](src/dashboard/Script.html#L343-L357).
4. **Backend — limpeza de `getDataForDashboard`/`readAllForApi_`.** Verificar se `doGet?action=data` ainda é consumido externamente; se sim, manter ponte; se não, remover.
5. **CSS — skeleton em Stylesheet.html.** Animação `shimmer` + classes utilitárias.
6. **HTML — Index.html.** Remover splash `#loading`; envolver/etiquetar placeholders.
7. **JS — refatoração Script.html.** Substituir `init`/`loadData`/`bootDashboard`/`render`/`renderHistorico` pelo fluxo de 3 passos descrito acima; introduzir `monthCache`, `onMonthChange`, helpers de skeleton.
8. **JS — `renderHistoricoFromSummary`.** Adaptar para consumir séries pré-agregadas vindas do backend.
9. **Tratamento de erro do passo 3.** Tiles/quadros funcionam normalmente; gráficos históricos exibem mensagem inline.

---

## Verification

1. **Deploy:** publicar via processo atual (clasp push ou editor do Apps Script) e abrir a URL do webapp.
2. **Skeleton imediato:** após submeter o token, o layout do dashboard deve aparecer instantaneamente com placeholders animados (não mais "Carregando…"). Medir no DevTools → Performance.
3. **Passo 2 (~1–2s):** cronometrar até os 3 tiles e os 4 quadros ficarem com dados reais. Comparar contra o tempo atual (~10s).
4. **Passo 3 (background):** os 2 gráficos de histórico continuam em skeleton enquanto a request `getHistoricalSummary` roda; depois aparecem renderizados. Seletor passa de 1 opção `disabled` para N opções habilitadas.
5. **Troca de mês:** ao escolher um mês diferente no seletor, apenas tiles/quadros entram em skeleton e re-renderizam após fetch sob demanda. Os 2 gráficos de histórico **não piscam**.
6. **Cache cliente:** voltar para o mês recente após visitar outro deve ser instantâneo (sem fetch — confirmar na aba Network do DevTools).
7. **Erro de histórico:** simular falha (ex.: revogar permissão temporariamente) e confirmar que tiles/quadros seguem funcionais e os charts exibem mensagem inline.
8. **Webhook não regrediu:** inserir uma despesa via webhook (POST com token) e recarregar o dashboard — a nova linha deve aparecer no mês correspondente.
