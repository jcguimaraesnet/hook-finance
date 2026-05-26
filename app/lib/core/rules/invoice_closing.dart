// Spec: docs/specs/rules/invoice-closing-date.md
// Porta Dart de nextInvoiceClosingDate_ no backend (apps-script/shared/Helpers.gs).
// Usado pelo dialog de "Nova fatura" pra previewar a data antes do POST.

const int kInvoiceClosingDay = 6;

String nextInvoiceClosingDate({DateTime? now}) {
  final n = now ?? DateTime.now();
  final year = n.month == 12 ? n.year + 1 : n.year;
  final month = n.month == 12 ? 1 : n.month + 1;
  final dd = kInvoiceClosingDay.toString().padLeft(2, '0');
  final mm = month.toString().padLeft(2, '0');
  return '$dd/$mm/$year';
}
