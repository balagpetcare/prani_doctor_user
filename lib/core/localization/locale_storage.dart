import 'package:hive_flutter/hive_flutter.dart';

import '../cache/hive_bootstrap.dart';

/// Persists UI language (`bn` | `en`) locally for instant cold-start locale.
abstract final class LocaleStorage {
  static const _key = 'app_locale';
  static const defaultLanguageCode = 'bn';

  static Box<dynamic> get _box => openCacheBox();

  static String readSync() {
    final value = _box.get(_key);
    if (value is String && (value == 'bn' || value == 'en')) {
      return value;
    }
    return defaultLanguageCode;
  }

  static Future<void> write(String languageCode) async {
    final normalized = languageCode == 'en' ? 'en' : 'bn';
    await _box.put(_key, normalized);
  }

  /// API profile/settings tags.
  static String toApiTag(String languageCode) =>
      languageCode == 'en' ? 'en-US' : 'bn-BD';

  static String fromApiTag(String? tag) {
    if (tag == 'en-US') return 'en';
    return defaultLanguageCode;
  }
}
