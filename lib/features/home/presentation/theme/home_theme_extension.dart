import 'package:flutter/material.dart';

import 'home_tokens.dart';

/// Home-specific theme tokens layered on [ThemeData] (light + dark).
@immutable
class HomeThemeExtension extends ThemeExtension<HomeThemeExtension> {
  const HomeThemeExtension({
    required this.cardElevation,
    required this.raisedElevation,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.sectionDivider,
  });

  final double cardElevation;
  final double raisedElevation;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color sectionDivider;

  static HomeThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<HomeThemeExtension>() ??
        HomeThemeExtension.light(Theme.of(context).colorScheme);
  }

  static HomeThemeExtension light(ColorScheme scheme) => HomeThemeExtension(
    cardElevation: HomeTokens.elevationNone,
    raisedElevation: HomeTokens.elevationLow,
    shimmerBase: scheme.surfaceContainerHighest,
    shimmerHighlight: scheme.surfaceContainerLow,
    sectionDivider: scheme.outlineVariant.withValues(alpha: 0.6),
  );

  static HomeThemeExtension dark(ColorScheme scheme) => HomeThemeExtension(
    cardElevation: HomeTokens.elevationNone,
    raisedElevation: HomeTokens.elevationMid,
    shimmerBase: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
    shimmerHighlight: scheme.surfaceContainerLow.withValues(alpha: 0.85),
    sectionDivider: scheme.outlineVariant.withValues(alpha: 0.35),
  );

  @override
  HomeThemeExtension copyWith({
    double? cardElevation,
    double? raisedElevation,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? sectionDivider,
  }) {
    return HomeThemeExtension(
      cardElevation: cardElevation ?? this.cardElevation,
      raisedElevation: raisedElevation ?? this.raisedElevation,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      sectionDivider: sectionDivider ?? this.sectionDivider,
    );
  }

  @override
  HomeThemeExtension lerp(ThemeExtension<HomeThemeExtension>? other, double t) {
    if (other is! HomeThemeExtension) return this;
    return HomeThemeExtension(
      cardElevation: cardElevation + (other.cardElevation - cardElevation) * t,
      raisedElevation:
          raisedElevation + (other.raisedElevation - raisedElevation) * t,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      sectionDivider: Color.lerp(sectionDivider, other.sectionDivider, t)!,
    );
  }
}
