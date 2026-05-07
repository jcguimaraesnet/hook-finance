// Spec: docs/specs/cards/person-card.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/format/money.dart';
import '../core/rules/bucket_key.dart';
import '../core/rules/diff_calculation.dart';
import '../core/rules/split_for_person.dart';
import '../core/types.dart';
import '../state/diff_toggle.dart';

class PersonCard extends ConsumerWidget {
  final Person person;
  final List<ExpenseRow> rows;

  const PersonCard({super.key, required this.person, required this.rows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDiff = ref.watch(diffVisibleProvider(person));
    final theme = Theme.of(context);

    final byOrigem = <String, double>{};
    for (final r in rows) {
      final v = splitForPerson(r, person);
      if (v == 0) continue;
      final k = bucketKey(r);
      byOrigem[k] = (byOrigem[k] ?? 0) + v;
    }
    final total = byOrigem.values.fold<double>(0, (s, v) => s + v);
    final seen = kBucketOrder.toSet();
    final keys = [
      ...kBucketOrder,
      ...byOrigem.keys.where((k) => !seen.contains(k)),
    ];

    final diff = diffCalculation(rows, person);
    final diffPositive = diff >= 0;
    final diffSign = diffPositive ? '+' : '−';
    final diffColor = diffPositive
        ? const Color(0xFF2C5AA0)
        : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              person: person,
              showDiff: showDiff,
              diff: diff,
              diffSign: diffSign,
              diffColor: diffColor,
              onToggle: () {
                ref.read(diffVisibleProvider(person).notifier).state =
                    !showDiff;
              },
            ),
            const SizedBox(height: 8),
            _Table(byOrigem: byOrigem, keys: keys, total: total),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Person person;
  final bool showDiff;
  final double diff;
  final String diffSign;
  final Color diffColor;
  final VoidCallback onToggle;

  const _Header({
    required this.person,
    required this.showDiff,
    required this.diff,
    required this.diffSign,
    required this.diffColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4D35E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            person.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262626),
            ),
          ),
          Positioned(
            right: 36,
            child: AnimatedOpacity(
              opacity: showDiff ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                '$diffSign R\$ ${formatMoney(diff.abs())}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: diffColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: showDiff
                      ? const Color(0xFF262626)
                      : Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Δ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: showDiff ? Colors.white : const Color(0xFF262626),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final Map<String, double> byOrigem;
  final List<String> keys;
  final double total;

  const _Table({
    required this.byOrigem,
    required this.keys,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderSide = BorderSide(color: theme.colorScheme.outlineVariant);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final rows = <TableRow>[
      TableRow(
        children: [
          _Cell(
              text: 'Despesas agrupadas',
              style: headerStyle,
              border: Border(bottom: borderSide)),
          _Cell(
              text: 'Valor (R\$)',
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
      for (final k in keys)
        if ((byOrigem[k] ?? 0) != 0)
          TableRow(
            children: [
              _Cell(
                  text: k,
                  style: cellStyle,
                  border: Border(bottom: borderSide)),
              _Cell(
                  text: formatMoney(byOrigem[k]!),
                  style: cellStyle,
                  align: TextAlign.right,
                  border: Border(bottom: borderSide)),
              _Cell(
                  text: total > 0 ? formatPct(byOrigem[k]! / total) : '—',
                  style: cellStyle,
                  align: TextAlign.right,
                  border: Border(bottom: borderSide)),
            ],
          ),
      TableRow(
        children: [
          _Cell(
              text: 'Total Pessoal',
              style: cellStyle?.copyWith(fontWeight: FontWeight.bold),
              border: Border(top: BorderSide(color: theme.colorScheme.onSurface, width: 1.5))),
          _Cell(
              text: formatMoney(total),
              style: cellStyle?.copyWith(fontWeight: FontWeight.bold),
              align: TextAlign.right,
              border: Border(top: BorderSide(color: theme.colorScheme.onSurface, width: 1.5))),
          _Cell(
              text: total > 0 ? formatPct(1) : '—',
              style: cellStyle?.copyWith(fontWeight: FontWeight.bold),
              align: TextAlign.right,
              border: Border(top: BorderSide(color: theme.colorScheme.onSurface, width: 1.5))),
        ],
      ),
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: IntrinsicColumnWidth(),
      },
      children: rows,
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
