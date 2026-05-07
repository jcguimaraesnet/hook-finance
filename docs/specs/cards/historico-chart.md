---
status: stable
last_updated: 2026-05-07
---

# HistoricoChart — linha 12 meses

Line chart mostrando até 12 meses de histórico. Usado em duas variantes em Consulta/Histórico:

- **Total geral** (uma série, marrom).
- **Pessoal** (duas séries: Júlio azul, Dani vermelho).

## Contexto

Os dados vêm de `historicalSummary.history` — um agregado pré-computado pelo backend (cols A, D, E, G só, do slab dos últimos 12 meses). Frontend não recalcula.

## Regras

### Inputs

```ts
interface Props {
  title: string;
  months: string[];           // "DD/MM/YYYY", ascendente
  series: {
    label: string;
    data: number[];           // mesmo length de months
    color: string;            // hex
    align: "top" | "bottom";  // posição do datalabel
  }[];
  showLegend?: boolean;       // default true
}
```

### Mobile vs desktop

- Mobile (`max-width: 639.98px`): mostra **últimos 6 meses** (`months.slice(-6)`, mesmo para `series.data`).
- Tablet/PC (`>= 640px`): mostra todos os 12 meses.
- Detecção via `matchMedia` (PWA) / `MediaQuery` (Flutter).

### Datasets

Para cada série:

- `borderColor` e `backgroundColor` = `series.color`.
- `tension: 0.2` (curva levemente suave).
- `borderWidth: 1.5`.
- `pointRadius: 2.5`, `pointHoverRadius: 5`.
- Datalabel align conforme `series.align` (top/bottom), offset 6.

### Eixos

- **X (meses):**
  - `autoSkip: false`, `maxRotation: 0`.
  - Ticks alternados: só os de índice par renderizam.
  - Render via `brDateToMMYYYY(label)` → `"05/2026"`.
- **Y (valor):**
  - Ticks alternados: só os de índice par renderizam, formato `moneyK(value)`.

### Tooltip

- `mode: "index"`, `intersect: false`. Mostra todos os datasets do mês ao passar o mouse.
- Label: `${dataset.label}: ${formatMoney(parsed.y)}`.
- **Plugin custom `verticalHoverLine`:** desenha linha tracejada vertical na posição do hover, da topo ao fundo da chart area, cor `rgba(38, 38, 38, 0.45)`, dash `[4, 4]`. Ver `afterDatasetsDraw` do plugin.

### Datalabels

- Display sempre.
- `anchor: "end"`, `align: "top"` ou conforme série.
- Cor = `dataset.borderColor`.
- Formato: `moneyK(v)`.

### Layout

- Padding top: 24px (espaço para datalabels acima do último ponto).
- Altura: 320px (mobile), 300px (tablet+).
- Legenda: bottom default. Pode ser desligada via `showLegend: false`.

### Variantes consumidas em Consulta

```ts
// Total geral
<HistoricoChart
  title="Histórico — Total geral"
  months={months}
  series={[
    { label: "Total geral", data: totals, color: "#a07b5e", align: "top" },
  ]}
  showLegend={false}
/>

// Pessoal (Cartão pessoal por pessoa, valor cheio — ver endpoints.md)
<HistoricoChart
  title="Histórico — Pessoal"
  months={months}
  series={[
    { label: "Julio", data: julioPessoal, color: "#4a7ab8", align: "top" },
    { label: "Dani", data: daniPessoal, color: "#c97070", align: "bottom" },
  ]}
/>
```

## Edge cases

- **Menos de 12 meses no histórico:** `months` tem length < 12; chart renderiza só os disponíveis.
- **Mobile com menos de 6 meses:** `slice(-6)` retorna o que houver. Sem padding artificial.
- **Série com `data` toda zero:** linha plana em y=0. Pontos visíveis.
- **Ticks do Y mostrando todos vazios** se `autoSkip` decidir mal: trade-off do `index % 2 !== 0 ? "" : moneyK(value)`. Aceito.

### Flutter — divergências aceitas

`fl_chart` não tem plugin de hover line tracejada nem datalabels nativos. Implementar:

- Hover line: usar `LineChartData.touchData` + custom `getTouchedSpotIndicator` (linha vertical via `FlLine`). Sem dash → divergência visual aceita.
- Datalabels: usar `showingTooltipIndicators` ou textos via `Stack` posicionado por `LineChartBarData`. Se ficar inviável, exibir tooltip on-tap em vez de datalabels permanentes — documentar em `docs/specs/known-divergences.md`.
- Os ticks alternados do eixo Y/X: `getTitlesWidget` retorna `Container.shrink()` para índices ímpares.

## Implementações

- **PWA:** [web/src/components/HistoricoChart.tsx](../../../web/src/components/HistoricoChart.tsx)
- **Backend:** dados servidos por [getHistoricalSummary](../api/endpoints.md).
- **Flutter:** `app/lib/widgets/historico_chart.dart` (Onda 5, fl_chart).

## Specs relacionadas

- [../api/endpoints.md](../api/endpoints.md) — `historicalSummary.history`
- [../pages/consulta.md](../pages/consulta.md)
- [../responsive/breakpoints.md](../responsive/breakpoints.md)
