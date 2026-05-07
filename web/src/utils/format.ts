// Re-exports de @/core (back-compat).
// Specs: docs/specs/conventions.md (Money/dates), docs/specs/rules/parcela-format.md
export { Money, Pct, formatMoney, formatPct, moneyK } from "@/core/format/money";
export { parcelaTotal, isParcelado } from "@/core/rules/parcela";
