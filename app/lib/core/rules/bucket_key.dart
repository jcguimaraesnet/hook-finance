// Spec: docs/specs/rules/bucket-key.md
// Mudanças aqui DEVEM começar pela spec.

import '../types.dart';

String bucketKey(ExpenseRow row) {
  if (row.origem == 'Cartão') {
    return row.rateio == 'Metade'
        ? 'Cartão (compartilhado)'
        : 'Cartão (pessoal)';
  }
  return row.origem;
}
