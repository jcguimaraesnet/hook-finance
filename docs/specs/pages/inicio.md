---
status: stable
last_updated: 2026-05-08
---

# Início — visão pessoal (Flutter, direção Bloom)

Página default ao logar **no app Flutter** (Bloom IA, 5 abas). Mostra a despesa pessoal de uma pessoa selecionada (Júlio ou Dani) com donut interativo, comparativo vs. mês anterior e últimos lançamentos.

> **Escopo:** apenas Flutter. PWA continua em [consulta.md](consulta.md) (4 sub-tabs).

## Contexto

Substitui as sub-abas `Mês` e `Pessoal` da [Consulta](consulta.md) do PWA, tratando a divisão da fatura como dado primário (donut + 3 buckets compart/pessoal/contas). O total compartilhado tem visualização separada em [Compart](compart.md), e o detalhamento de lançamentos pessoais é drill-down via tap no donut → [Detalhe pessoal](detalhe.md).

## Regras

### Inputs

- `monthData(currentMonth)` — fatura atual.
- `monthData(previousMonth)` — derivado de `currentMonth` para o card comparativo (ver [bucket-deltas.md](../rules/bucket-deltas.md)).
- `lastEntries(2)` — para a seção "Últimos lançamentos".

### Layout (top-to-bottom)

1. **App-bar custom** com `BloomLogo` + label "hook" à esquerda, botões `↻` (refresh) e `⚙` (config) à direita.
2. **Saudação** "Olá, Júlio" + título display "Junho, 2026" + `MonthSelector` à direita.
3. **Card hero**: `BloomDonut` à esquerda + bloco com:
   - Kicker "TOTAL PESSOAL" + valor display completo (sem `compact`).
   - Pílula de delta vs. mês anterior (`good`/`bad` cor) sobre `Σ buckets` da pessoa.
   - 3 linhas (1 por bucket) com cor + label + percentual; tap reflete no donut.
   - Link "Ver pessoal →" que navega para `/detalhe?person=<atual>`.
4. **Person pills** (Júlio/Dani) — toggle ativo via fundo `ink`.
5. **Tiles 2-col**: `Cartão geral` + `Parcelado` (totais brutos do mês).
6. **Card "Comparativo vs. <mês anterior>"** com 3 colunas (Compart/Pessoal/Contas), separadas por divisor vertical. Cada coluna: bullet de cor + kicker + valor compact + pílula `↗` (bad) ou `↘` (good) com `prevDelta %`.
7. **Seção "Últimos lançamentos"**: 2 itens via `lastEntries(2)` + link "Ver mais →" para `/lancamento`.

### Donut interativo

- 3 arcos compart/pessoal/contas com cores `violet`/`mint`/`sky` (escala fixa, não Person-derived).
- Tap em arco → segmento expande (`stroke + 4`), demais ficam 35% opacos. Centro mostra label do bucket + valor + `pct%`.
- Tap fora dos arcos / segundo tap → desselecciona.
- Cálculo dos buckets: ver [bucket-key.md](../rules/bucket-key.md) e [split-for-person.md](../rules/split-for-person.md).

### Person switcher

Selectiona a pessoa cuja visão pessoal é exibida (afeta donut + tiles + comparativo + recentes). Persiste em `selectedPersonProvider` (sessão).

## Edge cases

- **Mês sem rows:** todos os buckets em 0; donut renderiza como ring vazio sem segmentos. Comparativo mostra deltas `—`.
- **Sem mês anterior** (primeiro mês de dados): card comparativo oculta as pílulas de delta, mostra apenas valores absolutos.
- **`lastEntries` vazio:** seção "Últimos lançamentos" mostra mensagem `"Sem lançamentos."`.

## Implementações

- **Flutter:** [app/lib/features/inicio/inicio_page.dart](../../../app/lib/features/inicio/inicio_page.dart)
- **Widgets:** `BloomDonut`, `PersonPill`, `RecentEntryRow` em `app/lib/widgets/bloom/`.
- **PWA:** sem equivalente — usa [consulta.md](consulta.md) (4 sub-tabs).

## Specs relacionadas

- [bucket-deltas.md](../rules/bucket-deltas.md) — cálculo de % vs. mês anterior
- [bucket-key.md](../rules/bucket-key.md) — agrupamento Cartão+rateio
- [split-for-person.md](../rules/split-for-person.md) — alocação por pessoa
- [detalhe.md](detalhe.md) — drill-down do donut
- [compart.md](compart.md) — visão complementar (categoria)
