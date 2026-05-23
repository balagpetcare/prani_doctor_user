import 'package:flutter/material.dart';

import '../core/branding/brand_theme.dart';
import '../features/home/presentation/theme/home_theme_extension.dart';
import '../features/home/presentation/theme/home_tokens.dart';

class AppTheme {
  static ThemeData light() {
    const seed = BrandColors.primary;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _base(scheme, HomeThemeExtension.light(scheme));
  }

  static ThemeData dark() {
    const seed = BrandColors.primaryLight;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme, HomeThemeExtension.dark(scheme));
  }

  static ThemeData _base(ColorScheme scheme, HomeThemeExtension home) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: HomeTokens.elevationNone,
        scrolledUnderElevation: HomeTokens.elevationLow,
        surfaceTintColor: scheme.surfaceTint,
      ),
      cardTheme: CardThemeData(
        elevation: HomeTokens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusLg),
        ),
      ),
      extensions: [home],
    );
  }
}
