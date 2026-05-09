// Spec: docs/specs/pages/compart.md
// Cartão compartilhado por categoria — 2 tiles topo + tabela com bar inline.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/money.dart';
import '../../core/types.dart';
import '../../state/data_providers.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_card.dart';
import '../../widgets/bloom/month_selector.dart';
import '../../widgets/bloom/screen_header.dart';

class CompartPage extends ConsumerWidget {
  const CompartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final monthAsync = ref.watch(monthDataProvider(currentMonth));
    final rows = monthAsync.value?.rows ?? const <ExpenseRow>[];
    final loading = monthAsync.isLoading && !monthAsync.hasValue;

    final cards = rows.where((r) => r.origem == 'Cartão').toList();
    final byCat = <String, _CatAgg>{};
    for (final r in cards) {
      final key = r.categoria.isEmpty ? '—' : r.categoria;
      final agg = byCat.putIfAbsent(key, () => _CatAgg());
      agg.total += r.valor;
      if (r.rateio == 'Metade') agg.compart += r.valor / 2;
    }
    final categories = byCat.entries
        .map((e) => _CatRow(
              label: e.key,
              value: e.value.total,
              compart: e.value.compart,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final grandTotal = categories.fold<double>(0, (s, c) => s + c.value);
    final grandCompart =
        categories.fold<double>(0, (s, c) => s + c.compart);
    final maxValue = categories.isEmpty
        ? 0.0
        : categories.map((c) => c.value).reduce((a, b) => a > b ? a : b);

    Future<void> onRefresh() async {
      ref.invalidate(monthDataProvider);
      try {
        await ref.read(monthDataProvider(currentMonth).future);
      } catch (_) {}
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: BloomColors.violet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: 140 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(
              kicker: 'Cartão compartilhado',
              title: 'Por categoria',
              trailing: MonthSelector(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: BloomCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL CARTÃO',
                              style: BloomTypography.kicker()),
                          const SizedBox(height: 2),
                          Text(
                            'R\$ ${formatMoney(grandTotal)}',
                            style: BloomTypography.display(
                                fontSize: 18, letterSpacing: -0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            BloomColors.violet.withValues(alpha: 0.08),
                            BloomColors.sky.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: BloomColors.violet.withValues(alpha: 0.15),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMPARTILHADO',
                            style: BloomTypography.kicker(
                                color: BloomColors.violet),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'R\$ ${formatMoney(grandCompart)}',
                            style: BloomTypography.display(
                                fontSize: 18, letterSpacing: -0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: BloomCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                borderRadius: BorderRadius.circular(22),
                child: loading && categories.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: BloomColors.violet),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                18, 10, 18, 6),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text('CATEGORIA',
                                        style: BloomTypography.kicker())),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'VALOR',
                                    textAlign: TextAlign.right,
                                    style: BloomTypography.kicker(),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    '%',
                                    textAlign: TextAlign.right,
                                    style: BloomTypography.kicker(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final c in categories)
                            _CategoryLine(
                              row: c,
                              total: grandTotal,
                              maxValue: maxValue,
                            ),
                          if (categories.isNotEmpty)
                            _TotalLine(
                                value: grandTotal),
                          if (categories.isEmpty && !loading)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24),
                              child: Center(
                                child: Text(
                                  'Sem despesas neste mês.',
                                  style: BloomTypography.geist(
                                    fontSize: 12,
                                    color: BloomColors.muted,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatAgg {
  double total = 0;
  double compart = 0;
}

class _CatRow {
  final String label;
  final double value;
  final double compart;
  const _CatRow(
      {required this.label, required this.value, required this.compart});
}

class _CategoryLine extends StatelessWidget {
  final _CatRow row;
  final double total;
  final double maxValue;

  const _CategoryLine({
    required this.row,
    required this.total,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : row.value / total * 100;
    final fillFrac = maxValue == 0 ? 0.0 : (row.value / maxValue).clamp(0.0, 1.0);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: BloomColors.divider, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillFrac,
                  child: Container(
                    decoration: BoxDecoration(
                      color: BloomColors.violet.withValues(alpha: 0.063),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: BloomColors.violet,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.label,
                        style: BloomTypography.geist(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        formatMoney(row.value),
                        textAlign: TextAlign.right,
                        style: BloomTypography.mono(fontSize: 12.5),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${pct.toStringAsFixed(2).replaceAll('.', ',')}%',
                        textAlign: TextAlign.right,
                        style: BloomTypography.mono(
                            fontSize: 11, color: BloomColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: RichText(
                    text: TextSpan(
                      style: BloomTypography.mono(
                        fontSize: 10.5,
                        color: BloomColors.muted,
                      ),
                      children: [
                        const TextSpan(text: 'Compart: '),
                        TextSpan(
                          text: row.compart > 0
                              ? 'R\$ ${formatMoney(row.compart)}'
                              : '—',
                          style: row.compart > 0
                              ? BloomTypography.mono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: BloomColors.mint,
                                )
                              : null,
                        ),
                      ],
                    ),
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

class _TotalLine extends StatelessWidget {
  final double value;
  const _TotalLine({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: BloomColors.ink, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total',
                style: BloomTypography.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                formatMoney(value),
                textAlign: TextAlign.right,
                style: BloomTypography.mono(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '100,00%',
                textAlign: TextAlign.right,
                style: BloomTypography.mono(
                    fontSize: 11, color: BloomColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
