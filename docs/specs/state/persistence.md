---
status: stable
last_updated: 2026-05-07
---

# Persistência de estado client-side

Define o que é persistido entre sessões, o que é por sessão, e o que é em memória apenas.

## Contexto

PWA usa Zustand (com `persist` middleware → localStorage) + sessionStorage avulso para toggles efêmeros + Tanstack Query (cache em memória, com TTL específico por hook). Flutter espelha o mesmo modelo via Riverpod + `shared_preferences`.

## Regras

### Persistido (sobrevive a fechar/reabrir o app)

**Storage key (PWA):** `hook-finance-store` (localStorage, via Zustand persist).
**Storage key (Flutter):** `hook_finance_store` (shared_preferences, namespace dos campos).

| Campo | Tipo | Default | Descrição |
|---|---|---|---|
| `token` | `string \| null` | `null` | WEBHOOK_TOKEN do Apps Script. Sem token → login screen. |
| `activePage` | `"consulta" \| "detalhe" \| "lancamento" \| "acerto"` | `"consulta"` | Aba primária. |
| `activeTab` | `"mes" \| "categoria" \| "pessoal" \| "historico"` | `"mes"` | Sub-tab de Consulta (mobile/tablet). |
| `acertoPixJulio` | `boolean` | `false` | Expande Pix do Júlio em Acerto. |

`partialize` no PWA garante que `currentMonth` e `allMonths` **NÃO** são persistidos.

### Sessão (perde ao fechar a aba/janela)

**Storage key (PWA):** `hook-finance-diff-${person}` em `sessionStorage`. Uma chave por pessoa.

| Campo | Tipo | Default | Descrição |
|---|---|---|---|
| `hook-finance-diff-Julio` | `"0" \| "1"` | `"1"` (visível) | Toggle Δ no PersonCard/AcertoCard de Júlio. |
| `hook-finance-diff-Dani` | `"0" \| "1"` | `"1"` (visível) | Idem Dani. |

Default = visível (`null` na chave → exibe Δ). Toggle persiste enquanto a aba viver.

**Flutter:** sessionStorage não existe. Equivalente: variável em memória que reseta ao reiniciar o app. Pode-se usar `Riverpod.autoDispose` ou state local. Não persistir entre sessões.

### Memória / refetch a cada sessão

| Campo | Tipo | Lugar | Descrição |
|---|---|---|---|
| `currentMonth` | `string \| null` | Zustand (não persistido) | Selecionado no dropdown do StickyHeader. Default `null` → backend escolhe o mais recente. |
| `allMonths` | `string[]` | Zustand (não persistido) | Lista de meses descendente; populado por `historicalSummary` no boot. |

### Tanstack Query — cache de dados

| Query key | Stale time | Notas |
|---|---|---|
| `["monthData", month]` | sem stale time explícito (cache infinito até refetch) | Invalidada por `useUpdateEntry`/`useDeleteEntry` no `onSuccess`. |
| `["historicalSummary"]` | `5 * 60_000` (5 min) | Histórico muda raramente; cache razoável. |
| `["lastEntries", n]` | sem stale time | Invalidada por mutations. |

Equivalente Flutter: usar `FutureProvider.family` para `monthData` (key = month), `FutureProvider.autoDispose` com cache custom de 5min para `historicalSummary`. Mutations invalidam via `ref.invalidate(provider)`.

### PWA install banner

| Storage | Key | Tipo | Descrição |
|---|---|---|---|
| `localStorage` | `hook-finance-install-dismissed` | `"1"` | Setada quando usuário fecha o banner. Suprime em visitas futuras. |

## Edge cases

- **Token inválido após restart:** boot tenta usar; `validateToken` no login dispara; se inválido, limpa e empurra para login. Não fica em loop.
- **`currentMonth` null no boot:** ConsultaPage espera resposta de `monthData` e auto-define para `data.month`. Único momento onde a Page precisa coordenar.
- **Aba duplicada (Ctrl+T):** `localStorage` é compartilhado; `sessionStorage` é por aba. Toggles de Δ são independentes por aba — esperado.
- **Modo privado/cookies bloqueados:** `localStorage`/`sessionStorage` podem dar throw. PWA atual já tem `try/catch` ao gravar — funciona em readonly mode (sem persist).

## Implementações

- **PWA:** [web/src/store/useAppStore.ts](../../../web/src/store/useAppStore.ts) (Zustand persist) + uso direto de `sessionStorage` em [PersonCard.tsx](../../../web/src/components/PersonCard.tsx) e [AcertoPage.tsx](../../../web/src/pages/AcertoPage.tsx).
- **Hooks de cache:** [web/src/hooks/](../../../web/src/hooks/).
- **Flutter:** `app/lib/state/auth_provider.dart`, `ui_provider.dart`, etc. (Onda 4).

## Specs relacionadas

- [../api/endpoints.md](../api/endpoints.md) — query keys e mutations
- [../cards/person-card.md](../cards/person-card.md), [../cards/acerto-card.md](../cards/acerto-card.md) — uso do toggle Δ
- [../pages/acerto.md](../pages/acerto.md) — `acertoPixJulio`
