// Spec: docs/specs/rules/bucket-key.md
// Mudanças aqui DEVEM começar pela spec.

import type { Row } from "../types";

export function bucketKey(row: Row): string {
  if (row.origem === "Cartão") {
    return row.rateio === "Metade"
      ? "Cartão (compartilhado)"
      : "Cartão (pessoal)";
  }
  return row.origem;
}
