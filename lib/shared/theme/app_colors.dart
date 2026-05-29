import 'package:flutter/material.dart';

/// Semantic status tone used by status chips, badges and cards.
///
/// Centralizes the meaning → color mapping so widgets stop hardcoding
/// `Colors.green` / `Colors.grey` etc. directly.
enum StatusTone { neutral, info, positive, warning, danger, muted }

/// Single source of truth for semantic status colors.
///
/// Provides separate light- and dark-mode palettes so chips and badges
/// remain legible on both surfaces. Use [AppStatusChip] or call
/// [AppStatusColors.of] inside a [BuildContext]-aware widget.
abstract final class AppStatusColors {
  AppStatusColors._();

  // ── Light palette ────────────────────────────────────────────────────
  static const Color neutral = Color(0xFF607D8B); // blue-grey 600
  static const Color info = Color(0xFF1976D2); // blue 700
  static const Color positive = Color(0xFF2E7D32); // green 800
  static const Color warning = Color(0xFFF57F17); // amber 900
  static const Color danger = Color(0xFFC62828); // red 800
  static const Color muted = Color(0xFF757575); // grey 600

  // ── Dark palette (higher-value hues for legibility on dark surfaces) ─
  static const Color neutralDark = Color(0xFF90A4AE); // blue-grey 300
  static const Color infoDark = Color(0xFF64B5F6); // blue 300
  static const Color positiveDark = Color(0xFF81C784); // green 300
  static const Color warningDark = Color(0xFFFFD54F); // amber 300
  static const Color dangerDark = Color(0xFFEF9A9A); // red 200
  static const Color mutedDark = Color(0xFFBDBDBD); // grey 400

  /// Returns the correct color for the current [Brightness].
  static Color forTone(StatusTone tone, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return switch (tone) {
        StatusTone.neutral => neutralDark,
        StatusTone.info => infoDark,
        StatusTone.positive => positiveDark,
        StatusTone.warning => warningDark,
        StatusTone.danger => dangerDark,
        StatusTone.muted => mutedDark,
      };
    }
    return of(tone);
  }

  /// Returns the light-mode color for [tone]. Use [forTone] when you have
  /// a [BuildContext] (or know the brightness).
  static Color of(StatusTone tone) => switch (tone) {
    StatusTone.neutral => neutral,
    StatusTone.info => info,
    StatusTone.positive => positive,
    StatusTone.warning => warning,
    StatusTone.danger => danger,
    StatusTone.muted => muted,
  };
}
