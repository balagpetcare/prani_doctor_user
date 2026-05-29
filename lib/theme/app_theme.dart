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

      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: HomeTokens.elevationNone,
        scrolledUnderElevation: HomeTokens.elevationLow,
        surfaceTintColor: scheme.surfaceTint,
      ),

      // ── Cards ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: HomeTokens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusLg),
        ),
      ),

      // ── Input fields ─────────────────────────────────────────────────
      // All TextFields/TextFormFields inherit consistent M3 outline decoration.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HomeTokens.space16,
          vertical: HomeTokens.space12,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        errorStyle: TextStyle(color: scheme.error),
        isDense: false,
      ),

      // ── Buttons ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTokens.space24,
            vertical: HomeTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTokens.space24,
            vertical: HomeTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTokens.space16,
            vertical: HomeTokens.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
          ),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusSm),
        ),
      ),

      // ── Dialogs ──────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusXl),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      // ── Bottom sheets ────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HomeTokens.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        elevation: HomeTokens.elevationLow,
      ),

      // ── Snack bar ────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radiusSm),
        ),
      ),

      extensions: [home],
    );
  }
}
