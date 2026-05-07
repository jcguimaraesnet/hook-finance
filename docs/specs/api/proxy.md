---
status: stable
last_updated: 2026-05-07
---

# Proxy `/api/proxy` (Azure Function)

Bridge que o PWA usa para falar com o Apps Script sem CORS. Função única em [web/api/proxy/](../../../web/api/proxy/), hospedada pelo Azure Static Web Apps na mesma origem do PWA.

## Contexto

Apps Script publicado em `https://script.google.com/macros/s/.../exec` exige `Content-Type: text/plain` em POST para evitar preflight CORS. Mesmo assim, GET cross-origin do PWA causa atrito (cookies, Same-Site, redirects do Apps Script). O proxy elimina o problema: o PWA chama `/api/proxy?...` mesma origem; a Function repassa para o Apps Script.

O Flutter **não** usa o proxy — chama Apps Script direto, já que apps nativos não têm restrição CORS.

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
- **Flutter:** não usa este proxy — chama Apps Script direto.

## Specs relacionadas

- [endpoints.md](endpoints.md)
- [webhook.md](webhook.md)
