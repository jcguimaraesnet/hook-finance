# PWA Migration — React + Vite + Tailwind v4 + Azure SWA + Apps Script (REST)

## Context

O dashboard hoje é um Google Apps Script web app que renderiza HTML/CSS/JS via `doGet`+template scriptlets, com chamadas client-server via `google.script.run`. O usuário quer **experiência próxima de app nativo no PC, Android e iPhone** sem o ônus de publicar nas lojas. Solução proposta: PWA React, hospedada em Azure Static Web Apps, mantendo o Apps Script atual como backend (acesso à planilha + webhook das notificações de cartão), exposto via endpoints REST.

Esta migração é grande: troca a UI inteira (vanilla → React), troca o CSS inteiro (atual → Tailwind v4), introduz proxy CORS via Azure Function, e refatora o backend pra dispatcher REST. Webhook e Sheets permanecem inalterados.

## Estado atual (inventário)

**Frontend Apps Script (a substituir):**
- `src/dashboard/Index.html` — HTML estático (login, dashboard, modais)
- `src/dashboard/Stylesheet.html` — CSS (mobile-first, breakpoints 640/750/1024, color-scheme light only)
- `src/dashboard/Script.html` — JS (~900 linhas) — todas as chamadas `google.script.run.*` + Chart.js + lógica de UI

**Backend Apps Script (a manter, refatorando dispatch):**
- `src/dashboard/Dashboard.gs` — `doGet` (HTML) + `doPost` (n/a hoje no doPost; webhook está em Webhook.gs); funções expostas: `getMonthData`, `getHistoricalSummary`, `getLastEntries`, `updateEntry`, `deleteEntry`
- `src/webhook/Webhook.gs` — `doPost` para POSTs de notificação de cartão
- `src/webhook/Classifier.gs`, `src/webhook/FixedExpenses.gs` — lógica do webhook
- `src/shared/Helpers.gs`, `src/shared/Constants.gs`, `src/shared/Setup.gs`

**Deploy atual:**
- `.clasp.json` (rootDir: `src`)
- `.claspignore`
- `.github/workflows/deploy.yml` — push em main → `clasp push -f` + `clasp deploy -i <PROD_ID>`

## Estado-alvo (arquitetura)

```
Hoje
┌────────────────────────────────────────────┐
│ Browser → script.google.com/.../exec       │
│   HTML + CSS + JS (google.script.run)      │
└────┬───────────────────────────────────────┘
     ▼
┌────────────────────────────────────────────┐
│ Apps Script (Dashboard.gs, Webhook.gs)     │
│   ↓ Google Sheets                          │
└────────────────────────────────────────────┘

Alvo
┌────────────────────────────────────────────┐
│ Browser (PWA instalável)                   │
│   <app>.azurestaticapps.net                │
│   React app + Service Worker               │
└────┬───────────────────────────────────────┘
     │ fetch /api/proxy (mesma origem, sem CORS)
     ▼
┌────────────────────────────────────────────┐
│ Azure Function /api/proxy                  │
│   forward GET/POST → Apps Script /exec     │
└────┬───────────────────────────────────────┘
     │ fetch server-to-server (sem CORS)
     ▼
┌────────────────────────────────────────────┐
│ Apps Script (modo REST)                    │
│   doGet?action=monthData&token=...         │
│   doPost { action, ... }                   │
│   ↓ Google Sheets                          │
└────────────────────────────────────────────┘

Webhook (inalterado)
   Tasker/IFTTT → POST script.google.com/.../exec → Webhook.gs → Sheets
```

## Decisões fixadas

| Tópico | Escolha |
|---|---|
| Linguagem | **TypeScript** |
| CSS | **Tailwind CSS v4** (rewrite visual) |
| CORS | **Azure Function** em `/api/proxy` (mesma origem) |
| Charts | **Chart.js v4 + react-chartjs-2** |
| State | **Zustand** (simples, sem boilerplate Redux/Context) |
| Data fetch | **Tanstack Query** (cache, retry, loading) |
| Routing | **React Router v6** |
| Build | **Vite 5** + **vite-plugin-pwa** |
| Hosting | **Azure Static Web Apps** (free tier) |
| API runtime | **Azure Functions Node.js v4** |

## Estrutura final do monorepo

```
hook-finance/
├── apps-script/                       # MOVIDO de src/
│   ├── appsscript.json
│   ├── dashboard/
│   │   └── Dashboard.gs               # Backend: dispatcher REST (sem HTML)
│   ├── shared/                        # Helpers.gs, Constants.gs, Setup.gs
│   └── webhook/                       # Webhook.gs, Classifier.gs, FixedExpenses.gs
├── web/                               # NOVO: React PWA
│   ├── public/
│   │   ├── icon-192.png
│   │   ├── icon-512.png
│   │   ├── apple-touch-icon.png
│   │   └── favicon.svg
│   ├── src/
│   │   ├── api/
│   │   │   ├── client.ts              # Fetch wrapper (chama /api/proxy)
│   │   │   ├── endpoints.ts           # Métodos: getMonthData, updateEntry, etc.
│   │   │   └── types.ts               # Row, Entry, HistorySummary, etc.
│   │   ├── components/
│   │   │   ├── PrimaryNav.tsx
│   │   │   ├── StickyHeader.tsx
│   │   │   ├── SubTabs.tsx
│   │   │   ├── PersonCard.tsx
│   │   │   ├── DiffToggle.tsx
│   │   │   ├── EditModal.tsx
│   │   │   ├── ChartLine.tsx
│   │   │   ├── ChartBar.tsx
│   │   │   ├── Skeleton.tsx
│   │   │   └── ErrorBoundary.tsx
│   │   ├── pages/
│   │   │   ├── LoginPage.tsx
│   │   │   ├── ConsultaPage.tsx
│   │   │   ├── DetalhePage.tsx
│   │   │   ├── LancamentoPage.tsx
│   │   │   └── AcertoPage.tsx
│   │   ├── hooks/
│   │   │   ├── useToken.ts
│   │   │   ├── useMonthData.ts
│   │   │   ├── useHistoricalSummary.ts
│   │   │   ├── useLastEntries.ts
│   │   │   └── useLocalToggle.ts
│   │   ├── store/
│   │   │   └── useAppStore.ts         # Zustand: activePage, activeTab, currentMonth, etc.
│   │   ├── utils/
│   │   │   ├── format.ts              # Money, parcelaTotal, moneyK
│   │   │   ├── dates.ts               # parseBrDate, monthName
│   │   │   └── splitForPerson.ts
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   └── index.css                  # @import "tailwindcss" + @theme
│   ├── api/                           # Azure Functions (deployadas com SWA)
│   │   ├── proxy/
│   │   │   ├── index.ts
│   │   │   └── function.json          # ou usar v4 programmatic model
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── host.json
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── tailwind.config.ts             # Opcional em v4 (CSS-first); usar pra tokens custom
│   ├── postcss.config.js              # Tailwind v4 dispensa em alguns setups
│   └── staticwebapp.config.json       # Roteamento SPA + headers
├── .github/workflows/
│   ├── deploy-apps-script.yml         # Renomear de deploy.yml; paths: apps-script/**
│   └── deploy-web.yml                 # NOVO: Azure SWA action
├── .clasp.json                        # rootDir: "apps-script"
├── .claspignore
├── package.json                       # Root: workspaces + scripts agregados
├── README.md                          # Atualizar
└── CLAUDE.md                          # Atualizar
```

## Mapeamento dos endpoints REST (Apps Script)

Refatorar `Dashboard.gs` (backend) para que `doGet` e `doPost` despachem por `action`. O webhook continua em `Webhook.gs` mas precisamos garantir que `doPost` no Webhook só responda quando o body tem `title`+`text` (notificação), e delegue ao `Dashboard.gs` quando tem `action`.

Idealmente: **um único `doPost` em `Dashboard.gs`** que trata os dois casos (webhook e REST), e Webhook.gs deixa de definir `doPost` (vira só helper). Apps Script só permite um `doPost`/`doGet` global.

Endpoints alvo:

| Método | URL (via proxy) | Action | Apps Script function |
|---|---|---|---|
| GET | `/api/proxy?action=monthData&token=X&month=...` | `monthData` | `getMonthData(token, month)` |
| GET | `/api/proxy?action=historicalSummary&token=X` | `historicalSummary` | `getHistoricalSummary(token)` |
| GET | `/api/proxy?action=lastEntries&token=X&n=10` | `lastEntries` | `getLastEntries(token, n)` |
| POST | `/api/proxy` body `{action:"updateEntry",token:..., row, fields}` | `updateEntry` | `updateEntry(token, row, fields)` |
| POST | `/api/proxy` body `{action:"deleteEntry",token:..., row}` | `deleteEntry` | `deleteEntry(token, row)` |
| POST | `/api/proxy` body `{title, text, token}` (legado, do Tasker) | webhook | mesmo doPost de hoje |

## Tarefas — fases sequenciais

### Phase A — Monorepo prep + REST dispatcher backend

1. **Renomear `src/` → `apps-script/`** e atualizar `.clasp.json` (`rootDir: "apps-script"`).
2. **Atualizar `.github/workflows/deploy.yml`** → renomear pra `deploy-apps-script.yml`; paths filter: `apps-script/**`, `.clasp.json`, `.claspignore`, `package.json`.
3. **Refatorar `Dashboard.gs`**: `doGet` despacha por `e.parameter.action`; novo `doPost` único na raiz que olha o body — se tem `title`+`text`, chama o handler do webhook; se tem `action`, despacha pra `updateEntry`/`deleteEntry`.
4. **Mover `doPost` antigo de `Webhook.gs`** para uma função privada `handleWebhookBody_(body)`. `Webhook.gs` perde o `doPost` global.
5. Validar local: `clasp push -f` + curl manual aos endpoints (confirmar JSON de resposta).
6. **Manter os arquivos `Index.html`, `Script.html`, `Stylesheet.html` funcionando** durante a migração (eles ainda usam `google.script.run` — esse caminho continua válido enquanto não for retirado em Phase G).

### Phase B — Inicializar React PWA

1. `cd hook-finance && mkdir web && cd web`
2. `npm create vite@latest . -- --template react-ts`
3. Adicionar deps:
   ```bash
   npm i react-router-dom@7 zustand @tanstack/react-query chart.js react-chartjs-2 chartjs-plugin-datalabels
   npm i -D vite-plugin-pwa workbox-window tailwindcss@next @tailwindcss/vite
   ```
4. Criar `vite.config.ts` com `@tailwindcss/vite` plugin + `vite-plugin-pwa` config (registerType `autoUpdate`, manifest inline, workbox runtime cache pra `/api/proxy?action=monthData*` e `historicalSummary*`).
5. Criar `src/index.css` com `@import "tailwindcss"; @theme { --color-bg: #faf8f5; --color-fg: #262626; --color-accent: #f4d35e; ... }` espelhando os tokens atuais.
6. `npm run dev` — verificar página default React rodando.

### Phase C — Core infrastructure

1. **`src/api/client.ts`** — wrapper `fetch` que sempre passa pelo `/api/proxy`:
   ```typescript
   const BASE = import.meta.env.VITE_API_BASE || "/api/proxy";
   export async function apiGet<T>(action: string, params: Record<string,string>): Promise<T> { ... }
   export async function apiPost<T>(action: string, body: unknown): Promise<T> { ... }
   ```
   POSTs sempre com `Content-Type: text/plain` (workaround histórico do Apps Script — desnecessário aqui porque o proxy resolve, mas mantém compat se um dia rodar sem proxy).
2. **`src/api/endpoints.ts`** — funções tipadas: `getMonthData(month?)`, `getHistoricalSummary()`, `getLastEntries(n)`, `updateEntry(row, fields)`, `deleteEntry(row)`. Cada uma chama o cliente com action correta + injeta token do store.
3. **`src/api/types.ts`** — interfaces espelhando os mapRow_ do backend: `Row`, `Entry`, `HistorySummary`, `MonthDataResponse`, etc.
4. **`src/store/useAppStore.ts`** (Zustand) — estado global: `token`, `activePage`, `activeTab`, `currentMonth`, `acertoMonth`, toggles de Diff, Acerto-Pix-Julio. Persistir o que precisa em `localStorage` via middleware `persist`.
5. **`src/utils/format.ts`** — port das helpers atuais: `Money` (Intl), `Pct`, `moneyK`, `parcelaTotal`, `splitForPerson`.
6. **`main.tsx`** — wrap App em `QueryClientProvider` e `BrowserRouter`.

### Phase D — Páginas e componentes

Cada página é um componente React substituindo o panel HTML correspondente. Reaproveitar tokens Tailwind do tema.

1. **`LoginPage`** — input token + submit; valida via uma chamada GET de teste (ex: `getMonthData(currentMonth)` vazio); salva em store + localStorage.
2. **App shell** (`App.tsx`):
   - `<PrimaryNav>` (Consulta/Detalhe/Lançamento/Acerto). Mobile = bottom-fixed; tablet+ = top.
   - `<Routes>` com cada page.
3. **`ConsultaPage`**:
   - `<StickyHeader>` (selector + 3 KPIs)
   - `<SubTabs>` (Mês/Categoria/Pessoal/Histórico)
   - Sub-componentes: `<PersonCard>` (com `<DiffToggle>`), `<CategoriaTable>`, `<RateioChart>` (Chart.js bar), `<HistoricoChart>` x2 (Chart.js line).
   - PC Web (≥750px): esconde `<SubTabs>` e renderiza tudo numa página só (igual ao layout atual).
4. **`DetalhePage`**:
   - Selector próprio (sincronizado com `currentMonth`)
   - Lista de pessoas em `<details>`/`<summary>` (ou um `<Accordion>` componente)
5. **`LancamentoPage`**:
   - Subtítulo "Mês corrente: maio de 2026"
   - Lista das últimas 10 (`useLastEntries`)
   - Click → abre `<EditModal>` full-screen com fields + parcela stepper
   - Salvar/Excluir → `useMutation` do Tanstack Query → invalida `lastEntries` cache
6. **`AcertoPage`**:
   - Selector com mês anterior pré-selecionado
   - 2 cards Júlio + Dani (1-col mobile, 2-col tablet+)
   - Toggle escondido no label "Pix (contas)" do Julio (estado em Zustand persistido)

### Phase E — PWA features

1. **`vite-plugin-pwa` config**:
   ```typescript
   VitePWA({
     registerType: "autoUpdate",
     includeAssets: ["favicon.svg", "apple-touch-icon.png"],
     manifest: {
       name: "hook-finance",
       short_name: "hook-finance",
       theme_color: "#f4d35e",
       background_color: "#faf8f5",
       display: "standalone",
       orientation: "portrait",
       icons: [
         { src: "icon-192.png", sizes: "192x192", type: "image/png" },
         { src: "icon-512.png", sizes: "512x512", type: "image/png" },
         { src: "icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
       ],
     },
     workbox: {
       runtimeCaching: [
         {
           urlPattern: /\/api\/proxy\?action=(monthData|historicalSummary)/,
           handler: "NetworkFirst",
           options: { cacheName: "api", expiration: { maxAgeSeconds: 3600 } },
         },
       ],
     },
   })
   ```
2. **Ícones**: gerar `icon-192.png` e `icon-512.png` (tema beige + acento amarelo). Usar `pwa-asset-generator` ou criar manual.
3. **Install prompt**: capturar evento `beforeinstallprompt`, expor no UI um botão "Instalar app" (mobile sticky bottom; desktop banner).
4. **iOS specifics**: `apple-touch-icon.png` 180x180 + meta tags `apple-mobile-web-app-capable`/`apple-mobile-web-app-status-bar-style` no `index.html`.
5. **Offline fallback**: rota `/offline.html` servida quando o SW detecta falha de rede e cache vazio.

### Phase F — Azure SWA + Function deploy

1. **Criar Azure SWA** (CLI ou portal):
   - SKU: Free
   - Source: GitHub (repo do user)
   - App location: `web/`
   - Api location: `web/api/`
   - Output location: `dist/`
   - Token (deployment) salvo como secret `AZURE_STATIC_WEB_APPS_API_TOKEN_*` no GitHub
2. **`web/api/proxy/`** — Azure Function v4:
   ```typescript
   import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
   const APPS_SCRIPT_URL = process.env.APPS_SCRIPT_URL!;
   app.http("proxy", {
     methods: ["GET", "POST"],
     authLevel: "anonymous",
     handler: async (req: HttpRequest, _ctx: InvocationContext): Promise<HttpResponseInit> => {
       const targetUrl = new URL(APPS_SCRIPT_URL);
       if (req.method === "GET") {
         for (const [k, v] of req.query) targetUrl.searchParams.set(k, v);
         const r = await fetch(targetUrl, { redirect: "follow" });
         return { status: r.status, headers: { "content-type": "application/json" }, body: await r.text() };
       }
       const body = await req.text();
       const r = await fetch(targetUrl, {
         method: "POST",
         headers: { "content-type": "text/plain" },
         body, redirect: "follow",
       });
       return { status: r.status, headers: { "content-type": "application/json" }, body: await r.text() };
     },
   });
   ```
3. **Configurar env var `APPS_SCRIPT_URL`** no Azure SWA (Configuration → Application settings) apontando para o `/exec` do deployment de produção (`AKfycby7v9mr...`).
4. **`staticwebapp.config.json`**:
   ```json
   {
     "navigationFallback": { "rewrite": "/index.html", "exclude": ["/api/*", "/*.{png,svg,ico,webmanifest,js,css}"] },
     "globalHeaders": { "Cache-Control": "no-cache" },
     "routes": [
       { "route": "/api/*", "allowedRoles": ["anonymous"] }
     ]
   }
   ```
5. **`.github/workflows/deploy-web.yml`** — usar action `Azure/static-web-apps-deploy@v1` com paths filter em `web/**`.

### Phase G — Cutover

1. Rodar **PWA + Apps Script HTML em paralelo** por algumas semanas (URLs separadas).
2. Atualizar bookmark/PWA install para a nova URL Azure.
3. Quando estável, remover `apps-script/dashboard/Index.html`, `Script.html`, `Stylesheet.html` (HTML antigo). Apps Script vira backend puro.
4. `doGet` antigo pode retornar uma página "Redirect → <PWA URL>" ou `405 Method Not Allowed` para HTML.

## Especificações críticas (skeletons)

### Apps Script — `apps-script/dashboard/Dashboard.gs` (dispatcher)

```javascript
function doGet(e) {
  const action = (e && e.parameter && e.parameter.action) || "";
  switch (action) {
    case "monthData":
      return jsonResponse_(getMonthData(e.parameter.token, e.parameter.month || null));
    case "historicalSummary":
      return jsonResponse_(getHistoricalSummary(e.parameter.token));
    case "lastEntries":
      return jsonResponse_(getLastEntries(e.parameter.token, parseInt(e.parameter.n, 10) || 10));
    case "data": // legacy /exec?action=data
      return jsonResponse_(readAllForApi_(e.parameter.token));
    default:
      return jsonResponse_({ ok: false, error: "unknown_action" });
  }
}

function doPost(e) {
  let body;
  try { body = JSON.parse(e.postData.contents || "{}"); }
  catch (_) { return jsonResponse_({ ok: false, error: "invalid_json" }); }

  // Caminho legado do webhook (Tasker/IFTTT envia title+text)
  if (body.title && body.text) {
    return jsonResponse_(handleWebhookBody_(body));
  }

  // Caminho REST
  switch (body.action) {
    case "updateEntry":
      return jsonResponse_(updateEntry(body.token, body.row, body.fields));
    case "deleteEntry":
      return jsonResponse_(deleteEntry(body.token, body.row));
    default:
      return jsonResponse_({ ok: false, error: "unknown_action" });
  }
}
```

`Webhook.gs`: extrair lógica do `doPost` antigo para `function handleWebhookBody_(body) { ... return { ok, error? } }`. Remover o `doPost` global de lá.

### `web/vite.config.ts`

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({ /* ver Phase E */ }),
  ],
  server: {
    proxy: {
      "/api": "http://localhost:7071", // Azure Functions Core Tools local
    },
  },
});
```

### `web/src/api/client.ts`

```typescript
import { useAppStore } from "@/store/useAppStore";

const BASE = "/api/proxy";

export async function apiGet<T>(action: string, params: Record<string, string | number | null | undefined> = {}): Promise<T> {
  const url = new URL(BASE, window.location.origin);
  url.searchParams.set("action", action);
  url.searchParams.set("token", useAppStore.getState().token || "");
  for (const [k, v] of Object.entries(params)) {
    if (v != null) url.searchParams.set(k, String(v));
  }
  const r = await fetch(url, { method: "GET" });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

export async function apiPost<T>(action: string, body: object): Promise<T> {
  const r = await fetch(BASE, {
    method: "POST",
    headers: { "Content-Type": "text/plain" },
    body: JSON.stringify({ action, token: useAppStore.getState().token, ...body }),
  });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}
```

### `web/src/store/useAppStore.ts` (Zustand + persist)

```typescript
import { create } from "zustand";
import { persist } from "zustand/middleware";

interface AppState {
  token: string | null;
  activePage: "consulta" | "detalhe" | "lancamento" | "acerto";
  activeTab: "mes" | "categoria" | "pessoal" | "historico";
  currentMonth: string | null;
  acertoMonth: string | null;
  diffToggleJulio: boolean;
  diffToggleDani: boolean;
  acertoPixJulio: boolean;
  setToken: (t: string | null) => void;
  setActivePage: (p: AppState["activePage"]) => void;
  setActiveTab: (t: AppState["activeTab"]) => void;
  setCurrentMonth: (m: string | null) => void;
  setAcertoMonth: (m: string | null) => void;
  toggleDiff: (p: "Julio" | "Dani") => void;
  toggleAcertoPix: () => void;
}

export const useAppStore = create<AppState>()(persist(
  (set) => ({
    token: null,
    activePage: "consulta",
    activeTab: "mes",
    currentMonth: null,
    acertoMonth: null,
    diffToggleJulio: false,
    diffToggleDani: false,
    acertoPixJulio: false,
    setToken: (t) => set({ token: t }),
    setActivePage: (p) => set({ activePage: p }),
    setActiveTab: (t) => set({ activeTab: t }),
    setCurrentMonth: (m) => set({ currentMonth: m }),
    setAcertoMonth: (m) => set({ acertoMonth: m }),
    toggleDiff: (p) => set((s) => p === "Julio" ? { diffToggleJulio: !s.diffToggleJulio } : { diffToggleDani: !s.diffToggleDani }),
    toggleAcertoPix: () => set((s) => ({ acertoPixJulio: !s.acertoPixJulio })),
  }),
  { name: "hook-finance-store" },
));
```

## Verificação por fase

| Fase | Verificação |
|---|---|
| A | `clasp push -f` ok; `curl <exec>?action=monthData&token=X` retorna JSON; HTML antigo continua carregando via `/exec` |
| B | `npm run dev` abre página React; `npm run build` gera `dist/` |
| C | DevTools mostra fetch GET a `/api/proxy?action=monthData...`; em modo dev (sem Azure), proxy do Vite encaminha pro `localhost:7071` |
| D | Cada página renderiza dados reais; troca de mês refetcha; lazy chart render preservado via Tanstack Query |
| E | Lighthouse PWA score ≥90; chrome://serviceworker-internals mostra SW registrado; install prompt aparece em mobile |
| F | URL Azure SWA serve a app; F12 Network mostra `/api/proxy` retornando dados; deploy automático após push em main |
| G | App antigo retirado; PWA instalada nos devices do user; webhook continua funcionando |

## Riscos e itens em aberto

- **Bundle size**: Chart.js + Tanstack Query + React + Router pode passar de 200kb gzipped. Mitigação: code-splitting por rota com `React.lazy`.
- **iOS PWA limitations**: sem push notifications nativo, install prompt menos óbvio (Safari → Share → Add to Home Screen). Documentar no README pra usuário leigo.
- **Azure SWA free tier**: 100GB bandwidth/mês, suficiente. Se exceder, app cai. Monitorar.
- **Apps Script latency**: ~1-2s por request via proxy. Cache via Tanstack Query mitiga; offline cache via SW pra leituras.
- **Auth**: token em localStorage exposto a XSS. Pra projeto pessoal aceitável; se evoluir, considerar OAuth/Google Sign-In.
- **Auto-dark do Chrome**: PWA standalone pode reaplicar auto-dark em alguns Android. Manter `color-scheme: light only` no Tailwind theme.
- **Migração de dados**: nenhuma — Sheets continua a fonte única de verdade.
- **Cutover do `doPost`**: cuidado pra não quebrar o webhook do Tasker durante a refatoração da Phase A. Validar com curl simulando a payload do webhook antes de mergear.

## Out of scope

- Auth além de token (OAuth, biometria)
- Reescrita do backend (Apps Script fica)
- Push notifications (limitado em iOS)
- Domínio customizado (later)
- Internacionalização (segue pt-BR fixo)
- Testes automatizados (sem framework até agora; manter manual)

## Estimativa rough

- Phase A: 1-2 horas
- Phase B: 1 hora
- Phase C: 2-3 horas
- Phase D: 6-10 horas (4 páginas + componentes + charts)
- Phase E: 2-3 horas
- Phase F: 2-4 horas (Azure setup + Function + workflow)
- Phase G: 1 hora + período de testes

**Total: ~15-25 horas de execução** (excluindo testes em produção e ajustes finos).
