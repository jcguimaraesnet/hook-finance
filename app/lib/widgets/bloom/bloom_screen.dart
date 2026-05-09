// Scaffold base — gradient lavanda→off-white→menta + decorative shapes + safe area.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/bloom_colors.dart';
import 'bloom_shapes.dart';

class BloomScreen extends StatelessWidget {
  final Widget child;
  final Widget? bottomNav;
  final bool showShapes;
  final EdgeInsetsGeometry? padding;

  const BloomScreen({
    super.key,
    required this.child,
    this.bottomNav,
    this.showShapes = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: BloomColors.bg2,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: BloomColors.screenGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                if (showShapes)
                  const Positioned.fill(child: BloomShapes()),
                Positioned.fill(
                  child: Padding(
                    padding: padding ?? EdgeInsets.zero,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: bottomNav,
          extendBody: bottomNav != null,
        ),
      ),
    );
  }
}
