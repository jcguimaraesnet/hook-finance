// Spec: docs/specs/cards/categoria-table.md

import 'package:flutter/material.dart';
import '../core/format/money.dart';
import '../core/types.dart';

class CategoriaTable extends StatelessWidget {
  final List<ExpenseRow> rows;
  const CategoriaTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartao = rows.where((r) => r.origem == 'Cartão');
    final byCat = <String, double>{};
    for (final r in cartao) {
      final k = r.categoria.isEmpty ? '(sem categoria)' : r.categoria;
      byCat[k] = (byCat[k] ?? 0) + r.valor;
    }
    final totalCheio = byCat.values.fold<double>(0, (s, v) => s + v);
    final list = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final borderSide = BorderSide(color: theme.colorScheme.outlineVariant);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final boldStyle = cellStyle?.copyWith(fontWeight: FontWeight.bold);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 8),
              child: Text(
                'Cartão compartilhado por categoria (R\$)',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    _Cell(
                        text: 'Categoria',
                        style: headerStyle,
                        border: Border(bottom: borderSide)),
                    _Cell(
                        text: 'Valor',
                        style: headerStyle,
                        align: TextAlign.right,
                        border: Border(bottom: borderSide)),
                    _Cell(
                        text: 'Compart.',
                        style: headerStyle,
                        align: TextAlign.right,
                        border: Border(bottom: borderSide)),
                    _Cell(
                        text: '%',
                        style: headerStyle,
                        align: TextAlign.right,
                        border: Border(bottom: borderSide)),
                  ],
                ),
                for (final e in list)
                  TableRow(
                    children: [
                      _Cell(
                          text: e.key,
                          style: cellStyle,
                          border: Border(bottom: borderSide)),
                      _Cell(
                          text: formatMoney(e.value),
                          style: cellStyle,
                          align: TextAlign.right,
                          border: Border(bottom: borderSide)),
                      _Cell(
                          text: e.key == 'Pessoal'
                              ? '—'
                              : formatMoney(e.value / 2),
                          style: cellStyle,
                          align: TextAlign.right,
                          border: Border(bottom: borderSide)),
                      _Cell(
                          text: totalCheio > 0
                              ? formatPct(e.value / totalCheio)
                              : '—',
                          style: cellStyle,
                          align: TextAlign.right,
                          border: Border(bottom: borderSide)),
                    ],
                  ),
                TableRow(
                  children: [
                    _Cell(
                        text: 'Total Geral',
                        style: boldStyle,
                        border: Border(top: BorderSide(
                            color: theme.colorScheme.onSurface, width: 1.5))),
                    _Cell(
                        text: formatMoney(totalCheio),
                        style: boldStyle,
                        align: TextAlign.right,
                        border: Border(top: BorderSide(
                            color: theme.colorScheme.onSurface, width: 1.5))),
                    _Cell(
                        text: '—',
                        style: boldStyle,
                        align: TextAlign.right,
                        border: Border(top: BorderSide(
                            color: theme.colorScheme.onSurface, width: 1.5))),
                    _Cell(
                        text: totalCheio > 0 ? formatPct(1) : '—',
                        style: boldStyle,
                        align: TextAlign.right,
                        border: Border(top: BorderSide(
                            color: theme.colorScheme.onSurface, width: 1.5))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign align;
  final Border border;

  const _Cell({
    required this.text,
    this.style,
    this.align = TextAlign.left,
    this.border = const Border(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: border),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(text, style: style, textAlign: align),
    );
  }
}
