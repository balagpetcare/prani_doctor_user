import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_date_format.dart';
import 'language_controller.dart';
import 'locale_storage.dart';
import 'localization_extensions.dart';
import 'translation_keys.dart';

export 'app_date_format.dart';
export 'localization_extensions.dart';
export 'translation_keys.dart';

// ── Language utilities ───────────────────────────────────────────────────────

/// Returns the current language code (`'bn'` or `'en'`) by reading Hive
/// synchronously. Useful in non-widget code that doesn't have a [BuildContext].
String get currentLanguageCode => LocaleStorage.readSync();

/// Provider that exposes the current language code as a plain [String].
///
/// Prefer this over `ref.watch(languageControllerProvider).languageCode`
/// when you only need the code string (avoids re-creating `Locale`).
final languageCodeProvider = Provider<String>((ref) {
  return ref.watch(languageControllerProvider).languageCode;
});

// ── Context extensions ───────────────────────────────────────────────────────

/// Convenience extensions on [BuildContext] for localization.
extension LocalizationHelpers on BuildContext {
  /// Returns a locale-aware [AppDateFormat] for the current context.
  ///
  /// ```dart
  /// Text(context.dateFormat.date(record.createdAt))
  /// ```
  AppDateFormatFromContext get dateFormat => AppDateFormatFromContext(this);

  /// `true` when the active locale is Bengali.
  bool get isBengali => tr.localeCode == 'bn';

  /// `true` when the active locale is English.
  bool get isEnglish => tr.localeCode == 'en';
}

/// Lazy access to [AppDateFormat] from a [BuildContext]. Created on-demand
/// so callers only pay the cost when they call a date method.
class AppDateFormatFromContext {
  const AppDateFormatFromContext(this._ctx);
  final BuildContext _ctx;

  String date(DateTime dt) => AppDateFormat.fromContext(_ctx).date(dt);
  String dateTime(DateTime dt) => AppDateFormat.fromContext(_ctx).dateTime(dt);
  String time(DateTime dt) => AppDateFormat.fromContext(_ctx).time(dt);
  String timeShort(DateTime dt) => AppDateFormat.fromContext(_ctx).timeShort(dt);
}

// ── Fallback-safe translation helper ────────────────────────────────────────

/// Wraps a raw `l10n.translate(key, args)` call with a developer-visible
/// warning when the key is not found (value equals the key itself).
///
/// **Only use in debug builds.** In release builds this is a no-op wrapper.
///
/// ```dart
/// final text = safeTranslate(context, TranslationKeys.inventoryTitle);
/// ```
String safeTranslate(
  BuildContext context,
  String key, [
  Map<String, Object?>? args,
]) {
  final result = context.tr.translate(key, args);
  assert(
    result != key,
    'Translation key "$key" is missing from the active locale '
    '(${context.tr.localeCode}). Add it to en.json / bn.json and '
    'translation_keys.dart.',
  );
  return result;
}

// ── Plural helper ────────────────────────────────────────────────────────────

/// Simple English/Bengali plural helper for numeric labels.
///
/// Selects [singular] when [count] == 1, otherwise [plural].
/// For Bengali, [plural] is usually the same as [singular] (no grammatical
/// plural suffix), so callers can pass identical values.
///
/// ```dart
/// pluralLabel(count, singular: l10n.animal, plural: l10n.animals)
/// ```
String pluralLabel(
  int count, {
  required String singular,
  required String plural,
}) {
  return count == 1 ? singular : plural;
}

// ── Named constant for the TranslationKeys class ─────────────────────────────

/// Convenience re-export so callers can write `TKey.inventoryTitle` instead of
/// `TranslationKeys.inventoryTitle` with a shorter import.
typedef TKey = TranslationKeys;
