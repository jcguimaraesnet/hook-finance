# hook-finance API (Azure Function proxy — legacy model)

Proxy CORS para o Apps Script REST. Roda em Azure Static Web Apps em `/api/proxy`.

## Estrutura

Modelo legado de Azure Functions (function.json + index.js) — necessário porque SWA managed functions no free tier não suporta o modelo programmatic v4.

```
web/api/
├── host.json            # extensionBundle 4.x
├── package.json         # vazio (sem deps; usa global fetch do Node 20)
└── proxy/
    ├── function.json    # binding HTTP (GET + POST, anonymous)
    └── index.js         # handler — forward pro APPS_SCRIPT_URL
```

Sem build step. Sem TypeScript. Sem node_modules — tudo via runtime nativo do Node 20.

## Setup local

1. Instale Azure Functions Core Tools v4: <https://learn.microsoft.com/azure/azure-functions/functions-run-local>
2. Copie `local.settings.json.example` → `local.settings.json` e ajuste `APPS_SCRIPT_URL`.
3. `cd web/api && func start`. Função fica em `http://localhost:7071/api/proxy`.
4. O dev server do Vite (`pnpm dev` na raiz) já tem proxy `/api → localhost:7071`.

## Setup no Azure SWA

1. SWA criado via portal — recurso `polite-mushroom-...` (POLITE_MUSHROOM_0D3D07A0F).
2. Em **Configuration → Application settings**, defina `APPS_SCRIPT_URL` = `https://script.google.com/macros/s/AKfycby7v9mr.../exec`.
3. Workflow `.github/workflows/deploy-web.yml` faz o deploy automático.
