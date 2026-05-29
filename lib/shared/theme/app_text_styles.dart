import 'package:flutter/material.dart';

/// Theme-derived text style accessors.
///
/// Prefer these over inline `TextStyle(...)` so typography stays consistent and
/// theme/dark-mode aware. All styles resolve from the ambient [TextTheme].
extension AppTextStyles on BuildContext {
  TextTheme get _t => Theme.of(this).textTheme;
  ColorScheme get _c => Theme.of(this).colorScheme;

  TextStyle? get titleStyle => _t.titleMedium;
  TextStyle? get sectionTitleStyle =>
      _t.titleSmall?.copyWith(fontWeight: FontWeight.w600);
  TextStyle? get bodyStyle => _t.bodyMedium;
  TextStyle? get captionStyle =>
      _t.bodySmall?.copyWith(color: _c.onSurfaceVariant);
  TextStyle? get errorStyle => _t.bodyMedium?.copyWith(color: _c.error);
}
