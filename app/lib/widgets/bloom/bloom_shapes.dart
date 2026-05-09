// Decorative shapes do background — radial blobs + dots geométricos.

import 'package:flutter/material.dart';
import '../../theme/bloom_colors.dart';

class BloomShapes extends StatelessWidget {
  const BloomShapes({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Blob violeta canto superior-direito
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(
              size: 220,
              color: BloomColors.violet,
              alignment: const Alignment(-0.4, -0.4),
            ),
          ),
          // Blob menta canto esquerdo
          Positioned(
            top: 220,
            left: -60,
            child: _Blob(
              size: 180,
              color: BloomColors.mint,
              alignment: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final Alignment alignment;
  const _Blob({
    required this.size,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: alignment,
          radius: 0.65,
          colors: [
            color.withValues(alpha: 0.33),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
