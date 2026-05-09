---
status: stable
last_updated: 2026-05-08
---

# Histórico — 6 meses (Flutter, direção Bloom)

Página com 2 cards sobrepostos: histórico do **total geral** e histórico **por pessoa** (Júlio×Dani). Substitui a sub-aba `Histórico` da [Consulta](consulta.md) do PWA.

> **Escopo:** apenas Flutter. PWA continua na sub-aba com 2 [HistoricoChart](../cards/historico-chart.md).

## Contexto

A visão temporal ajuda a identificar tendências (mês de viagem, mês de Black Friday, etc.). No mobile, mostrar apenas os **últimos 6 meses** é o melhor compromisso entre densidade e legibilidade.

## Regras

### Inputs

- `historicalSummary` — `months` + `totals` + `julioPessoal` + `daniPessoal`. Cache 5 min.
- Trunca para os **últimos 6 meses** (`months.takeLast(6)`).

### Layout

1. **Header** `ScreenHeader` com kicker "Histórico" + título "Últimos 6 meses".
2. **Card 1 — Total geral**:
   - Valor display do último mês + pílula de delta vs. mês anterior (good/bad).
   - Bar chart vertical (6 barras), última destacada com `accent`/cor primária; demais com 33% opacidade.
   - Cada barra com label numérico em monospace acima e label do mês ("01/26") abaixo.
3. **Card 2 — Por pessoa**:
   - Kicker "POR PESSOA" + título "Despesas pessoais".
   - Legenda à direita: `● Júlio` (violet) + `● Dani` (mint).
   - Line chart sobreposto: 2 séries (`julioPessoal`/`daniPessoal`).
     - Linhas com 2.4px stroke, `strokeLinecap: round`.
     - Pontos: 2.5px no histórico, 4px no último mês.
     - Eixo X com labels do mês ("01/26"); sem eixo Y visível.
   - 2 mini-tiles abaixo (2-col): `Júlio · jun: R$ X` (fundo `violet12`) + `Dani · jun: R$ Y` (fundo `mint12`).

### Cálculo de delta no Card 1

```
last = totals.last
prev = totals[totals.length - 2]
delta% = (last - prev) / prev * 100
```

### Loading / vazio

- Loading: 2 cards skeleton (placeholder do tamanho do chart).
- `history == null`: mensagem "Sem histórico".

## Edge cases

- **Menos de 6 meses de histórico**: usa o que tem; bars/line escalam para `n` meses.
- **Único mês:** bars renderiza 1 barra; line chart com 1 ponto (sem stroke). Pílula de delta oculta.
- **`prev == 0`**: delta% mostra `—` (evitar divisão por zero).

## Implementações

- **Flutter:** [app/lib/features/historico/historico_page.dart](../../../app/lib/features/historico/historico_page.dart). Usa `fl_chart` (já dep do projeto).
- **PWA:** sub-aba [consulta.md](consulta.md) → [historico-chart.md](../cards/historico-chart.md) (chartjs).

## Specs relacionadas

- [../cards/historico-chart.md](../cards/historico-chart.md) — chart equivalente no PWA
- [../api/endpoints.md](../api/endpoints.md) — `historicalSummary`
