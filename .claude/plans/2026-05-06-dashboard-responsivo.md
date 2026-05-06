# Dashboard Responsivo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reestruturar o dashboard com nav primária (Consulta/Detalhe/Lançamento), 3 sub-abas (Mês/Cartão/Histórico), responsividade mobile-first com body max-width 720px em tablet+, persistência da aba ativa e render lazy dos charts.

**Architecture:** Index.html ganha nav primária + sticky header + tab-strip + 3 tab-panels. Stylesheet.html reescreve breakpoints e adiciona regras pra nav, tabs, header compacto mobile e max-width. Script.html ganha estado `activeTab`, persistência em localStorage e mecanismo de pending charts (canvas só desenhado quando tab dele está visível).

**Tech Stack:** Google Apps Script web app · HTML/CSS/Vanilla JS · Chart.js 4 · clasp 2.5.

**Spec:** [.claude/specs/2026-05-06-dashboard-responsivo-design.md](.claude/specs/2026-05-06-dashboard-responsivo-design.md)

**Verification approach:** Como Apps Script web app não tem framework de testes automatizados neste projeto, cada task termina com verificação manual via `clasp push` + DevTools. Nas tasks de CSS/UI, o engenheiro deve abrir o webapp `@HEAD` e usar o emulador de dispositivos do Chrome (3 viewports: 360px, 768px, 1280px) para validar o comportamento.

---

## File Structure

| Arquivo | Responsabilidade após refactor |
|---|---|
| [src/dashboard/Index.html](src/dashboard/Index.html) | Markup com nav primária → sticky header → tab-strip → 3 tab-panels (mes, cartao, historico). Cada panel contém os cards/charts atuais reorganizados. |
| [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html) | Estilo mobile-first; novas classes `.primary-nav`, `.nav-item`, `.sticky-header`, `.filter-and-kpis`, `.tab-strip`, `.tab-btn`, `.tab-panel`; max-width body em ≥640px. |
| [src/dashboard/Script.html](src/dashboard/Script.html) | Adiciona estado `activeTab`, `chartPending`, `setActiveTab()`, `flushPendingCharts()`; modifica `renderCurrentMonth` e `renderHistoricoFromSummary` pra deferir charts não visíveis. |

Nenhuma mudança em backend (`Dashboard.gs`, `Helpers.gs`).

---

## Convenções

- **Breakpoints:** `@media (min-width: 640px)` separa mobile de tablet+; `@media (min-width: 1024px)` separa tablet de desktop.
- **Body max-width:** 720px centralizado em ≥640px; 100% em <640px.
- **Nav primária:** `position: fixed; bottom: 0` em mobile; `position: static; top` em ≥640px.
- **Estado da aba:** chave `hook-finance-tab` no localStorage. Valores válidos: `mes`, `cartao`, `historico`. Default: `mes`.

---

## Task 1: HTML — restructure markup

**Files:**
- Modify: `src/dashboard/Index.html` (lines 11-79 inteiras — corpo do `<body>` exceto `<script>`)

- [ ] **Step 1: Substituir o conteúdo do `<body>` por estrutura nova**

Substituir todo o bloco entre `<body>` e `<?!= include_('dashboard/Script') ?>` em [src/dashboard/Index.html](src/dashboard/Index.html) por:

```html
<body>
  <div id="login" hidden>
    <div class="login-card">
      <h2>hook-finance</h2>
      <label for="token-input">Token</label>
      <input id="token-input" type="password" autocomplete="off" />
      <button id="token-submit" type="button">Entrar</button>
      <p id="login-error" class="error" hidden></p>
    </div>
  </div>

  <div id="dashboard" hidden>
    <nav class="primary-nav" role="navigation" aria-label="Páginas principais">
      <button type="button" class="nav-item active" data-page="consulta">📊 Consulta</button>
      <button type="button" class="nav-item disabled" disabled aria-disabled="true">📋 Detalhe</button>
      <button type="button" class="nav-item disabled" disabled aria-disabled="true">➕ Lançamento</button>
    </nav>

    <div id="page-consulta" class="page">
      <div class="sticky-header">
        <div class="filter-and-kpis">
          <div class="filter-group">
            <label for="filter-data">Data</label>
            <select id="filter-data" disabled><option>—</option></select>
          </div>
          <div class="kpi"><span>Total geral</span><strong id="kpi-total-geral" class="skeleton skeleton-bar lg">—</strong></div>
          <div class="kpi"><span>Total cartão</span><strong id="kpi-total-cartao" class="skeleton skeleton-bar lg">—</strong></div>
          <div class="kpi"><span>Total parcelado</span><strong id="kpi-total-parcelado" class="skeleton skeleton-bar lg">—</strong></div>
        </div>
      </div>

      <div class="tab-strip" role="tablist" aria-label="Sub-seções">
        <button type="button" class="tab-btn active" data-tab="mes" role="tab" aria-selected="true">Mês</button>
        <button type="button" class="tab-btn" data-tab="cartao" role="tab" aria-selected="false">Cartão</button>
        <button type="button" class="tab-btn" data-tab="historico" role="tab" aria-selected="false">Histórico</button>
      </div>

      <section id="tab-mes" class="tab-panel" role="tabpanel">
        <div class="people">
          <div class="card person" data-person="Julio">
            <h3>Júlio</h3>
            <div class="scroll-x">
              <table class="origem-breakdown" id="table-julio"></table>
              <div id="skeleton-table-julio" class="skeleton-table">
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
              </div>
            </div>
            <div class="person-kpis" id="kpis-julio">
              <div class="mini-kpi skeleton skeleton-bar lg"></div>
              <div class="mini-kpi skeleton skeleton-bar lg"></div>
              <div class="mini-kpi skeleton skeleton-bar lg"></div>
            </div>
          </div>
          <div class="card person" data-person="Dani">
            <h3>Dani</h3>
            <div class="scroll-x">
              <table class="origem-breakdown" id="table-dani"></table>
              <div id="skeleton-table-dani" class="skeleton-table">
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
              </div>
            </div>
            <div class="person-kpis" id="kpis-dani">
              <div class="mini-kpi skeleton skeleton-bar lg"></div>
              <div class="mini-kpi skeleton skeleton-bar lg"></div>
              <div class="mini-kpi skeleton skeleton-bar lg"></div>
            </div>
          </div>
        </div>
      </section>

      <section id="tab-cartao" class="tab-panel" role="tabpanel" hidden>
        <div class="lower">
          <div class="card">
            <h3>Cartão (por categoria)</h3>
            <div class="scroll-x">
              <table id="categoria-table"></table>
              <div id="skeleton-table-categoria" class="skeleton-table">
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
                <span class="skeleton skeleton-bar"></span>
              </div>
            </div>
          </div>
          <div class="card">
            <h3>Cartão (por pessoa)</h3>
            <div class="chart-wrap">
              <canvas id="chart-rateio" hidden></canvas>
              <div id="skeleton-chart-rateio" class="skeleton skeleton-chart"></div>
            </div>
          </div>
        </div>
      </section>

      <section id="tab-historico" class="tab-panel" role="tabpanel" hidden>
        <section class="card history">
          <h3>Histórico — Total geral</h3>
          <div class="chart-wrap">
            <canvas id="chart-historico-total" hidden></canvas>
            <div id="skeleton-chart-historico-total" class="skeleton skeleton-chart"></div>
            <p id="error-historico-total" class="error" hidden></p>
          </div>
        </section>
        <section class="card history">
          <h3>Histórico — Pessoal</h3>
          <div class="chart-wrap">
            <canvas id="chart-historico-pessoal" hidden></canvas>
            <div id="skeleton-chart-historico-pessoal" class="skeleton skeleton-chart"></div>
            <p id="error-historico-pessoal" class="error" hidden></p>
          </div>
        </section>
      </section>
    </div>
  </div>

  <?!= include_('dashboard/Script') ?>
</body>
```

- [ ] **Step 2: Verificar visualmente que markup não quebra nada**

Run: `.\node_modules\.bin\clasp.cmd push -f`
Expected: `Pushed 11 files.`

Recarregar webapp `@HEAD` no browser. Esperado: dashboard ainda funciona; visualmente vai aparecer estranho (sem CSS dos novos elementos), mas KPIs, pessoa, cartão e histórico continuam todos visíveis e renderizados (porque o JS atual ainda mostra todos os panels — `hidden` nos `#tab-cartao` e `#tab-historico` esconde inicialmente, mas o JS ainda não controla isso). Isto é esperado nesta task.

Com DevTools console aberto: nenhum erro JS.

- [ ] **Step 3: Commit**

```bash
git add src/dashboard/Index.html
git commit -m "refactor(dashboard): reorganize markup with primary nav and sub-tab panels"
```

---

## Task 2: JS — tab switching + localStorage persistence

**Files:**
- Modify: `src/dashboard/Script.html` (init function, novas funções)

- [ ] **Step 1: Adicionar estado `activeTab` e helper `setActiveTab`**

Em [src/dashboard/Script.html](src/dashboard/Script.html), localizar a área de declaração de globals (~linha 11-26) e adicionar estas linhas após `let currentMonthRows = [];`:

```javascript
  const TAB_KEY = "hook-finance-tab";
  const VALID_TABS = ["mes", "cartao", "historico"];
  let activeTab = "mes";
```

- [ ] **Step 2: Adicionar a função `setActiveTab` antes de `function init()`**

Adicionar este bloco em [src/dashboard/Script.html](src/dashboard/Script.html) imediatamente antes da função `init()`:

```javascript
  function setActiveTab(tab) {
    if (!VALID_TABS.includes(tab)) tab = "mes";
    activeTab = tab;
    try { localStorage.setItem(TAB_KEY, tab); } catch (_) {}
    const buttons = document.querySelectorAll(".tab-btn");
    for (const btn of buttons) {
      const isActive = btn.dataset.tab === tab;
      btn.classList.toggle("active", isActive);
      btn.setAttribute("aria-selected", isActive ? "true" : "false");
    }
    const panels = document.querySelectorAll(".tab-panel");
    for (const panel of panels) {
      panel.hidden = panel.id !== "tab-" + tab;
    }
    flushPendingCharts(tab);
  }

  function flushPendingCharts(tab) {
    // implementação na Task 5; placeholder vazio agora
  }
```

- [ ] **Step 3: Modificar `init()` pra restaurar tab e ligar listeners das tabs**

Localizar a função `init()` em [src/dashboard/Script.html](src/dashboard/Script.html) (atualmente entre as linhas ~48-65) e substituir todo o corpo dela por:

```javascript
  function init() {
    $("token-submit").addEventListener("click", () => {
      const v = $("token-input").value.trim();
      if (!v) return;
      localStorage.setItem(TOKEN_KEY, v);
      startDashboard(v);
    });
    $("token-input").addEventListener("keydown", (e) => {
      if (e.key === "Enter") $("token-submit").click();
    });
    $("filter-data").addEventListener("change", (e) => {
      onMonthChange(e.target.value);
    });
    for (const btn of document.querySelectorAll(".tab-btn")) {
      btn.addEventListener("click", () => setActiveTab(btn.dataset.tab));
    }
    let saved = "mes";
    try { saved = localStorage.getItem(TAB_KEY) || "mes"; } catch (_) {}
    setActiveTab(saved);

    const stored = localStorage.getItem(TOKEN_KEY);
    if (stored) startDashboard(stored);
    else showLogin();
  }
```

- [ ] **Step 4: Push e verificar troca de aba funciona**

Run: `.\node_modules\.bin\clasp.cmd push -f`

Recarregar webapp. Esperado:
- Inicial: aba "Mês" ativa (botão pintado), só `#tab-mes` visível, demais com `hidden`.
- Click em "Cartão": `#tab-cartao` aparece, `#tab-mes` desaparece, botão "Cartão" pintado.
- Click em "Histórico": idem.
- Recarregar página depois de selecionar "Histórico": dashboard volta com "Histórico" ativo.
- Console: sem erros.

Nota: charts vão estar quebrados (canvas oculto) — será resolvido na Task 5.

- [ ] **Step 5: Commit**

```bash
git add src/dashboard/Script.html
git commit -m "feat(dashboard): wire sub-tab switching with localStorage persistence"
```

---

## Task 3: CSS — base structure + body max-width + panel visibility

**Files:**
- Modify: `src/dashboard/Stylesheet.html`

- [ ] **Step 1: Atualizar reset/body styles**

Em [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html), localizar o bloco `body { ... }` (~linha 17) e substituir POR:

```css
  html, body { margin: 0; padding: 0; }
  body {
    font: 16px/1.4 -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
    color: var(--fg);
    background: var(--bg);
    padding: var(--pad);
  }
  #dashboard {
    max-width: none;
    margin: 0;
  }
  .page {
    padding-bottom: 4rem; /* espaço pro bottom nav fixo no mobile */
  }
  .tab-panel[hidden] { display: none !important; }
```

- [ ] **Step 2: Substituir media query desktop pra usar 720px no body**

Localizar o bloco `@media (min-width: 1024px) { ... }` no fim do arquivo [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html) e substituir TODO o bloco por:

```css
  /* Tablet+ (≥640px) */
  @media (min-width: 640px) {
    body {
      max-width: 720px;
      margin: 0 auto;
    }
    .page {
      padding-bottom: 0; /* sem bottom nav fixa em ≥640px */
    }
    .people { grid-template-columns: 1fr 1fr; }
    .lower { grid-template-columns: 1fr 1fr; }
    .chart-wrap { height: 280px; }
    .history .chart-wrap { height: 300px; }
  }

  /* Desktop (≥1024px) — mantém max-width 720px, ajusta apenas spacing */
  @media (min-width: 1024px) {
    :root { --gap: 1rem; --pad: 1rem; }
    .kpi strong { font-size: 1.6rem; }
  }
```

- [ ] **Step 3: Remover regra antiga `header { grid-template-columns: 1.2fr 1fr 1fr }`**

Buscar dentro de `@media (min-width: 640px)` antes da edição anterior — se ainda existir uma regra residual `header { grid-template-columns: 1.2fr 1fr 1fr; align-items: end; }`, remover (a Task 4 reescreve esse bloco).

Pra confirmar: após Step 2, o arquivo não deve mais conter qualquer regra que use `header` como seletor. Use Grep:

Run: `grep -n "^\s*header\s*{" src/dashboard/Stylesheet.html`
Expected: nenhuma linha retornada.

- [ ] **Step 4: Push e verificar que body fica centralizado em tablet+**

Run: `.\node_modules\.bin\clasp.cmd push -f`

DevTools → Toggle device toolbar:
- 360px: body ocupa 100% largura. Nada deve estourar.
- 768px (iPad): body com max-width 720px, centralizado.
- 1280px: body 720px centralizado, margens cinza/bg laterais.

Bug esperado nesta task: nav primária e tabs ainda sem styling. Aceitável.

- [ ] **Step 5: Commit**

```bash
git add src/dashboard/Stylesheet.html
git commit -m "style(dashboard): set body max-width 720px and panel visibility"
```

---

## Task 4: CSS — primary nav (bottom mobile, top tablet+)

**Files:**
- Modify: `src/dashboard/Stylesheet.html`

- [ ] **Step 1: Adicionar regras de `.primary-nav` antes do bloco `/* Skeleton */`**

Em [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html), localizar a linha que tem `/* Skeleton */` (introduzida na entrega anterior) e adicionar IMEDIATAMENTE ANTES dela este bloco:

```css
  /* Primary nav — Consulta / Detalhe / Lançamento */
  .primary-nav {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 0;
    background: #262626;
    border-radius: 0;
    overflow: hidden;
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    padding-bottom: env(safe-area-inset-bottom);
    z-index: 50;
    border-top: 1px solid #3a3a3a;
  }
  .nav-item {
    background: transparent;
    color: white;
    border: none;
    border-radius: 0;
    padding: 0.7rem 0.4rem;
    font-size: 0.85rem;
    font-weight: 600;
    text-align: center;
    cursor: pointer;
  }
  .nav-item.active {
    background: var(--accent);
    color: var(--accent-fg);
  }
  .nav-item.disabled,
  .nav-item:disabled {
    opacity: 0.45;
    cursor: not-allowed;
    pointer-events: none;
  }
```

- [ ] **Step 2: Adicionar override em ≥640px pra colocar a nav no topo**

Dentro do bloco `@media (min-width: 640px)` que foi criado na Task 3 Step 2, ADICIONAR (pode colar logo após `.history .chart-wrap`) estas regras:

```css
    .primary-nav {
      position: static;
      margin-bottom: var(--gap);
      border-radius: 8px;
      padding: 4px;
      gap: 4px;
      border-top: none;
    }
    .nav-item {
      border-radius: 6px;
      padding: 0.7rem 0.6rem;
    }
```

- [ ] **Step 3: Push e verificar nav primária**

Run: `.\node_modules\.bin\clasp.cmd push -f`

DevTools:
- 360px: bar preta no rodapé fixa, "Consulta" amarela ativa, outros 2 cinza claro inativos. Não dá pra clicar em Detalhe/Lançamento.
- 768px: bar preta no topo do dashboard. Mesma estrutura.
- 1280px: idem 768px.

- [ ] **Step 4: Commit**

```bash
git add src/dashboard/Stylesheet.html
git commit -m "style(dashboard): primary nav (bottom on mobile, top on tablet+)"
```

---

## Task 5: CSS — sticky header + tile-strip mobile / 4-col tablet+

**Files:**
- Modify: `src/dashboard/Stylesheet.html`

- [ ] **Step 1: Substituir o bloco `/* Header */` por novas regras**

Em [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html), localizar o comentário `/* Header */` e o bloco que vem depois (até antes de `/* Cards / sections */`). Substituir TODO esse intervalo (`header`, `.filter-stack`, `.filter-group`, `.kpi`) por:

```css
  /* Sticky header (mobile: combined card; tablet+: 4-col grid) */
  .sticky-header {
    position: sticky;
    top: -1px; /* esconde 1px de borda quando sticky */
    background: var(--bg);
    z-index: 20;
    padding: 0.4rem 0;
    margin-bottom: var(--gap);
  }
  .filter-and-kpis {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 0.4rem;
    background: white;
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 0.6rem;
  }
  .filter-and-kpis .filter-group {
    grid-column: 1 / -1;
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    border-bottom: 1px solid var(--border);
    padding-bottom: 0.4rem;
    margin-bottom: 0.2rem;
  }
  .filter-and-kpis .filter-group label {
    font-size: 0.75rem;
    color: var(--muted);
  }
  .kpi {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
    text-align: center;
    padding: 0.2rem;
    background: transparent;
    border: none;
    border-radius: 0;
  }
  .filter-and-kpis .kpi:not(:last-child) {
    border-right: 1px solid var(--border);
  }
  .kpi span {
    font-size: 0.7rem;
    color: var(--muted);
  }
  .kpi strong {
    font-size: 1.1rem;
    font-variant-numeric: tabular-nums;
  }
```

- [ ] **Step 2: Adicionar overrides do header em tablet+**

Dentro do bloco `@media (min-width: 640px)` (em [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html)), adicionar após as regras da `.primary-nav` da Task 4:

```css
    .sticky-header {
      position: static;
      padding: 0;
    }
    .filter-and-kpis {
      grid-template-columns: 1.2fr 1fr 1fr 1fr;
      gap: var(--gap);
      background: transparent;
      border: none;
      padding: 0;
    }
    .filter-and-kpis .filter-group {
      grid-column: auto;
      border-bottom: none;
      padding: var(--pad);
      margin: 0;
      background: white;
      border: 1px solid var(--border);
      border-radius: 8px;
    }
    .filter-and-kpis .filter-group label {
      font-size: 0.8rem;
    }
    .kpi {
      background: white;
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: var(--pad);
      text-align: left;
    }
    .filter-and-kpis .kpi:not(:last-child) {
      border-right: 1px solid var(--border);
    }
    .kpi strong {
      font-size: 1.5rem;
    }
    .kpi span {
      font-size: 0.8rem;
    }
```

- [ ] **Step 3: Push e verificar header em todos os viewports**

Run: `.\node_modules\.bin\clasp.cmd push -f`

DevTools:
- 360px: 1 card branco ocupando todo width, com selector full-width na primeira linha (com label "Data") + 3 mini-KPIs em 3 col abaixo (separados por linha vertical). Sticky: scrollar pra baixo, header gruda no topo.
- 768px / 1280px: 4 cards inline (selector + 3 totais), cada um com seu border. Não sticky.

- [ ] **Step 4: Commit**

```bash
git add src/dashboard/Stylesheet.html
git commit -m "style(dashboard): compact sticky header on mobile and 4-col on tablet+"
```

---

## Task 6: CSS — sub-tabs (segmented control)

**Files:**
- Modify: `src/dashboard/Stylesheet.html`

- [ ] **Step 1: Adicionar regras de `.tab-strip` antes do bloco `/* Cards / sections */`**

Em [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html), localizar `/* Cards / sections */` e ADICIONAR IMEDIATAMENTE ANTES dele:

```css
  /* Sub-tabs (Mês / Cartão / Histórico) */
  .tab-strip {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 4px;
    background: white;
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 4px;
    margin-bottom: var(--gap);
  }
  .tab-btn {
    background: transparent;
    color: var(--muted);
    border: none;
    border-radius: 6px;
    padding: 0.6rem 0.4rem;
    font-size: 0.95rem;
    font-weight: 600;
    cursor: pointer;
  }
  .tab-btn.active {
    background: var(--accent);
    color: var(--accent-fg);
  }
```

- [ ] **Step 2: Push e verificar visual**

Run: `.\node_modules\.bin\clasp.cmd push -f`

DevTools (qualquer viewport): faixa branca abaixo do header com 3 botões iguais. "Mês" pintado de amarelo (ativo). Click em outro troca o pintado e mostra/esconde o panel correto.

- [ ] **Step 3: Commit**

```bash
git add src/dashboard/Stylesheet.html
git commit -m "style(dashboard): segmented control for sub-tabs"
```

---

## Task 7: JS — lazy chart render per active tab

**Files:**
- Modify: `src/dashboard/Script.html`

- [ ] **Step 1: Trocar a função `flushPendingCharts` placeholder por implementação completa**

Em [src/dashboard/Script.html](src/dashboard/Script.html), localizar a função `flushPendingCharts(tab)` que foi criada vazia na Task 2 e substituí-la POR:

```javascript
  const chartPending = {
    rateio: null,
    historicoTotal: null,
    historicoPessoal: null,
  };

  function flushPendingCharts(tab) {
    if (tab === "cartao" && chartPending.rateio !== null) {
      const rows = chartPending.rateio;
      chartPending.rateio = null;
      revealRateioCanvas_();
      renderRateioChart(rows);
    }
    if (tab === "historico") {
      if (chartPending.historicoTotal !== null) {
        const p = chartPending.historicoTotal;
        chartPending.historicoTotal = null;
        revealHistoricoCanvases_();
        drawLineChart_("chart-historico-total", "historicoTotal", p.months, p.series);
      }
      if (chartPending.historicoPessoal !== null) {
        const p = chartPending.historicoPessoal;
        chartPending.historicoPessoal = null;
        revealHistoricoCanvases_();
        drawLineChart_("chart-historico-pessoal", "historicoPessoal", p.months, p.series);
      }
    }
  }

  function revealRateioCanvas_() {
    const c = $("chart-rateio");
    if (c) c.hidden = false;
    const sk = $(RATEIO_SKELETON);
    if (sk) sk.hidden = true;
  }

  function revealHistoricoCanvases_() {
    for (const id of [HISTORICO_TOTAL_SKELETON, HISTORICO_PESSOAL_SKELETON]) {
      const el = $(id);
      if (el) el.hidden = true;
    }
    for (const cid of ["chart-historico-total", "chart-historico-pessoal"]) {
      const c = $(cid);
      if (c) c.hidden = false;
    }
  }
```

Nota: `chartPending` deve ser declarado UMA SÓ VEZ no arquivo. Se já tiver sido declarado por engano na Task 2, mover/manter aqui e remover de lá.

- [ ] **Step 2: Modificar `clearCurrentMonthSkeleton` pra não revelar o canvas do rateio**

Localizar `function clearCurrentMonthSkeleton()` em [src/dashboard/Script.html](src/dashboard/Script.html) e substituir o corpo POR (remove a parte que mexe no `chart-rateio` canvas):

```javascript
  function clearCurrentMonthSkeleton() {
    for (const id of TILE_IDS) {
      $(id).classList.remove("skeleton", "skeleton-bar", "lg");
    }
    for (const id of TABLE_SKELETONS) {
      const el = $(id);
      if (el) el.hidden = true;
    }
  }
```

- [ ] **Step 3: Modificar `renderCurrentMonth` pra deferir rateio chart se aba inativa**

Localizar `function renderCurrentMonth(mes, rows)` em [src/dashboard/Script.html](src/dashboard/Script.html) e substituir POR:

```javascript
  function renderCurrentMonth(mes, rows) {
    clearCurrentMonthSkeleton();
    renderTotals(rows);
    renderPerson("Julio", rows);
    renderPerson("Dani", rows);
    renderCategoria(rows);
    if (activeTab === "cartao") {
      revealRateioCanvas_();
      renderRateioChart(rows);
      chartPending.rateio = null;
    } else {
      chartPending.rateio = rows;
    }
  }
```

- [ ] **Step 4: Modificar `renderHistoricoFromSummary` pra deferir charts de histórico se aba inativa**

Localizar `function renderHistoricoFromSummary(history)` em [src/dashboard/Script.html](src/dashboard/Script.html) e substituir POR:

```javascript
  function renderHistoricoFromSummary(history) {
    const meses = (history && history.months) || [];
    const totals = (history && history.totals) || [];
    const julioPessoal = (history && history.julioPessoal) || [];
    const daniPessoal = (history && history.daniPessoal) || [];

    const totalSeries = [
      { label: "Total geral", data: totals, color: "#a07b5e", align: "top" },
    ];
    const pessoalSeries = [
      { label: "Julio", data: julioPessoal, color: "#4a7ab8", align: "top" },
      { label: "Dani", data: daniPessoal, color: "#c97070", align: "bottom" },
    ];

    if (activeTab === "historico") {
      revealHistoricoCanvases_();
      drawLineChart_("chart-historico-total", "historicoTotal", meses, totalSeries);
      drawLineChart_("chart-historico-pessoal", "historicoPessoal", meses, pessoalSeries);
      chartPending.historicoTotal = null;
      chartPending.historicoPessoal = null;
    } else {
      chartPending.historicoTotal = { months: meses, series: totalSeries };
      chartPending.historicoPessoal = { months: meses, series: pessoalSeries };
    }
  }
```

- [ ] **Step 5: Remover a função `clearHistoricoSkeleton` (substituída por `revealHistoricoCanvases_`)**

Localizar `function clearHistoricoSkeleton()` em [src/dashboard/Script.html](src/dashboard/Script.html) e DELETAR a função inteira.

Verificar que não há mais usos: `grep -n "clearHistoricoSkeleton" src/dashboard/Script.html` deve retornar nenhuma linha.

- [ ] **Step 6: Push e verificar lazy render**

Run: `.\node_modules\.bin\clasp.cmd push -f`

Cenários a testar (com DevTools console aberto, Network tab aberto):

1. **Carregamento inicial em "Mês":** página abre na aba Mês. Tiles + tabelas pessoa renderizam. Aba Cartão e Histórico ficam hidden. Charts NÃO devem ser desenhados (Chart.js init não dispara). Skeleton dos charts permanece dentro dos panels.

2. **Click em "Cartão":** `#tab-cartao` mostra. Chart rateio renderiza naquele momento (skeleton some, canvas com barras aparece).

3. **Click em "Histórico":** `#tab-historico` mostra. Os 2 line charts renderizam.

4. **Voltar pra "Mês" e trocar mês no selector:** tabela pessoa atualiza com dados do novo mês. Charts da Cartão ficam pendentes (com dados novos). Click em "Cartão" → re-renderiza com dados do novo mês.

5. **Recarregar com aba "Histórico" salva:** ao iniciar, `setActiveTab("historico")` é chamado em `init()`, mas `chartPending.historico*` ainda é `null` (data ainda não chegou). Quando `getHistoricalSummary` resolver, `renderHistoricoFromSummary` vê `activeTab === "historico"` e renderiza imediatamente.

- [ ] **Step 7: Commit**

```bash
git add src/dashboard/Script.html
git commit -m "feat(dashboard): lazy-render charts per active sub-tab"
```

---

## Task 8: CSS — chart-wrap layout fix (skeleton + canvas + error)

**Files:**
- Modify: `src/dashboard/Stylesheet.html`

- [ ] **Step 1: Validar que regras de `.chart-wrap` herdadas estão corretas**

Em [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html), confirmar que o bloco `/* Charts */` ainda contém o seguinte (introduzido na entrega anterior):

```css
  .chart-wrap {
    position: relative;
    height: 240px;
  }
  .chart-wrap > .skeleton-chart,
  .chart-wrap > canvas {
    position: absolute;
    inset: 0;
  }
  .chart-wrap > .error {
    position: absolute;
    inset: 0;
    display: grid;
    place-items: center;
    margin: 0;
    color: var(--negative);
    font-size: 0.9rem;
    text-align: center;
    padding: 0.5rem;
  }
  .history .chart-wrap {
    height: 280px;
  }
  select:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
```

Se algum desses estiver ausente (improvável, mas validar), adicionar.

- [ ] **Step 2: Aumentar altura mínima dos charts em mobile**

Substituir o bloco `.chart-wrap { ... }` (sem o `.history` qualifier) por:

```css
  .chart-wrap {
    position: relative;
    height: 280px;
  }
```

E o `.history .chart-wrap` por:

```css
  .history .chart-wrap {
    height: 320px;
  }
```

(Em ≥640px e ≥1024px, as media queries existentes da Task 3 já garantem altura adequada com 280px e 300px.)

- [ ] **Step 3: Push e verificar charts com altura adequada**

Run: `.\node_modules\.bin\clasp.cmd push -f`

DevTools 360px: trocar pra aba Cartão. Chart deve ter ~280px. Trocar pra Histórico: charts ~320px. Sem sobreposição de labels.

- [ ] **Step 4: Commit**

```bash
git add src/dashboard/Stylesheet.html
git commit -m "style(dashboard): increase chart minimum height"
```

---

## Task 9: Verificação end-to-end

- [ ] **Step 1: Push final + abrir webapp**

Run: `.\node_modules\.bin\clasp.cmd push -f`

Run (em background ou aba separada): `.\node_modules\.bin\clasp.cmd open --webapp --deploymentId AKfycbyodB4jZEEe-6qnS-eWI7UNSFEDQUgLPXeB1Yb2tcIK`

(O deploymentId @HEAD foi obtido em sessão anterior. Se quiser confirmar: `.\node_modules\.bin\clasp.cmd deployments` e usar o `@HEAD`.)

- [ ] **Step 2: Checklist de aceitação — Mobile (DevTools 360px)**

- [ ] Bottom nav fixa com Consulta amarela ativa, Detalhe e Lançamento cinza inativos.
- [ ] Sticky header (1 card combinado com selector + 3 mini-KPIs em 3 col) gruda no topo ao scrollar.
- [ ] Sub-abas (Mês/Cartão/Histórico) full-width, segmented control.
- [ ] Aba Mês: Júlio acima, Dani abaixo (1 col).
- [ ] Aba Cartão: categoria acima, pessoa abaixo (1 col). Chart aparece ao ativar a aba (lazy).
- [ ] Aba Histórico: total acima, pessoal abaixo (1 col). Charts aparecem ao ativar (lazy).
- [ ] Trocar mês no selector mantém aba ativa.
- [ ] Recarregar página mantém aba ativa.
- [ ] Click em Detalhe / Lançamento: nada acontece (botão disabled).

- [ ] **Step 3: Checklist de aceitação — Tablet (DevTools 768px)**

- [ ] Body centralizado com max-width 720px (margens cinza laterais visíveis).
- [ ] Top nav (Consulta/Detalhe/Lançamento) no topo, antes do header.
- [ ] Header em 4 cards inline (selector + 3 totais).
- [ ] Aba Mês: Júlio + Dani em 2 col side-by-side.
- [ ] Aba Cartão: categoria + pessoa em 2 col side-by-side.
- [ ] Aba Histórico: 1 col (cada chart linha cheia).

- [ ] **Step 4: Checklist de aceitação — Desktop (DevTools 1280px)**

- [ ] Idêntico ao tablet (max-width 720px), mais margens cinza nas laterais.
- [ ] KPI strong fonte 1.6rem (pouco maior que tablet).

- [ ] **Step 5: Checklist regressão**

- [ ] Webhook não regrediu: enviar uma despesa via POST com token (ex: `curl -X POST -d "..."`); recarregar dashboard; nova linha aparece no mês corrente.
- [ ] Endpoint `?action=data&token=X` ainda retorna JSON (com novas linhas).
- [ ] Login flow ainda funciona: limpar `localStorage.hook-finance-token`, recarregar, formulário de token aparece, submeter token válido entra no dashboard.
- [ ] Console DevTools: zero erros JS em qualquer aba.
- [ ] Network DevTools: ao trocar de mês, **somente** chamadas de `getMonthData` (uma só); `getHistoricalSummary` não dispara de novo.

- [ ] **Step 6: Commit do ajuste final caso necessário**

Se algum ajuste de polimento for necessário durante a verificação:

```bash
git add src/dashboard/...
git commit -m "fix(dashboard): <descrição do ajuste>"
```

Se tudo passou sem ajuste, pular este step.

---

## Pós-implementação

Após todas as tasks passarem na verificação:

1. Não fazer merge automaticamente em `main`. Aguardar comando do usuário.
2. Branch atual: `feat/dashboard-responsivo` (criar antes do Task 1 se ainda estiver em main).
3. Quando autorizado, FF merge em main + push origin main + delete branch local + (opcional) criar nova versão de deploy GH Action.

---

## Self-Review checklist (executado durante a escrita)

- ✅ **Spec coverage:** Hierarquia de navegação (Tasks 1, 4); viewports (Tasks 3, 4, 5); aba persistente (Task 2); lazy render (Task 7); body max-width 720px (Task 3); pessoa 2-col tablet+ (Task 3 via `.people` grid); cartão 2-col tablet+ (Task 3 via `.lower` grid); histórico 1-col (default sem grid override); Detalhe/Lançamento desabilitados (Tasks 1, 4); chart min-height (Task 8); verification (Task 9).
- ✅ **Placeholder scan:** Sem TBD/TODO. Sem "implementar depois". Cada step tem código completo.
- ✅ **Type consistency:** `chartPending` declarado em Task 7 Step 1. `setActiveTab`/`flushPendingCharts` consistentes em Tasks 2/7. IDs HTML (`tab-mes`, `tab-cartao`, `tab-historico`) consistentes em HTML (Task 1) e JS (Tasks 2, 7).
