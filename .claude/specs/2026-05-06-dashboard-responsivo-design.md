# Dashboard responsivo — design

## Contexto

O layout atual tem dois breakpoints (640px e 1024px) e empilha tudo em 1 coluna abaixo de 640px. O resultado em mobile (~360px) é uma página com ~10 seções verticais (selector + 3 KPIs full-width + 2 quadros pessoa + 2 quadros lower + 2 históricos), tabelas que estouram horizontalmente, charts em apenas 240px de altura e KPIs ocupando ~150px só no header.

Este spec redesenha a estrutura para resolver os 5 pontos de atrito identificados em [.superpowers/brainstorm/47937-1778082968/content/current-mobile-issues.html](.superpowers/brainstorm/47937-1778082968/content/current-mobile-issues.html), e ao mesmo tempo prepara o terreno para 2 funcionalidades futuras (Detalhe e Lançamento) através de uma navegação primária que vai existir desde já.

A estrutura final é uma fusão de 2 abordagens exploradas: bottom-nav/top-nav primária (estilo "C: tabs") + sub-abas dentro da seção atual (estilo "C") + cards de pessoa em 1 col no mobile (estilo "B").

## Estrutura final

### Hierarquia de navegação

```
┌─────────────────────────────────────────────┐
│ Nav primária: Consulta · Detalhe · Lançam.  │  ← bottom em mobile, top em tablet+
├─────────────────────────────────────────────┤
│ Sticky header: selector + 3 KPIs            │  ← sempre visível dentro de Consulta
├─────────────────────────────────────────────┤
│ Sub-abas: Mês · Cartão · Histórico          │  ← dentro de Consulta
├─────────────────────────────────────────────┤
│ Conteúdo da sub-aba ativa                   │
└─────────────────────────────────────────────┘
```

- **Consulta:** dashboard atual (esta entrega)
- **Detalhe** e **Lançamento:** placeholders inativos (cinza, opacity ~0.5, não clicáveis); ficam visíveis para indicar que existirão.

### Comportamento por viewport

Convenção de breakpoints: `@media (min-width: 640px)` separa mobile de tablet+; `@media (min-width: 1024px)` separa tablet de desktop. Mobile é o default (sem media query).

| Elemento | Mobile (<640px) | Tablet (640-1023px) | Desktop (≥1024px) |
|---|---|---|---|
| **Body** | width 100% (sem max) | max-width 720px, centralizado | max-width 720px, centralizado |
| **Nav primária** | bar fixa no rodapé | barra horizontal no topo | barra horizontal no topo |
| **Header (selector + 3 KPIs)** | 1 card combinado, compacto, sticky | 4 cards inline (selector + 3 totais) | 4 cards inline |
| **Sub-abas Mês/Cartão/Histórico** | segmented control, full-width | segmented control | segmented control |
| **Aba Mês — Pessoas (Júlio + Dani)** | 1 col (Júlio acima, Dani abaixo) | 2 col side-by-side | 2 col side-by-side |
| **Aba Cartão — categoria + pessoa** | 1 col | 2 col side-by-side | 2 col side-by-side |
| **Aba Histórico — Total + Pessoal** | 1 col, charts empilhados | 1 col | 1 col |

### Detalhes de design

**Sticky header em mobile** — selector e os 3 KPIs ficam num único card compacto: o `<select>` ocupa a primeira linha em width 100%, e os 3 KPIs aparecem abaixo em uma linha de 3 colunas com fonte reduzida (rótulo ~7px, valor ~11px, formato abreviado tipo "12k").

**Header em tablet/desktop** — mantém o layout grid de 4 colunas (`1.2fr 1fr 1fr 1fr`) com selector + 3 totais em cards individuais, semelhante ao atual.

**Sub-abas** — 3 botões iguais com flex 1, dentro de um wrapper branco. Aba ativa pinta fundo `--accent` (`#f4d35e`) com texto `--accent-fg`. Aba inativa fica neutra (cinza claro). Click troca a aba ativa.

**Nav primária** — visual: bar `#262626` (preto) com 3 itens flex 1. Ativo (`Consulta`) com fundo accent + texto preto + bold. Inativos (`Detalhe`, `Lançamento`) com texto branco + opacity 0.5 + `pointer-events: none`. Em mobile a nav é `position: fixed; bottom: 0` com `padding-bottom: env(safe-area-inset-bottom)` para respeitar a notch/home-bar; em tablet+ vira `position: static` no topo do body.

**Charts** — altura mínima 280px em qualquer viewport (vs 240px atual em mobile).

**Tabelas** — fonte ligeiramente menor em mobile (~0.85rem). `scroll-x` mantido para não quebrar conteúdo. Person card hoje já tem `.scroll-x` então OK.

### Estado e persistência

- **Aba ativa (Mês/Cartão/Histórico)** persiste em `localStorage` (chave `hook-finance-tab`). Default na primeira visita: `Mês`.
- **Mês selecionado** já persiste implicitamente (selector recarrega o mês mais recente).
- **Trocar de mês não muda a aba ativa.**
- **Recarregar a página vai direto para a aba salva.**

### Render dos charts

- **Lazy render por aba**: o `Chart.js` só desenha o canvas quando a aba dele se torna ativa pela primeira vez. Os canvases das abas inativas ficam em estado skeleton.
- Quando o usuário troca de aba, se o chart daquela aba ainda não existe, é criado naquele momento. Subsequentes trocas reutilizam o instance.
- Quando o mês muda: charts já existentes são atualizados via `chart.update()` apenas para a aba ativa; as outras abas são marcadas como "stale" e re-renderizadas só quando ativadas novamente.

### Lazy load do histórico mantido

A entrega anterior já implementa o carregamento em 3 passos (skeleton → dados do mês → histórico em background). Isso continua: o passo 3 (`getHistoricalSummary`) só aciona o render do chart histórico se a aba Histórico estiver ativa; senão guarda os dados e marca a aba como pronta para render.

## Arquivos afetados

- [src/dashboard/Index.html](src/dashboard/Index.html) — reorganização do markup: nav primária, sticky header reestruturado, sub-abas, wrappers das 3 abas com IDs distintos.
- [src/dashboard/Stylesheet.html](src/dashboard/Stylesheet.html) — novas regras: `.primary-nav`, `.tab-strip`, `.tab-panel`, `.tile-strip` (header compacto mobile), responsividade reescrita com max-width no body em ≥640px, estilos de aba ativa/inativa.
- [src/dashboard/Script.html](src/dashboard/Script.html) — handler de troca de sub-aba; `localStorage` para aba ativa; ajuste do fluxo de render para respeitar lazy-render por aba; `renderHistoricoFromSummary` chamado sob demanda quando a aba Histórico ativa.

Sem mudanças em backend (`Dashboard.gs`, `Helpers.gs`).

## Out of scope

- **Implementação de Detalhe e Lançamento.** Apenas reservar o lugar visual e os items inativos na nav primária. Conteúdo dessas abas fica "Em breve" ou similar; não há roteamento, formulários, listagem, etc.
- **Service worker / PWA.** Não nesse spec.
- **Modo escuro.** Não nesse spec.
- **Aba Histórico com seletor próprio de período** (ex: 6m / 12m / 24m). Continua fixo em 12 meses.

## Verificação end-to-end

1. **Mobile portrait (~360px):** abrir em DevTools, conferir
   - Bottom nav fixa com Consulta ativa.
   - Sticky header (selector + 3 mini-KPIs) sempre visível ao scrollar.
   - Sub-abas Mês/Cartão/Histórico — clicar em cada uma troca o conteúdo.
   - Aba Mês: Júlio acima de Dani.
   - Aba Cartão: categoria acima de pessoa.
   - Aba Histórico: total acima de pessoal.
   - Trocar mês mantém a aba ativa.
   - Recarregar mantém aba salva.

2. **Tablet (~768px):** body fica centralizado com margens cinzas laterais; top nav no topo (sem bottom fixa); pessoa em 2 col; cartão em 2 col; histórico empilhado.

3. **Desktop (~1280px):** idêntico ao tablet, com mais margem cinza.

4. **Detalhe e Lançamento:** items aparecem na nav, ficam cinza claro, não respondem ao clique.

5. **Lazy render:** ao abrir a aba Histórico pela primeira vez, o chart aparece (e na primeira vez observa-se a transição de skeleton → renderizado se a request `getHistoricalSummary` ainda estiver em vôo).

6. **Webhook não regrediu:** inserir uma despesa via POST com token, recarregar — nova linha no mês corrente.
