// Spec: docs/specs/responsive/breakpoints.md

import 'package:flutter/widgets.dart';

const double _tabletMin = 640;
const double _pcMin = 750;

enum Breakpoint { mobile, tablet, pc }

extension BreakpointX on BuildContext {
  Breakpoint get bp {
    final w = MediaQuery.of(this).size.width;
    if (w >= _pcMin) return Breakpoint.pc;
    if (w >= _tabletMin) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }

  bool get isMobile => bp == Breakpoint.mobile;
  bool get isTabletOrUp => bp != Breakpoint.mobile;
  bool get isPC => bp == Breakpoint.pc;
}
