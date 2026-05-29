import 'package:flutter/widgets.dart';

/// App-wide spacing scale on a 4pt grid.
///
/// Generalizes the home-only `HomeTokens` spacing so every feature can use a
/// consistent scale instead of ad-hoc `EdgeInsets.all(16)` literals.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Common page paddings.
  static const EdgeInsets page = EdgeInsets.all(lg);
  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pageV = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Const-friendly vertical/horizontal gaps to avoid repeated `SizedBox`.
abstract final class Gap {
  Gap._();

  static const Widget xs = SizedBox(height: AppSpacing.xs, width: AppSpacing.xs);
  static const Widget sm = SizedBox(height: AppSpacing.sm, width: AppSpacing.sm);
  static const Widget md = SizedBox(height: AppSpacing.md, width: AppSpacing.md);
  static const Widget lg = SizedBox(height: AppSpacing.lg, width: AppSpacing.lg);
  static const Widget xl = SizedBox(height: AppSpacing.xl, width: AppSpacing.xl);

  static const Widget h8 = SizedBox(height: AppSpacing.sm);
  static const Widget h12 = SizedBox(height: AppSpacing.md);
  static const Widget h16 = SizedBox(height: AppSpacing.lg);
  static const Widget h24 = SizedBox(height: AppSpacing.xxl);
  static const Widget w8 = SizedBox(width: AppSpacing.sm);
  static const Widget w12 = SizedBox(width: AppSpacing.md);
  static const Widget w16 = SizedBox(width: AppSpacing.lg);
}
