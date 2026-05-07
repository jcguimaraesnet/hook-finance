// Spec: docs/specs/rules/split-for-person.md
// Mudanças aqui DEVEM começar pela spec.

import type { Row, Person } from "../types";

export function splitForPerson(row: Row, person: Person): number {
  if (row.rateio === person) return row.valor;
  if (row.rateio === "Metade" && (person === "Julio" || person === "Dani")) {
    return row.valor / 2;
  }
  return 0;
}
