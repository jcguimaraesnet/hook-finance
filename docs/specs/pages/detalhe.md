---
status: stable
last_updated: 2026-05-29
---

# Detalhe — despesas pessoais por pessoa

Página que lista despesas pessoais (não compartilhadas) do mês corrente, com 4 indicadores no topo: total pessoal, cartão pessoal, parcelado atual e parcelado próximo mês.

- **PWA:** todas as pessoas em accordions colapsáveis na mesma página. (Congelado — `web/src/`.)
- **Flutter (Bloom):** drill-down a partir do donut da [Início](inicio.md) — recebe `?person=julio|dani`, mostra apenas a pessoa clicada com toggle Júlio/Dani no topo para trocar.

## Contexto

Útil para revisar o que cada um gastou de forma pessoal — separado da despesa compartilhada que vai para o acerto. A lista usa só Cartão pessoal (atrito de leitura), mas os 4 tiles superiores resumem também o impacto de parcelas em meses futuros.

## Regras

### Inputs

Lê `monthData(currentMonth)`. Não chama outros endpoints.

### Filtragem da lista de lançamentos

- `r.origem === "Cartão"` (só Cartão).
- `r.rateio !== ""` E `r.rateio !== "Metade"` (exclui sem rateio e compartilhado).

### Agregação dos tiles superiores (Flutter)

Ver [../rules/personal-summary.md](../rules/personal-summary.md) — define `personalSummaryForPerson(rows, person)` com 4 campos: `totalPessoal`, `cartaoPessoal`, `parceladoAtual`, `parceladoProx`.

### Agregação da lista (PWA legada)

Agrupa por `r.rateio`. Cada grupo:

- `total = Σ r.valor` (cheio, não dividido).
- `items = Row[]` daquele rateio.

### Ordem dos grupos

Ordem preferida: `["Julio", "Dani", "Alzira"]`. Outros rateios (raros) entram depois em ordem alfabética.

```ts
const ordered = [...PREFERRED_ORDER, ...others.sort()].filter((p) => byPerson[p]);
```

### Render

**PWA:** cada grupo é um `<details>` (accordion) colapsado:

- **Summary:** nome (`Julio`/`Dani`/...) + total `R$ X` à direita.
- **Body** (quando expandido): tabela com colunas Data | Descrição | Valor.
  - Itens ordenados por `dataRef` **descendente** (mais recente primeiro).

**Flutter (Bloom):** página single-person (a passada via `?person=`):

- Header `ScreenHeader` com kicker "Despesas pessoais" + título "<Person> · <mês>" + `MonthSelector`.
- Person pills Júlio/Dani — tap troca a query e re-renderiza. Cor da pill ativa = `BloomColors.forPerson(p)` (Júlio=menta, Dani=lilás — ver [inicio.md](inicio.md)).
- **Grid 2×2 de tiles** (mesmo padrão visual de [compart.md](compart.md) — Cards `BloomCard` com kicker uppercase + valor `R$`, sem badge de %):
  - **Total pessoal** — `summary.totalPessoal`.
  - **Cartão pessoal** — `summary.cartaoPessoal`.
  - **Parcelado atual** — `summary.parceladoAtual`.
  - **Parcelado Próx** — `summary.parceladoProx` (projeção do próximo mês).
- Lista de lançamentos `RecentEntryRow` filtrada (mais recente primeiro) ou mensagem "Sem lançamentos pessoais este mês". Avatar de cada linha usa cor+símbolo do rateio — ver [../cards/recent-entry-row.md](../cards/recent-entry-row.md).

### Loading / vazio

- Loading: 3 skeletons.
- Sem despesas pessoais: mensagem `"Sem despesas pessoais neste mês."`.

## Edge cases

- **Mês sem nenhuma despesa Cartão pessoal:** mostra mensagem de vazio.
- **Pessoa só com despesas compartilhadas no mês:** não aparece (filtra `rateio === "Metade"`).
- **Rateio com valor diferente de Julio/Dani/Alzira:** entra na seção `others`, ordem alfabética.
- **`dataRef` sem horário:** `localeCompare` ainda funciona (ordena por string).

## Implementações

- **PWA:** [web/src/pages/DetalhePage.tsx](../../../web/src/pages/DetalhePage.tsx)
- **Após Onda 2:** `PREFERRED_ORDER` move para `core/constants.ts`. Filtro fica inline (regra simples, sem reuso fora dessa página).
- **Flutter:** [app/lib/features/detalhe/detalhe_page.dart](../../../app/lib/features/detalhe/detalhe_page.dart) — drill-down de [inicio.md](inicio.md) via `?person=julio|dani`. Sem accordion (single-person view).

## Specs relacionadas

- [../rules/personal-summary.md](../rules/personal-summary.md) — fórmulas dos 4 tiles
- [../cards/recent-entry-row.md](../cards/recent-entry-row.md) — avatar e linha de metadados
- [../data/despesas-sheet.md](../data/despesas-sheet.md) — cols E (origem), G (rateio), B (dataRef)
- [../responsive/breakpoints.md](../responsive/breakpoints.md)
