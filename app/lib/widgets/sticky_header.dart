// Spec: docs/specs/pages/lancamento.md (modo disabled)
// Spec: docs/specs/pages/consulta.md (filtro de mês)
// Spec: docs/specs/rules/parcela-format.md (isParcelado)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/format/money.dart';
import '../core/rules/parcela.dart';
import '../core/types.dart';
import '../state/data_providers.dart';

class StickyHeader extends ConsumerWidget {
  final bool disabled;
  const StickyHeader({super.key, this.disabled = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final allMonths = ref.watch(allMonthsProvider);
    final monthArg = disabled ? null : currentMonth;
    final monthAsync = ref.watch(monthDataProvider(monthArg));

    final rows = monthAsync.value?.rows ?? const <ExpenseRow>[];
    final loading = monthAsync.isLoading && !monthAsync.hasValue;
    final displayMonth = disabled ? monthAsync.value?.month : currentMonth;

    final totalGeral = rows.fold<double>(0, (s, r) => s + r.valor);
    final totalCartao = rows
        .where((r) => r.origem == 'Cartão')
        .fold<double>(0, (s, r) => s + r.valor);
    final totalParcelado = rows
        .where((r) => isParcelado(r.parcela))
        .fold<double>(0, (s, r) => s + r.valor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MonthPicker(
              disabled: disabled || allMonths.isEmpty,
              displayMonth: displayMonth,
              months: disabled ? const [] : allMonths,
              onChanged: (m) =>
                  ref.read(currentMonthProvider.notifier).state = m,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    label: 'Total geral',
                    value: totalGeral,
                    loading: loading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Tile(
                    label: 'Total cartão',
                    value: totalCartao,
                    loading: loading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Tile(
                    label: 'Total parcelado',
                    value: totalParcelado,
                    loading: loading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final bool disabled;
  final String? displayMonth;
  final List<String> months;
  final ValueChanged<String?> onChanged;

  const _MonthPicker({
    required this.disabled,
    required this.displayMonth,
    required this.months,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Data',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: displayMonth,
          items: [
            if (months.isEmpty && displayMonth != null)
              DropdownMenuItem(value: displayMonth, child: Text(displayMonth!)),
            for (final m in months)
              DropdownMenuItem(value: m, child: Text(m)),
          ],
          onChanged: disabled ? null : onChanged,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final double value;
  final bool loading;

  const _Tile({
    required this.label,
    required this.value,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          loading
              ? Container(
                  height: 18,
                  width: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  formatMoney(value),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
        ],
      ),
    );
  }
}
