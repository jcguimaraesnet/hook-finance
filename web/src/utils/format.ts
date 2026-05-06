// Espelhando os helpers do Script.html atual (Money, Pct, moneyK, parcelaTotal).

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

/** Extrai o total de parcelas a partir de "X/Y" (ou número legado). 0/empty -> 1. */
export function parcelaTotal(p: unknown): number {
  if (p == null || p === "") return 1;
  const s = String(p).trim();
  if (s.indexOf("/") !== -1) {
    return parseInt(s.split("/")[1], 10) || 1;
  }
  return parseInt(s, 10) || 1;
}

export function isParcelado(p: unknown): boolean {
  return String(p ?? "").trim() !== "";
}
