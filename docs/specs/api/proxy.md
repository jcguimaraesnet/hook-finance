---
status: stable
last_updated: 2026-05-07
---

# Proxy `/api/proxy` (Azure Function)

Bridge para falar com o Apps Script. Função única em [web/api/proxy/](../../../web/api/proxy/), hospedada pelo Azure Static Web Apps. Usada por **PWA** (same-origin, evita CORS) e por **Flutter** (URL hardcoded em `app/lib/api/config.dart` aponta para `<azure-swa>/api/proxy`).

## Contexto

Apps Script publicado em `https://script.google.com/macros/s/.../exec` exige `Content-Type: text/plain` em POST para evitar preflight CORS. Mesmo assim, GET cross-origin causa atrito (cookies, Same-Site, redirects do Apps Script). O proxy elimina o problema: PWA e Flutter chamam `/api/proxy?...`; a Function repassa para o Apps Script com a mesma querystring/body.

Apesar do Flutter não ter restrição CORS, ele também usa o proxy — assim o backend tem **uma única fronteira** (a env var `APPS_SCRIPT_URL` na Function). Trocar o deploy do Apps Script é mudança em um lugar só.

## Regras

- **GET `/api/proxy?action=...&token=...&...`** → Function faz GET na URL do Apps Script com a mesma querystring, retorna o body verbatim.
- **POST `/api/proxy`** com body JSON (`Content-Type: text/plain`) → Function faz POST no Apps Script com mesmo body, retorna verbatim.
- Status code da resposta **espelha** o do Apps Script (normalmente 200; erros vêm no body).
- Sem cache na Function (cache é responsabilidade do client/SW).
- Variável de ambiente `APPS_SCRIPT_URL` (set no Azure Portal, não em código).

## Edge cases

- **Sem `APPS_SCRIPT_URL` configurado:** Function retorna 500 com mensagem clara.
- **Apps Script timeout (raro):** repassa o erro HTTP. PWA deve tratar via `useQuery` retry.
- **Workbox SW cache:** `vite-plugin-pwa` configura NetworkFirst para `/api/proxy?action=monthData|historicalSummary` — ver Service Worker config no PWA.

## Implementações

- **Function:** [web/api/proxy/](../../../web/api/proxy/)
- **PWA dev:** Vite proxy em `vite.config.ts` redireciona `/api/*` → `localhost:7071` (Azure Functions Core Tools).
- **PWA prod:** Azure SWA serve `/api/*` direto.
- **Flutter:** URL hardcoded em [app/lib/api/config.dart](../../../app/lib/api/config.dart) (constante `kApiBase`, `String.fromEnvironment('API_BASE', defaultValue: '<azure-swa>/api/proxy')`). Override em build com `--dart-define=API_BASE=…`.

## Specs relacionadas

- [endpoints.md](endpoints.md)
- [webhook.md](webhook.md)
