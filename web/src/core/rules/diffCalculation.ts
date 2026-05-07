// Spec: docs/specs/rules/diff-calculation.md
// Mudanças aqui DEVEM começar pela spec. Esta função consolida a regra de Δ
// que antes vivia duplicada em PersonCard.tsx e AcertoPage.tsx.

import type { Row, Person } from "../types";
import { splitForPerson } from "./splitForPerson";

export function diffCalculation(rows: Row[], person: Person): number {
  const other: Person = person === "Julio" ? "Dani" : "Julio";
  const monthHasPix = rows.some((r) => r.origem === "Pix (contas)");
  let meu = 0;
  let outro = 0;
  if (monthHasPix) {
    for (const r of rows) {
      if (r.origem !== "Pix (contas)") continue;
      meu += splitForPerson(r, person);
      outro += splitForPerson(r, other);
    }
  } else {
    for (const r of rows) {
      if (r.origem === "Contas" || r.origem === "Empregados") {
        meu += splitForPerson(r, person);
        outro += splitForPerson(r, other);
      }
    }
  }
  return meu - outro;
}
