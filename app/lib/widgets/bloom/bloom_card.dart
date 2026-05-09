// Card branco padrão do design Bloom — radius 22, border 1px, sombra suave opcional.

import 'package:flutter/material.dart';
import '../../theme/bloom_colors.dart';

class BloomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool soft;
  final VoidCallback? onTap;
  final Border? border;

  const BloomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius,
    this.color,
    this.soft = false,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(22);
    final decoration = BoxDecoration(
      color: color ?? BloomColors.card,
      borderRadius: radius,
      border: border ?? Border.all(color: BloomColors.border, width: 1),
      boxShadow: soft
          ? [
              BoxShadow(
                color: BloomColors.violet.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );

    final content = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}
