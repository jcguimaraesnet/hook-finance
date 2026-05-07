// Spec: docs/specs/rules/split-for-person.md
// Mudanças aqui DEVEM começar pela spec.

import '../types.dart';

double splitForPerson(ExpenseRow row, Person person) {
  if (row.rateio == person.name) return row.valor;
  if (row.rateio == 'Metade' &&
      (person == Person.julio || person == Person.dani)) {
    return row.valor / 2;
  }
  return 0;
}
