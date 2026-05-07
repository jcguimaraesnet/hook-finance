// Spec: docs/specs/conventions.md (Money / números)

export const Money = new Intl.NumberFormat("pt-BR", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

export const Pct = new Intl.NumberFormat("pt-BR", {
  style: "percent",
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

export function formatMoney(v: number): string {
  return Money.format(v);
}

export function formatPct(v: number): string {
  return Pct.format(v);
}

/** "20k", "1,5k", ou "500" — usado em eixos de gráficos. */
export function moneyK(v: number): string {
  if (v == null || isNaN(v)) return "";
  if (Math.abs(v) >= 1000) {
    const k = v / 1000;
    return (k % 1 === 0 ? k.toString() : k.toFixed(1).replace(".", ",")) + "k";
  }
  return v.toLocaleString("pt-BR");
}
