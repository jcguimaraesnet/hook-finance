// Spec: docs/specs/pages/lancamento.md
// Picker custom de mês + ano (sem dia). Usado em "Mês Fatura" do modal
// de edição e da aba "+ Novo" em Lançamentos. Retorna DateTime com day=6
// (convenção do projeto — coluna Data da planilha sempre tem dia 06 para
// lançamentos editados/criados pela UI).

import 'package:flutter/material.dart';
import '../../core/format/dates.dart';
import '../../theme/bloom_colors.dart';

const int _firstYearOffset = -4; // permite olhar 4 anos pra trás
const int _lastYearOffset = 2; // e 2 anos pra frente

Future<DateTime?> showMonthYearPicker(
  BuildContext context, {
  required DateTime initial,
  String title = 'Mês Fatura',
}) {
  final now = DateTime.now();
  final base = initial.year < 2000 ? now : initial;
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthYearDialog(
      initialMonth: base.month,
      initialYear: base.year,
      firstYear: now.year + _firstYearOffset,
      lastYear: now.year + _lastYearOffset,
      title: title,
    ),
  );
}

class _MonthYearDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;
  final int firstYear;
  final int lastYear;
  final String title;

  const _MonthYearDialog({
    required this.initialMonth,
    required this.initialYear,
    required this.firstYear,
    required this.lastYear,
    required this.title,
  });

  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
    _year = widget.initialYear.clamp(widget.firstYear, widget.lastYear);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                initialValue: _month,
                decoration: const InputDecoration(labelText: 'Mês'),
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(value: m, child: Text(monthNamePt(m))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _month = v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                initialValue: _year,
                decoration: const InputDecoration(labelText: 'Ano'),
                items: [
                  for (var y = widget.firstYear; y <= widget.lastYear; y++)
                    DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _year = v);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: BloomColors.ink),
          onPressed: () =>
              Navigator.of(context).pop(DateTime(_year, _month, 6)),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
