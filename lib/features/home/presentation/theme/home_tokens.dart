import 'package:flutter/material.dart';

/// Spacing, motion, layout, and elevation tokens for the home dashboard.
abstract final class HomeTokens {
  HomeTokens._();

  // Breakpoints
  static const tabletBreakpoint = 600.0;
  static const maxContentWidth = 720.0;

  // Spacing scale (4pt grid)
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;

  // Radii
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;

  // Motion (implicit animations)
  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 220);
  static const durationSlow = Duration(milliseconds: 320);
  static const curveStandard = Curves.easeOutCubic;

  // Elevation (Material 3 tonal surfaces — logical levels)
  static const elevationNone = 0.0;
  static const elevationLow = 1.0;
  static const elevationMid = 2.0;
  static const elevationHigh = 4.0;

  // Scroll / lazy load
  static const scrollCacheExtent = 480.0;
  static const lazySectionScrollChunk = 320.0;
  static const horizontalListCacheExtent = 240.0;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// RTL-safe horizontal inset; centers content on tablet.
  static EdgeInsetsDirectional pageHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= maxContentWidth) {
      return const EdgeInsetsDirectional.only(start: space16, end: space16);
    }
    final gutter = (width - maxContentWidth) / 2;
    return EdgeInsetsDirectional.only(start: gutter, end: gutter);
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    required int phone,
    required int tablet,
  }) => isTablet(context) ? tablet : phone;

  static int quickActionColumns(BuildContext context) =>
      gridCrossAxisCount(context, phone: 4, tablet: 6);

  static double bottomScrollPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 72;
}
