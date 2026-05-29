import 'package:flutter/material.dart';

import 'app_localizations.dart';

export 'app_localizations.dart' show AppLocalizations;

/// Project-standard access: `context.tr.navHome` or `context.tr.tr(TranslationKeys.x)`.
extension LocalizationContext on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this)!;
}

extension AppLocalizationsTranslate on AppLocalizations {
  /// Alias for dynamic JSON keys not yet exposed as getters.
  String t(String key, [Map<String, Object?>? args]) => translate(key, args);
}
