import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/data/profile_validation.dart';
import 'locale_storage.dart';

/// Active app UI locale. Initialized synchronously from [LocaleStorage].
class LanguageController extends StateNotifier<Locale> {
  LanguageController() : super(_initialLocale);

  static final _initialLocale = Locale(LocaleStorage.readSync());

  /// Updates local storage and in-memory locale (live switch, no restart).
  Future<void> setLanguageCode(String languageCode) async {
    final code = languageCode == 'en' ? 'en' : 'bn';
    if (state.languageCode == code) return;
    await LocaleStorage.write(code);
    state = Locale(code);
  }

  void syncFromApiTag(String? localeTag) {
    if (localeTag == null || !ProfileValidation.isSupportedLocale(localeTag)) {
      return;
    }
    final code = LocaleStorage.fromApiTag(localeTag);
    if (state.languageCode == code) return;
    state = Locale(code);
    unawaited(LocaleStorage.write(code));
  }

  String get apiTag => LocaleStorage.toApiTag(state.languageCode);
}

final languageControllerProvider =
    StateNotifierProvider<LanguageController, Locale>((ref) {
  return LanguageController();
});

/// Bridge for legacy name.
final profileLocaleControllerProvider = languageControllerProvider;
