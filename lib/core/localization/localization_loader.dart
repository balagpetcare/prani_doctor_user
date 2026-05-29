import 'dart:convert';

import 'package:flutter/services.dart';

import '../errors/safe_parse.dart';
import '../logging/app_logger.dart';

/// Preloads [assets/i18n/en.json] and [bn.json] before [runApp].
abstract final class LocalizationLoader {
  static Map<String, Map<String, String>>? _byLocale;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final en = await _loadJson('assets/i18n/en.json');
    var bn = await _loadJson('assets/i18n/bn.json');
    if (bn.isEmpty && en.isNotEmpty) {
      AppLog.warn(
        'bn.json empty or failed — falling back to English strings',
        tag: 'L10n',
      );
      bn = en;
    }
    _byLocale = {'en': en, 'bn': bn};
    _initialized = true;
  }

  static Future<Map<String, String>> _loadJson(String asset) async {
    try {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw);
      final map = SafeParse.map(decoded, context: asset);
      return map.map((key, value) {
        if (key.startsWith('@')) return MapEntry(key, '');
        if (value is! String) return MapEntry(key, '');
        return MapEntry(key, value);
      })..removeWhere((key, value) => key.startsWith('@') || value.isEmpty);
    } catch (e, st) {
      AppLog.error(
        'Failed to load localization asset',
        tag: 'L10n',
        error: e,
        stackTrace: st,
        reportToCrashReporter: false,
      );
      return {};
    }
  }

  static Map<String, String> stringsFor(String languageCode) {
    final maps = _byLocale;
    if (maps == null) return const {};
    return maps[languageCode] ?? maps['bn'] ?? maps['en'] ?? const {};
  }

  static String lookup(String languageCode, String key) {
    return stringsFor(languageCode)[key] ?? key;
  }
}
