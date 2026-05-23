import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Brand colors aligned with Prani Doctor identity.
abstract final class BrandColors {
  BrandColors._();

  static const primary = Color(0xFF0D9488);
  static const primaryLight = Color(0xFF5EEAD4);
  static const splashBackground = Color(0xFFFFFFFF);
  static const onboardingBackground = Color(0xFF020D0B);
  static const illustrationBackground = Color(0xFFE8F5F3);
  static const white = Color(0xFFFFFFFF);
}

abstract final class BrandTheme {
  BrandTheme._();

  static ThemeData light() => AppTheme.light();

  static ThemeData dark() => AppTheme.dark();

  static BoxDecoration splashBackground() =>
      const BoxDecoration(color: BrandColors.splashBackground);
}
