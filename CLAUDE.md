# hook-finance — Project Notes for Claude

Personal finance monorepo. Backend é Google Apps Script (REST + webhook); frontend é uma PWA React hospedada no Azure Static Web Apps; um Azure Function proxy faz a ponte. Toda a data vive em uma Google Sheet única. Um app Flutter (Android primeiro, iOS depois) está planejado.

## SOURCE OF TRUTH

**Regras de negócio vivem em [docs/specs/](docs/specs/README.md). Toda mudança de comportamento começa lá.**

1. Edite (ou crie) o spec relevante em `docs/specs/`.
2. Propague a mudança para `web/src/core/` (PWA). Ao existir, propague também para `app/lib/core/` (Flutter).
3. Ajuste `apps-script/` se a regra for de servidor.
4. Componentes/widgets consomem `core/` — **nunca** redefinem regras inline.

Mudanças puramente visuais (Tailwind, layout de widget) podem ir direto no código. Mudanças de schema da planilha ou contrato de API começam em `docs/specs/data/` ou `docs/specs/api/`.

Índice das specs: [docs/specs/README.md](docs/specs/README.md).

## Monorepo (pnpm workspace)

```
hook-finance/
├── apps-script/                # Backend GAS (REST dispatcher + webhook)
├── web/                        # PWA React (Vite + TS + Tailwind v4)
│   ├── src/core/               # Regras de negócio (espelha docs/specs/rules/)
│   └── api/                    # Azure Function /api/proxy
├── app/                        # (futuro) Flutter Android/iOS
├── docs/specs/                 # Fonte da verdade (regras, cards, páginas, API)
├── .github/workflows/          # deploy-apps-script.yml, deploy-web.yml
├── pnpm-workspace.yaml
└── package.json
```

`pnpm install` na raiz. `pnpm dev` roda o PWA. `pnpm --filter hook-finance-web test` roda os testes do core.

## Architecture (resumo)

- **Backend**: `doGet`/`doPost` em [Dashboard.gs](apps-script/dashboard/Dashboard.gs) despacham por `action`. Webhook reusa `doPost` quando body tem `title`+`text`. Detalhes em [docs/specs/api/](docs/specs/api/).
- **PWA**: React 18 + Vite 5 + Tailwind v4 + Zustand + Tanstack Query + Chart.js. Detalhes de páginas/cards em [docs/specs/pages/](docs/specs/pages/) e [docs/specs/cards/](docs/specs/cards/).
- **Proxy**: Azure Function `/api/proxy` (web/api/) — bridge same-origin para o Apps Script.
- **Deploy**: GH Actions (`deploy-apps-script.yml`, `deploy-web.yml`). Local clasp: `./node_modules/.bin/clasp.cmd push -f`.

## Conventions

- UI em pt-BR. Money via `Intl.NumberFormat("pt-BR")`, prefixo `R$` inline. Datas como string `"DD/MM/YYYY"`.
- Funções com `_` no final em Apps Script são privadas.
- Comentários só quando o **porquê** não é óbvio. Nunca descrevam o **o quê**.
- Em arquivos de `web/src/core/` e `app/lib/core/`: comentário `// Spec: docs/specs/...` no topo.

Detalhes em [docs/specs/conventions.md](docs/specs/conventions.md).

## Plan + spec docs (sessão Claude)

- Plans de implementação: `.claude/plans/YYYY-MM-DD-<feature>.md`.
- Specs de design (brainstorming): `.claude/specs/YYYY-MM-DD-<feature>-design.md`.
- `docs/specs/` é diferente: fonte da verdade do produto, vive no repo, é load-bearing.
- `.superpowers/` é gitignored.
