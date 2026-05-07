// Spec: docs/specs/rules/diff-calculation.md
// Mudanças aqui DEVEM começar pela spec.

import '../types.dart';
import 'split_for_person.dart';

double diffCalculation(List<ExpenseRow> rows, Person person) {
  final other = person.other;
  final monthHasPix = rows.any((r) => r.origem == 'Pix (contas)');
  double meu = 0;
  double outro = 0;
  if (monthHasPix) {
    for (final r in rows) {
      if (r.origem != 'Pix (contas)') continue;
      meu += splitForPerson(r, person);
      outro += splitForPerson(r, other);
    }
  } else {
    for (final r in rows) {
      if (r.origem == 'Contas' || r.origem == 'Empregados') {
        meu += splitForPerson(r, person);
        outro += splitForPerson(r, other);
      }
    }
  }
  return meu - outro;
}
