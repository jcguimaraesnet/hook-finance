---
status: stable
last_updated: 2026-05-07
---

# Breakpoints — responsividade do PWA

Define em que largura o PWA muda layout. Spec é específica do PWA (CSS-driven via Tailwind v4 `@theme`); o Flutter usa `MediaQuery.of(context).size.width` mas não precisa replicar **exatamente** os mesmos números.

## Contexto

O PWA tem 3 níveis: mobile, tablet (intermediário), PC (web desktop). Decidimos breakpoints na hora de criar a UI; documentar evita drift se mudarmos.

## Regras (PWA)

| Breakpoint | Largura | Aliases Tailwind | Comportamento |
|---|---|---|---|
| Mobile | `< 640px` | (default sem prefix) | Bottom-fixed primary nav. Consulta com sub-tabs. Cards 1-col. HistoricoChart só 6 meses. |
| Tablet | `640..749px` | `tablet:` (custom) | Top primary nav (sticky com tiles). Consulta com sub-tabs. Cards 2-col. Body max-width 880px centered. |
| PC | `>= 750px` | `pc:` (custom) | Top primary nav. Consulta **sem** sub-tabs (todos painéis visíveis). Cards 2-col. |

### Custom breakpoints definidos no `@theme`

`web/src/index.css` (ou equivalente) define:

```css
@theme {
  --breakpoint-tablet: 640px;
  --breakpoint-pc: 750px;
}
```

(Tailwind v4 expõe os custom breakpoints via `tablet:` e `pc:` prefixes em classes.)

### Detecção JavaScript

- Componentes que precisam saber o breakpoint usam `window.matchMedia`:
  - HistoricoChart: `(max-width: 639.98px)` (mobile-only behavior).
  - ConsultaPage: `(min-width: 750px)` (PC sem sub-tabs).
- Reagir a mudanças via `addEventListener("change", ...)` no `MediaQueryList`.

### Acerto Final

- Mobile: cards empilhados.
- Tablet+ (`>= 640px`): grid 2-col.

## Edge cases

- **Resize cruzando breakpoint enquanto a página está aberta:** `matchMedia` listener atualiza imediatamente. Sem flicker.
- **iPad em landscape (`1024px`):** cai em PC. Comportamento desktop. OK.
- **Janelas estreitas em desktop (< 640px):** cai em mobile. OK.

## Flutter — equivalência

`MediaQuery.of(context).size.width`:

- `< 640dp` → mobile.
- `640..749dp` → tablet.
- `>= 750dp` → PC (raríssimo num celular; mais relevante quando rodar em emulador/tablet/desktop Flutter futuro).

Como o app Flutter é primariamente Android phone, a maioria dos casos é mobile. **Não obrigatório** replicar todos os 3 breakpoints — implementar só mobile e tablet, e tratar tablet como "ampliação" do mobile (cards 2-col, etc.). PC fica deferido.

## Implementações

- **PWA Tailwind config:** `web/src/index.css` (ou `tailwind.config.ts` se existir).
- **PWA components com matchMedia:** [HistoricoChart.tsx:9-22](../../../web/src/components/HistoricoChart.tsx), [ConsultaPage.tsx:12-17](../../../web/src/pages/ConsultaPage.tsx).
- **Flutter:** sem arquivo dedicado; cada widget consulta `MediaQuery`.

## Specs relacionadas

- [../pages/consulta.md](../pages/consulta.md)
- [../pages/acerto.md](../pages/acerto.md)
- [../cards/historico-chart.md](../cards/historico-chart.md)
