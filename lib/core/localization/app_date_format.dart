import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'language_controller.dart';
import 'localization_extensions.dart';

/// Locale-aware date / time formatters that respect the active app language.
///
/// **Usage — in a `ConsumerWidget`:**
/// ```dart
/// final fmt = ref.watch(appDateFormatProvider);
/// Text(fmt.date(record.createdAt))
/// ```
///
/// **Usage — from a `BuildContext`:**
/// ```dart
/// Text(AppDateFormat.fromContext(context).dateTime(event.timestamp))
/// ```
///
/// Supports `bn` (Bengali numerals/months) and `en` (Gregorian) — matching
/// the two locales declared in `AppLocalizations.supportedLocales`.
///
/// `initializeDateFormatting` for both locales is called in `bootstrap.dart`
/// before `runApp`, so no additional setup is required.
abstract final class AppDateFormat {
  AppDateFormat._();

  // ── Factory constructors ─────────────────────────────────────────────

  /// Creates a formatter set for [languageCode] (`'bn'` or `'en'`).
  static AppDateFormatHelper forCode(String languageCode) =>
      AppDateFormatHelper(languageCode == 'en' ? 'en' : 'bn');

  /// Creates a formatter set from a [BuildContext] by reading the active
  /// [AppLocalizations] locale. Safe to call in `build()`.
  static AppDateFormatHelper fromContext(BuildContext context) =>
      AppDateFormatHelper(context.tr.localeCode);
}

/// Concrete date/time formatter set for a single locale.
///
/// Returned by [AppDateFormat.forCode] and [AppDateFormat.fromContext].
/// Also exposed directly by [appDateFormatProvider].
class AppDateFormatHelper {
  const AppDateFormatHelper(this._code);

  final String _code;

  // ── High-level helpers ───────────────────────────────────────────────

  /// `"23 May 2026"` / `"২৩ মে ২০২৬"`.
  String date(DateTime dt) => intl.DateFormat.yMMMd(_code).format(dt.toLocal());

  /// `"23 May 2026, 2:30 PM"` / `"২৩ মে ২০২৬, দুপুর ২:৩০"`.
  String dateTime(DateTime dt) =>
      intl.DateFormat.yMMMd(_code).add_jm().format(dt.toLocal());

  /// `"2:30:00 PM"` / `"দুপুর ২:৩০:০০"`.
  String time(DateTime dt) => intl.DateFormat.jms(_code).format(dt.toLocal());

  /// `"2:30 PM"` / `"দুপুর ২:৩০"`.
  String timeShort(DateTime dt) => intl.DateFormat.jm(_code).format(dt.toLocal());

  /// ISO date `"2026-05-23"`.
  String isoDate(DateTime dt) => intl.DateFormat('yyyy-MM-dd').format(dt.toLocal());

  // ── Raw [intl.DateFormat] access ─────────────────────────────────────

  intl.DateFormat get dateFormat => intl.DateFormat.yMMMd(_code);
  intl.DateFormat get dateTimeFormat => intl.DateFormat.yMMMd(_code).add_jm();
  intl.DateFormat get timeFormat => intl.DateFormat.jms(_code);
}

/// Riverpod provider that returns an [AppDateFormatHelper] for the current
/// app locale. Rebuilds widgets only when the language changes.
///
/// ```dart
/// final fmt = ref.watch(appDateFormatProvider);
/// Text(fmt.date(record.createdAt))
/// ```
final appDateFormatProvider = Provider<AppDateFormatHelper>((ref) {
  final languageCode = ref.watch(languageControllerProvider).languageCode;
  return AppDateFormatHelper(languageCode == 'en' ? 'en' : 'bn');
});
