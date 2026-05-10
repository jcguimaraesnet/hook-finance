# hook-finance — Project Notes for Claude

Personal finance monorepo. Backend é Google Apps Script (REST + webhook); frontend é um app **Flutter** distribuído em duas formas a partir do **mesmo codebase**: APK Android e PWA web hospedada no Azure Static Web Apps. Um Azure Function proxy faz a ponte. Toda a data vive em uma Google Sheet única.

A versão PWA antiga em React (em `web/src/` + `web/public/` + `web/dist/`) está **congelada**: não é mais deployada e será removida em cleanup futuro. Continua no repo apenas como referência. O proxy `web/api/` (Azure Function) é o único conteúdo de `web/` ainda em uso.

## SOURCE OF TRUTH

**Regras de negócio vivem em [docs/specs/](docs/specs/README.md). Toda mudança de comportamento começa lá.**

1. Edite (ou crie) o spec relevante em `docs/specs/`.
2. Propague a mudança para `app/lib/core/` (Flutter — fonte do APK e da PWA).
3. Ajuste `apps-script/` se a regra for de servidor.
4. Componentes/widgets consomem `core/` — **nunca** redefinem regras inline.

> A pasta `web/src/core/` é histórico congelado. Não tocar.

Mudanças puramente visuais (Tailwind, layout de widget) podem ir direto no código. Mudanças de schema da planilha ou contrato de API começam em `docs/specs/data/` ou `docs/specs/api/`.

Índice das specs: [docs/specs/README.md](docs/specs/README.md).

## Direção visual

Direção **Bloom** — paleta lavanda+menta, bottom-nav 5 abas (Início · Compart · Lançamentos · Histórico · Acerto). Mesma identidade no APK e na PWA, vinda do mesmo `app/lib/`. Specs: `docs/specs/pages/{inicio,compart,historico,detalhe,lancamento,acerto}.md`.

A PWA React em `web/` (IA legada de 4 sub-tabs com `pages/consulta.md`) está fora do ar — substituída pela Flutter PWA na mesma URL.

## Monorepo

```
hook-finance/
├── apps-script/                # Backend GAS (REST dispatcher + webhook)
├── app/                        # Flutter — direção Bloom (APK Android + PWA web)
│   ├── lib/                    # Código compartilhado (core/, widgets/, features/)
│   ├── web/                    # Scaffold PWA (manifest, index.html, icons, SWA config)
│   └── tool/                   # Utilitários (ex.: generate_pwa_icons.py)
├── web/                        # 🟡 LEGADO congelado (PWA React, não deployada)
│   └── api/                    # Azure Function /api/proxy — único conteúdo ativo
├── docs/specs/                 # Fonte da verdade (regras, cards, páginas, API)
├── .github/workflows/          # deploy-apps-script.yml, deploy-web.yml, build-app.yml
├── pnpm-workspace.yaml
└── package.json
```

- **APK**: `cd app && flutter build apk --release` → `app/build/app/outputs/flutter-apk/app-release.apk`. Release manual via `gh release create`.
- **PWA**: `cd app && flutter build web --release` → `app/build/web/` → deploy automático no Azure SWA via [.github/workflows/deploy-web.yml](.github/workflows/deploy-web.yml).

## Architecture (resumo)

- **Backend**: `doGet`/`doPost` em [Dashboard.gs](apps-script/dashboard/Dashboard.gs) despacham por `action`. Webhook reusa `doPost` quando body tem `title`+`text`. Detalhes em [docs/specs/api/](docs/specs/api/).
- **App**: Flutter 3.x (Material 3) + Riverpod + GoRouter + fl_chart + dio + google_fonts (Bricolage Grotesque + Geist). Mesmo binário lógico para APK e PWA. Detalhes de páginas/cards em [docs/specs/pages/](docs/specs/pages/) e [docs/specs/cards/](docs/specs/cards/).
- **Proxy**: Azure Function `/api/proxy` ([web/api/](web/api/)) — bridge same-origin para o Apps Script. CORS habilitado (`*`) para permitir `flutter run -d chrome` local sem flags.
- **Deploy**: GH Actions (`deploy-apps-script.yml` para backend, `deploy-web.yml` para PWA Flutter, `build-app.yml` para analyze+test). Local clasp: `./node_modules/.bin/clasp.cmd push -f`.

## Conventions

- UI em pt-BR. Money via `Intl.NumberFormat("pt-BR")` (Dart: `package:intl`), prefixo `R$` inline. Datas como string `"DD/MM/YYYY"`.
- Funções com `_` no final em Apps Script são privadas.
- Comentários só quando o **porquê** não é óbvio. Nunca descrevam o **o quê**.
- Em arquivos de `app/lib/core/`: comentário `// Spec: docs/specs/...` no topo.

Detalhes em [docs/specs/conventions.md](docs/specs/conventions.md).

## Plan + spec docs (sessão Claude)

- Plans de implementação: `.claude/plans/YYYY-MM-DD-<feature>.md`.
- Specs de design (brainstorming): `.claude/specs/YYYY-MM-DD-<feature>-design.md`.
- `docs/specs/` é diferente: fonte da verdade do produto, vive no repo, é load-bearing.
- `.superpowers/` é gitignored.
