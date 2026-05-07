// Spec: docs/specs/conventions.md (Money / números)

import 'package:intl/intl.dart';

final NumberFormat _moneyFormatter = NumberFormat.decimalPattern('pt_BR')
  ..minimumFractionDigits = 2
  ..maximumFractionDigits = 2;

final NumberFormat _pctFormatter = NumberFormat.decimalPercentPattern(
  locale: 'pt_BR',
  decimalDigits: 2,
);

String formatMoney(double v) => _moneyFormatter.format(v);
String formatPct(double v) => _pctFormatter.format(v);

/// "20k", "1,5k", ou "500" — usado em eixos de gráficos.
String moneyK(num? v) {
  if (v == null || v.isNaN) return '';
  if (v.abs() >= 1000) {
    final k = v / 1000;
    if (k % 1 == 0) {
      return '${k.toInt()}k';
    }
    return '${k.toStringAsFixed(1).replaceAll('.', ',')}k';
  }
  return NumberFormat.decimalPattern('pt_BR').format(v);
}
