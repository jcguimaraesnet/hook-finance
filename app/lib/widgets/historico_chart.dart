// Spec: docs/specs/cards/historico-chart.md
//
// fl_chart LineChart. Mobile mostra últimos 6 meses; tablet/PC mostra todos.
// Diferenças aceitas vs PWA: hover-line tracejada e datalabels permanentes —
// fl_chart oferece tooltip on-tap por padrão; mantemos isso.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/format/dates.dart';
import '../core/format/money.dart';
import '../theme/breakpoints.dart';

class HistoricoSeries {
  final String label;
  final List<double> data;
  final Color color;
  const HistoricoSeries({
    required this.label,
    required this.data,
    required this.color,
  });
}

class HistoricoChart extends StatelessWidget {
  final String title;
  final List<String> months;
  final List<HistoricoSeries> series;
  final bool showLegend;

  const HistoricoChart({
    super.key,
    required this.title,
    required this.months,
    required this.series,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;
    final visibleMonths = isMobile ? _tail(months, 6) : months;
    final visibleSeries = isMobile
        ? series
            .map((s) => HistoricoSeries(
                  label: s.label,
                  data: _tail(s.data, 6),
                  color: s.color,
                ))
            .toList()
        : series;

    final allValues = visibleSeries.expand((s) => s.data);
    final maxY = allValues.isEmpty
        ? 1.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 8),
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
            SizedBox(
              height: 280,
              child: visibleMonths.isEmpty
                  ? Center(
                      child: Text(
                        'Sem dados',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (visibleMonths.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        lineBarsData: [
                          for (final s in visibleSeries)
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < s.data.length; i++)
                                  FlSpot(i.toDouble(), s.data[i]),
                              ],
                              isCurved: true,
                              curveSmoothness: 0.2,
                              color: s.color,
                              barWidth: 1.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, _, _, _) =>
                                    FlDotCirclePainter(
                                  radius: 2.5,
                                  color: s.color,
                                  strokeWidth: 0,
                                ),
                              ),
                            ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              interval: maxY / 4,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    moneyK(value),
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                final i = value.toInt();
                                if (i < 0 || i >= visibleMonths.length) {
                                  return const SizedBox.shrink();
                                }
                                if (i % 2 != 0) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    brDateToMMYYYY(visibleMonths[i]),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: theme.colorScheme.outlineVariant,
                            strokeWidth: 0.5,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => [
                              for (final spot in spots)
                                LineTooltipItem(
                                  '${visibleSeries[spot.barIndex].label}: '
                                  'R\$ ${formatMoney(spot.y)}',
                                  TextStyle(
                                    color: visibleSeries[spot.barIndex].color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          getTouchedSpotIndicator: (_, indexes) => indexes
                              .map((_) => TouchedSpotIndicatorData(
                                    FlLine(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                      strokeWidth: 1,
                                    ),
                                    FlDotData(show: true),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
            ),
            if (showLegend && visibleSeries.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final s in visibleSeries)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(s.label,
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<T> _tail<T>(List<T> list, int n) =>
    list.length <= n ? list : list.sublist(list.length - n);
