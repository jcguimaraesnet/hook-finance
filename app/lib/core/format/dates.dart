// Spec: docs/specs/conventions.md (Datas)

const List<String> _monthNamesPt = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "DD/MM/YYYY" -> DateTime (epoch comparável). Inválido -> DateTime(1970).
DateTime parseBrDate(String s) {
  final parts = s.split('/');
  if (parts.length != 3) return DateTime.fromMillisecondsSinceEpoch(0);
  final d = int.tryParse(parts[0]) ?? 1;
  final m = int.tryParse(parts[1]) ?? 1;
  final y = int.tryParse(parts[2]) ?? 1970;
  return DateTime(y, m, d);
}

/// "06/05/2026" -> "maio de 2026".
String monthYearLabel(String? brDate) {
  if (brDate == null || brDate.isEmpty) return '';
  final parts = brDate.split('/');
  if (parts.length != 3) return brDate;
  final m = int.tryParse(parts[1]) ?? 0;
  final y = parts[2];
  final name = (m >= 1 && m <= 12) ? _monthNamesPt[m - 1] : 'mês $m';
  return '$name de $y';
}

/// "06/05/2026" -> "05/2026". Usado em ticks de eixo X dos gráficos.
String brDateToMMYYYY(String brDate) {
  final parts = brDate.split('/');
  if (parts.length != 3) return brDate;
  return '${parts[1]}/${parts[2]}';
}
