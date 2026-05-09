// Donut clicável (3 arcos compart/pessoal/contas) com label central reativo.
// Spec: docs/specs/pages/inicio.md (donut interativo).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/format/money.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';

class DonutBucket {
  final String label;
  final double value;
  final double pct;
  const DonutBucket(
      {required this.label, required this.value, required this.pct});
}

class BloomDonut extends StatelessWidget {
  final List<DonutBucket> buckets;
  final double total;
  final String person;
  final int? selectedIdx;
  final ValueChanged<int?> onSelect;
  final double size;
  final double stroke;

  const BloomDonut({
    super.key,
    required this.buckets,
    required this.total,
    required this.person,
    required this.selectedIdx,
    required this.onSelect,
    this.size = 170,
    this.stroke = 18,
  });

  static const _colors = [
    BloomColors.violet, // compart
    BloomColors.mint,   // pessoal
    BloomColors.sky,    // contas
  ];
  static const _labels = ['Compart.', 'Pessoal', 'Contas'];

  @override
  Widget build(BuildContext context) {
    final sel = selectedIdx;
    final centerColor = sel != null ? _colors[sel] : BloomColors.ink;
    final centerLabel = sel != null ? _labels[sel] : person;
    final centerValue =
        sel != null ? buckets[sel].value : total;
    final centerSub = sel != null
        ? '${buckets[sel].pct.toStringAsFixed(1).replaceAll('.', ',')}%'
        : 'R\$ pessoal';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final hit = _hitTest(d.localPosition);
              onSelect(hit == selectedIdx ? null : hit);
            },
            child: CustomPaint(
              size: Size.square(size),
              painter: _DonutPainter(
                buckets: buckets,
                colors: _colors,
                stroke: stroke,
                selectedIdx: selectedIdx,
              ),
            ),
          ),
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerLabel,
                  style: BloomTypography.geist(
                    fontSize: 11,
                    fontWeight: sel != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: sel != null
                        ? centerColor
                        : BloomColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'R\$ ${formatMoney(centerValue)}',
                  style: BloomTypography.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: centerColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  centerSub,
                  style: BloomTypography.mono(
                    fontSize: 10,
                    color: BloomColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Determina qual arco foi tocado, ou `null` se foi fora do donut.
  int? _hitTest(Offset local) {
    final c = Offset(size / 2, size / 2);
    final dx = local.dx - c.dx;
    final dy = local.dy - c.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final r = (size - stroke) / 2;
    final inner = r - stroke / 2 - 4;
    final outer = r + stroke / 2 + 4;
    if (dist < inner || dist > outer) return null;

    // Ângulo do toque a partir do topo, em sentido horário, [0, 2π).
    final raw = math.atan2(dy, dx); // [-π, π], 0 = leste
    var fromTop = raw + math.pi / 2;
    if (fromTop < 0) fromTop += 2 * math.pi;
    final pctAt = fromTop / (2 * math.pi) * 100;

    var acc = 0.0;
    for (var i = 0; i < buckets.length; i++) {
      final start = acc;
      final end = acc + buckets[i].pct;
      if (pctAt >= start && pctAt < end) return i;
      acc = end;
    }
    return null;
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutBucket> buckets;
  final List<Color> colors;
  final double stroke;
  final int? selectedIdx;

  _DonutPainter({
    required this.buckets,
    required this.colors,
    required this.stroke,
    required this.selectedIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Trilho de fundo (anel completo).
    final track = Paint()
      ..color = BloomColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(c, r, track);

    // Gap angular (em radianos) entre cada arco — corresponde a ~3px de arco.
    final gap = 3 / r;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < buckets.length; i++) {
      final pct = buckets[i].pct.clamp(0.0, 100.0);
      var sweep = pct / 100 * 2 * math.pi - gap;
      if (sweep < 0) sweep = 0;

      final isSel = selectedIdx == i;
      final dim = selectedIdx != null && !isSel;
      final color = colors[i].withValues(alpha: dim ? 0.35 : 1.0);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSel ? stroke + 4 : stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.buckets != buckets ||
      old.selectedIdx != selectedIdx ||
      old.stroke != stroke;
}
