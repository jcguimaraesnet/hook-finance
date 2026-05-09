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

const _monthsCapitalizedPt = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Aceita "DD/MM/YYYY" ou "MM/YYYY" e retorna "Mês, YYYY" (pt-BR capitalizado).
/// Ex: "06/05/2026" -> "Maio, 2026"; "05/2026" -> "Maio, 2026".
String monthYearLong(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final parts = raw.split('/');
  int? m;
  String? y;
  if (parts.length == 3) {
    m = int.tryParse(parts[1]);
    y = parts[2];
  } else if (parts.length == 2) {
    m = int.tryParse(parts[0]);
    y = parts[1];
  }
  if (m == null || y == null || m < 1 || m > 12) return raw;
  return '${_monthsCapitalizedPt[m - 1]}, $y';
}

/// Aceita "DD/MM/YYYY" ou "MM/YYYY" e retorna "MM/YYYY".
String mmYYYY(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final parts = raw.split('/');
  if (parts.length == 3) return '${parts[1]}/${parts[2]}';
  if (parts.length == 2) return raw;
  return raw;
}
