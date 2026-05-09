---
status: stable
last_updated: 2026-05-08
---

# Consulta — página principal (PWA)

Página default ao logar **no PWA**. Mostra resumo do mês corrente em 4 sub-tabs: Mês, Categoria, Pessoal, Histórico.

> **Flutter (Bloom IA)** dissolve essa página em 4 destinos top-level:
> [Início](inicio.md) · [Compart](compart.md) · [Lançamentos](lancamento.md) · [Histórico](historico.md).
> Esta spec descreve apenas o comportamento do PWA.

## Contexto

É o uso mais frequente do app — abrir, conferir os totais do mês, ver onde foi gasto, comparar com meses anteriores. Precisa carregar rápido. Decisão de manter `monthData` em cache estável (sem `staleTime` explícito; cache infinito até refetch via mutation/invalidation).

## Regras

### Layout responsivo

- **Mobile (`< 640px`)** e **Tablet (`640..749px`)**: sub-tabs visíveis (componente `SubTabs`). Apenas o painel da `activeTab` renderiza.
- **PC (`>= 750px`)**: sub-tabs ocultas. **Todos os 4 painéis renderizam** simultaneamente, empilhados verticalmente. Categoria/Pessoal renderizam lado a lado em grid 2-col.

### Tabs

| Tab | Painel |
|---|---|
| Mês | 2 [PersonCard](../cards/person-card.md) (Júlio + Dani) lado a lado em tablet+. Mobile empilha. |
| Categoria | [CategoriaTable](../cards/categoria-table.md). Em PC, ao lado do RateioChart (ver Pessoal). |
| Pessoal | [RateioChart](../cards/rateio-chart.md). Em PC, fundido com a sub-tab Categoria no grid. |
| Histórico | 2 [HistoricoChart](../cards/historico-chart.md): "Total geral" + "Pessoal". |

### Loading

- `monthData` carregando → painel renderiza `CardSkeleton` com mesmo título do card real.
- `historicalSummary` carregando → painel Histórico mostra 2 skeletons.
- Carregamentos paralelos (não sequenciais).

### Auto-set de `currentMonth`

Quando a primeira resposta de `monthData` chega sem `currentMonth` definido no store, o componente faz `setCurrentMonth(monthQ.data.month)`. Isso popula o dropdown de mês com o invoice mais recente automaticamente.

### Auto-popular `allMonths`

Quando `historicalSummary` chega, `setAllMonths(historyQ.data.months)`. Dropdown ganha opções em ordem descendente.

## Edge cases

- **Token recém-inserido**: queries só rodam após `token` no store. Login screen lida com isso antes de empurrar para Consulta.
- **`monthData.rows = []`** (sheet vazia / mês sem dados): cards renderizam com totais 0; charts vazios.
- **`historicalSummary.history.months = []`**: Histórico mostra cards vazios.
- **Erro de rede em `monthData`**: mostra mensagem `"Erro carregando dados do mês."` no fim da página.
- **PWA install banner**: aparece sobreposto, não afeta layout (ver feature separada — fora do escopo deste spec).

## Implementações

- **PWA:** [web/src/pages/ConsultaPage.tsx](../../../web/src/pages/ConsultaPage.tsx)
- **Hooks:** `useMonthData`, `useHistoricalSummary`.
- **Flutter:** N/A — usa Bloom IA. Ver [inicio.md](inicio.md), [compart.md](compart.md), [historico.md](historico.md).

## Specs relacionadas

- [../cards/person-card.md](../cards/person-card.md)
- [../cards/categoria-table.md](../cards/categoria-table.md)
- [../cards/rateio-chart.md](../cards/rateio-chart.md)
- [../cards/historico-chart.md](../cards/historico-chart.md)
- [../responsive/breakpoints.md](../responsive/breakpoints.md)
- [../state/persistence.md](../state/persistence.md) — `activeTab`
