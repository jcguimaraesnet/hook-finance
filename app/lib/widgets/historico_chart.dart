// Spec: docs/specs/cards/historico-chart.md
//
// fl_chart LineChart com datalabels permanentes via Stack overlay (mesma
// abordagem do PWA via plugin datalabels do Chart.js). Tooltip de touch
// usa cor inverseSurface do Material 3 — leg ível em ambos os temas.

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

  // Reserved sizes (precisam casar com leftTitles/bottomTitles abaixo).
  static const double _chartLeftPad = 44;
  static const double _chartRightPad = 8;
  static const double _chartTopPad = 16;
  static const double _chartBottomPad = 28;

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
        : allValues.reduce((a, b) => a > b ? a : b) * 1.15;
    final maxX = (visibleMonths.length - 1).clamp(1, 1 << 30).toDouble();

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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            _buildChart(theme, visibleMonths, visibleSeries,
                                maxY, maxX),
                            ..._buildDataLabels(
                              constraints,
                              visibleMonths,
                              visibleSeries,
                              maxY,
                              maxX,
                            ),
                          ],
                        );
                      },
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
                          Text(s.label, style: theme.textTheme.bodySmall),
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

  Widget _buildChart(
    ThemeData theme,
    List<String> visibleMonths,
    List<HistoricoSeries> visibleSeries,
    double maxY,
    double maxX,
  ) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
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
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
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
              reservedSize: _chartLeftPad,
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
              reservedSize: _chartBottomPad,
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
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            tooltipRoundedRadius: 6,
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${visibleSeries[spot.barIndex].label}: '
                  'R\$ ${formatMoney(spot.y)}',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
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
    );
  }

  /// Renderiza moneyK acima/abaixo de cada ponto (substitui o plugin
  /// datalabels do Chart.js).
  List<Widget> _buildDataLabels(
    BoxConstraints constraints,
    List<String> visibleMonths,
    List<HistoricoSeries> visibleSeries,
    double maxY,
    double maxX,
  ) {
    final chartWidth =
        constraints.maxWidth - _chartLeftPad - _chartRightPad;
    final chartHeight =
        constraints.maxHeight - _chartTopPad - _chartBottomPad;
    if (chartWidth <= 0 || chartHeight <= 0 || maxY <= 0 || maxX <= 0) {
      return const [];
    }

    final widgets = <Widget>[];
    for (var sIdx = 0; sIdx < visibleSeries.length; sIdx++) {
      final s = visibleSeries[sIdx];
      // Série única ou primeira (Júlio) -> rótulos acima do ponto.
      // Demais (Dani) -> abaixo. Replica regra align "top"/"bottom" do PWA.
      final above = visibleSeries.length == 1 || sIdx == 0;
      for (var i = 0; i < s.data.length; i++) {
        final yData = s.data[i];
        if (yData == 0) continue; // não mostra label para zero
        final px = _chartLeftPad + (i / maxX) * chartWidth;
        final py = _chartTopPad + (1 - yData / maxY) * chartHeight;
        widgets.add(Positioned(
          left: px - 22,
          top: above ? py - 16 : py + 4,
          width: 44,
          child: Text(
            moneyK(yData),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: s.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}

List<T> _tail<T>(List<T> list, int n) =>
    list.length <= n ? list : list.sublist(list.length - n);
