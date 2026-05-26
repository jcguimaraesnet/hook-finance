// Spec: docs/specs/rules/invoice-closing-date.md
// Portas Dart das funções de fechamento de fatura do backend
// (apps-script/shared/Helpers.gs).

const int kInvoiceClosingDay = 6;

// Equivalente a nextInvoiceClosingDate_(): fatura **atual acumulando**.
// Usada pelo webhook na hora de gravar a compra.
String nextInvoiceClosingDate({DateTime? now}) {
  final n = now ?? DateTime.now();
  final year = n.month == 12 ? n.year + 1 : n.year;
  final month = n.month == 12 ? 1 : n.month + 1;
  final dd = kInvoiceClosingDay.toString().padLeft(2, '0');
  final mm = month.toString().padLeft(2, '0');
  return '$dd/$mm/$year';
}

// Equivalente a newInvoiceClosingDate_(): fatura DEPOIS da acumulando.
// Usada pelo dialog de "Nova fatura" pra previewar a data antes do POST.
String newInvoiceClosingDate({DateTime? now}) {
  final n = now ?? DateTime.now();
  // mês corrente + 2 (com wrap de ano).
  var month = n.month + 2;
  var year = n.year;
  while (month > 12) {
    month -= 12;
    year += 1;
  }
  final dd = kInvoiceClosingDay.toString().padLeft(2, '0');
  final mm = month.toString().padLeft(2, '0');
  return '$dd/$mm/$year';
}
