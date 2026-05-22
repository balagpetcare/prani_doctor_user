import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_validation.dart';

class ProfileLocaleController extends StateNotifier<Locale?> {
  ProfileLocaleController() : super(null);

  void syncFromProfile(String localeTag) {
    if (!ProfileValidation.isSupportedLocale(localeTag)) return;
    state = _toFlutterLocale(localeTag);
  }

  Locale _toFlutterLocale(String localeTag) {
    return localeTag == 'en-US' ? const Locale('en') : const Locale('bn');
  }
}
