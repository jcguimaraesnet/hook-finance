# hook-finance API (Azure Function proxy)

Proxy CORS para o Apps Script REST. Roda em Azure Static Web Apps na rota `/api/proxy`.

## Setup local

1. Instale Azure Functions Core Tools v4: <https://learn.microsoft.com/azure/azure-functions/functions-run-local>
2. Copie `local.settings.json.example` → `local.settings.json` e ajuste `APPS_SCRIPT_URL` se quiser testar contra outro deployment.
3. `pnpm install` na raiz do monorepo.
4. `pnpm --filter hook-finance-api build` (ou `watch` para hot reload).
5. `cd web/api && pnpm start` (ou `func start`). Função fica em `http://localhost:7071/api/proxy`.
6. O dev server do Vite (`pnpm dev` na raiz) já tem proxy `/api → localhost:7071`, então o React app chama `/api/proxy` direto.

## Setup no Azure SWA

1. Crie um Static Web App (SKU Free) apontando o repo `main` branch.
2. Build presets:
   - `app_location`: `web`
   - `api_location`: `web/api`
   - `output_location`: `dist`
3. Em **Configuration → Application settings**, defina:
   - `APPS_SCRIPT_URL` = `https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec`
4. Salve o token de deploy do SWA como secret `AZURE_STATIC_WEB_APPS_API_TOKEN` no GitHub repo settings.
5. O workflow `.github/workflows/deploy-web.yml` faz o build + deploy automático em cada push em `main`.
