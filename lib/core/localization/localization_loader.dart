import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../errors/safe_parse.dart';
import '../logging/app_logger.dart';
import '../startup/startup_trace.dart';

/// Preloads [assets/i18n/en.json] and [bn.json] before [runApp].
abstract final class LocalizationLoader {
  static Map<String, Map<String, String>>? _byLocale;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    StartupTrace.mark('L10N_LOAD_START');
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
    StartupTrace.mark('L10N_LOAD_DONE', detail: 'keys=${en.length}/${bn.length}');
  }

  static Future<Map<String, String>> _loadJson(String asset) async {
    try {
      final raw = await rootBundle.loadString(asset);
      if (raw.length > 48000) {
        return compute(_parseLocalizationAsset, _LocalizationParseInput(asset, raw));
      }
      return _parseLocalizationAsset(_LocalizationParseInput(asset, raw));
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

class _LocalizationParseInput {
  const _LocalizationParseInput(this.asset, this.raw);

  final String asset;
  final String raw;
}

Map<String, String> _parseLocalizationAsset(_LocalizationParseInput input) {
  final decoded = jsonDecode(input.raw);
  final map = SafeParse.map(decoded, context: input.asset);
  return map.map((key, value) {
    if (key.startsWith('@')) return MapEntry(key, '');
    if (value is! String) return MapEntry(key, '');
    return MapEntry(key, value);
  })..removeWhere((key, value) => key.startsWith('@') || value.isEmpty);
}
