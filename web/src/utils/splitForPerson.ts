import type { Row, Person } from "@/api/types";

/** Espelha splitForPerson(row, person) do Script.html atual.
 *  Retorna o valor que cabe à pessoa: cheio se rateio === person; metade se "Metade"; 0 caso contrário. */
export function splitForPerson(row: Row, person: Person): number {
  if (row.rateio === person) return row.valor;
  if (
    row.rateio === "Metade" &&
    (person === "Julio" || person === "Dani")
  ) {
    return row.valor / 2;
  }
  return 0;
}
