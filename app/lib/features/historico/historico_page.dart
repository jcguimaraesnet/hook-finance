// Spec: docs/specs/pages/historico.md
// 2 cards: bars do total geral + line chart per-pessoa.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/types.dart';
import '../../state/data_providers.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_card.dart';
import '../../widgets/bloom/screen_header.dart';

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  int? _selectedTotalIdx;
  int? _selectedPersonIdx;

  @override
  Widget build(BuildContext context) {
    final histAsync = ref.watch(historicalSummaryProvider);
    final loading = histAsync.isLoading && !histAsync.hasValue;
    final history = histAsync.value?.history;

    Future<void> onRefresh() async {
      ref.invalidate(historicalSummaryProvider);
      try {
        await ref.read(historicalSummaryProvider.future);
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
              kicker: 'Histórico',
              title: 'Últimos 6 meses',
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                      color: BloomColors.violet),
                ),
              )
            else if (history == null || history.months.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Sem histórico.',
                    style: BloomTypography.geist(
                      fontSize: 13,
                      color: BloomColors.muted,
                    ),
                  ),
                ),
              )
            else ...[
              _TotalCard(
                history: history,
                selectedIdx: _selectedTotalIdx,
                onSelect: (i) => setState(() {
                  _selectedTotalIdx = (_selectedTotalIdx == i) ? null : i;
                }),
              ),
              const SizedBox(height: 14),
              _PersonalCard(
                history: history,
                selectedIdx: _selectedPersonIdx,
                onSelect: (i) => setState(() {
                  _selectedPersonIdx = (_selectedPersonIdx == i) ? null : i;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<int> _last6Indexes(int n) {
  if (n <= 6) return List.generate(n, (i) => i);
  return List.generate(6, (i) => n - 6 + i);
}

class _TotalCard extends StatelessWidget {
  final HistoricalSummary history;
  final int? selectedIdx;
  final ValueChanged<int> onSelect;

  const _TotalCard({
    required this.history,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final idx = _last6Indexes(history.totals.length);
    final months = idx.map((i) => mmYYYY(history.months[i])).toList();
    final totals = idx.map((i) => history.totals[i]).toList();

    final viewIdx = selectedIdx ?? totals.length - 1;
    final viewValue = totals.isEmpty ? 0.0 : totals[viewIdx];
    final prev = viewIdx > 0 ? totals[viewIdx - 1] : null;
    final delta = (prev == null || prev == 0)
        ? null
        : (viewValue - prev) / prev * 100;
    final selectedLabel =
        selectedIdx != null && selectedIdx! < months.length
            ? months[selectedIdx!]
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: BloomCard(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('TOTAL GERAL',
                              style: BloomTypography.kicker()),
                          if (selectedLabel != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· $selectedLabel',
                              style: BloomTypography.mono(
                                fontSize: 10.5,
                                color: BloomColors.violet,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'R\$ ${formatMoney(viewValue)}',
                        style: BloomTypography.display(
                            fontSize: 22, letterSpacing: -0.4),
                      ),
                    ],
                  ),
                ),
                if (delta != null)
                  _DeltaBadge(value: delta),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: _BarsChart(
                months: months,
                values: totals,
                selectedIdx: selectedIdx,
                onSelect: onSelect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarsChart extends StatelessWidget {
  final List<String> months;
  final List<double> values;
  final int? selectedIdx;
  final ValueChanged<int> onSelect;

  const _BarsChart({
    required this.months,
    required this.values,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.reduce((a, b) => a > b ? a : b);
    final lastIdx = values.length - 1;
    final highlightedIdx = selectedIdx ?? lastIdx;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: max == 0 ? 1 : max * 1.18,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response?.spot != null) {
              onSelect(response!.spot!.touchedBarGroupIndex);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 0,
            getTooltipItem: (_, _, _, _) => null,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 16,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= values.length) return const SizedBox();
                final isHi = i == highlightedIdx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    moneyK(values[i]),
                    style: BloomTypography.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isHi
                          ? BloomColors.violet
                          : BloomColors.muted,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox();
                // Alterna: mostra apenas índices pares (0, 2, 4) — exceto se
                // for o último mês, sempre exibido.
                final showIt = i % 2 == 0 || i == lastIdx;
                if (!showIt) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    months[i],
                    style: BloomTypography.mono(
                      fontSize: 9,
                      color: BloomColors.muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                  gradient: i == highlightedIdx
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            BloomColors.violet,
                            Color(0xCC6E5CE7),
                          ],
                        )
                      : null,
                  color: i == highlightedIdx
                      ? null
                      : BloomColors.violet.withValues(alpha: 0.20),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PersonalCard extends StatelessWidget {
  final HistoricalSummary history;
  final int? selectedIdx;
  final ValueChanged<int> onSelect;

  const _PersonalCard({
    required this.history,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final idx = _last6Indexes(history.julioPessoal.length);
    final months = idx.map((i) => mmYYYY(history.months[i])).toList();
    final ju = idx.map((i) => history.julioPessoal[i]).toList();
    final da = idx.map((i) => history.daniPessoal[i]).toList();

    final viewIdx = selectedIdx ?? (ju.length - 1).clamp(0, ju.length - 1);
    final viewJulio = ju.isEmpty ? 0.0 : ju[viewIdx];
    final viewDani = da.isEmpty ? 0.0 : da[viewIdx];
    final viewMonth = months.isEmpty ? '' : months[viewIdx];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: BloomCard(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('POR PESSOA',
                          style: BloomTypography.kicker()),
                      Text(
                        'Despesas pessoais',
                        style: BloomTypography.display(
                          fontSize: 18,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: const [
                    _LegendChip(
                        color: BloomColors.violet, label: 'Júlio'),
                    SizedBox(width: 10),
                    _LegendChip(color: BloomColors.mint, label: 'Dani'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: _PersonalLines(
                months: months,
                julio: ju,
                dani: da,
                selectedIdx: selectedIdx,
                onSelect: onSelect,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniTile(
                    label: 'Júlio · $viewMonth',
                    value: viewJulio,
                    color: BloomColors.violet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniTile(
                    label: 'Dani · $viewMonth',
                    value: viewDani,
                    color: BloomColors.mint,
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

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: BloomTypography.mono(
            fontSize: 10.5,
            color: BloomColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _PersonalLines extends StatelessWidget {
  final List<String> months;
  final List<double> julio;
  final List<double> dani;
  final int? selectedIdx;
  final ValueChanged<int> onSelect;

  const _PersonalLines({
    required this.months,
    required this.julio,
    required this.dani,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (julio.isEmpty || dani.isEmpty) return const SizedBox.shrink();
    final all = [...julio, ...dani];
    final max = all.reduce((a, b) => a > b ? a : b);
    final min = all.reduce((a, b) => a < b ? a : b);
    final lastIdx = months.length - 1;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).toDouble(),
        minY: min - (max - min) * 0.1,
        maxY: max + (max - min) * 0.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            getTooltipItems: (spots) =>
                List.filled(spots.length, null),
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              onSelect(response.lineBarSpots!.first.x.toInt());
            }
          },
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox();
                final showIt = i % 2 == 0 || i == lastIdx;
                if (!showIt) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    months[i],
                    style: BloomTypography.mono(
                      fontSize: 9,
                      color: BloomColors.muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          _line(julio, BloomColors.violet, lastIdx, selectedIdx),
          _line(dani, BloomColors.mint, lastIdx, selectedIdx),
        ],
      ),
    );
  }

  LineChartBarData _line(
      List<double> values, Color color, int lastIdx, int? sel) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++)
          FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: false,
      color: color,
      barWidth: 2.4,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, _, idx) {
          final isHi = idx == (sel ?? lastIdx);
          return FlDotCirclePainter(
            radius: isHi ? 5 : 2.5,
            color: color,
            strokeWidth: isHi ? 2 : 0,
            strokeColor: Colors.white,
          );
        },
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: BloomTypography.kicker(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'R\$ ${moneyK(value)}',
            style: BloomTypography.display(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double value;
  const _DeltaBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final up = value > 0;
    final tone = up ? BloomColors.bad : BloomColors.good;
    final symbol = up ? '↗' : '↘';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$symbol ${value.abs().toStringAsFixed(1).replaceAll('.', ',')}%',
        style: BloomTypography.mono(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: tone,
        ),
      ),
    );
  }
}
