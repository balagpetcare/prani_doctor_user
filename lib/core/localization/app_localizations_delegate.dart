import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_localizations_base.dart';
import 'generated/app_localizations_impl.dart';

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'bn':
    default:
      return AppLocalizationsBn();
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

const appLocalizationsDelegate = AppLocalizationsDelegate();
