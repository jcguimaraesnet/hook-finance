// Logo "h" com conic-gradient (violet → sky → mint → pink → violet).
// O CSS `conic-gradient(from 220deg)` é emulado via SweepGradient + GradientRotation.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/bloom_colors.dart';

class BloomLogo extends StatelessWidget {
  final double size;
  const BloomLogo({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final innerInset = size * 0.13;
    final outerRadius = size * 0.32;
    final innerRadius = size * 0.20;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        gradient: const SweepGradient(
          colors: [
            BloomColors.violet,
            BloomColors.sky,
            BloomColors.mint,
            BloomColors.pink,
            BloomColors.violet,
          ],
          // CSS conic-gradient(from 220deg) → SweepGradient.transform rotates
          // so that o stop 0 fica em 220° clockwise a partir do topo.
          // Em radianos: -π/2 (topo) + 220° = -π/2 + 220·π/180 ≈ 2.269.
          transform: GradientRotation(
            -math.pi / 2 + 220 * math.pi / 180,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BloomColors.violet.withValues(alpha: 0.27),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(innerInset),
        child: Container(
          decoration: BoxDecoration(
            color: BloomColors.bg3,
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            'h',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w700,
              color: BloomColors.ink,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
