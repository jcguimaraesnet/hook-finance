// Spec: docs/specs/rules/parcela-format.md
// Mudanças aqui DEVEM começar pela spec.

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
