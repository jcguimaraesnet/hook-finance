// Spec: docs/specs/rules/bucket-deltas.md
// Mudanças aqui DEVEM começar pela spec.

import '../types.dart';
import 'split_for_person.dart';

/// Buckets agregados de uma pessoa para um conjunto de linhas.
class PersonBuckets {
  final double compart;
  final double pessoal;
  final double contas;

  const PersonBuckets({
    required this.compart,
    required this.pessoal,
    required this.contas,
  });

  double get total => compart + pessoal + contas;

  static const zero = PersonBuckets(compart: 0, pessoal: 0, contas: 0);
}

/// Soma `splitForPerson(r, person)` por bucket.
PersonBuckets bucketsForPerson(List<ExpenseRow> rows, Person person) {
  double compart = 0, pessoal = 0, contas = 0;
  for (final r in rows) {
    final v = splitForPerson(r, person);
    if (v == 0) continue;
    if (r.origem == 'Cartão') {
      if (r.rateio == 'Metade') {
        compart += v;
      } else {
        pessoal += v;
      }
    } else {
      contas += v;
    }
  }
  return PersonBuckets(compart: compart, pessoal: pessoal, contas: contas);
}

/// Δ% por bucket entre `current` e `previous`. `null` quando previous é 0.
class BucketDeltas {
  final double? compart;
  final double? pessoal;
  final double? contas;

  const BucketDeltas({this.compart, this.pessoal, this.contas});

  static const empty = BucketDeltas();
}

BucketDeltas bucketDeltas({
  required PersonBuckets current,
  required PersonBuckets previous,
}) {
  double? delta(double cur, double prev) {
    if (prev == 0) return null;
    return (cur - prev) / prev * 100;
  }

  return BucketDeltas(
    compart: delta(current.compart, previous.compart),
    pessoal: delta(current.pessoal, previous.pessoal),
    contas: delta(current.contas, previous.contas),
  );
}

/// Calcula o mês anterior em formato `MM/YYYY`.
/// Retorna `null` se o input não está nesse formato.
String? previousMonthOf(String? mm) {
  if (mm == null) return null;
  final parts = mm.split('/');
  if (parts.length != 2) return null;
  final m = int.tryParse(parts[0]);
  final y = int.tryParse(parts[1]);
  if (m == null || y == null) return null;
  if (m == 1) return '12/${y - 1}';
  return '${(m - 1).toString().padLeft(2, '0')}/$y';
}
