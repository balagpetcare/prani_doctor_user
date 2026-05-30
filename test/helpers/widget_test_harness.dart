import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

/// Stable English locale for widget tests (avoids OS locale drift).
const testLocale = Locale('en');

/// [MaterialApp] configured for widget/golden tests.
Widget testMaterialApp({
  required Widget home,
  ThemeData? theme,
  Size? viewportSize,
}) {
  Widget child = MaterialApp(
    theme: theme,
    locale: testLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
  if (viewportSize != null) {
    child = MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: child,
    );
  }
  return child;
}
