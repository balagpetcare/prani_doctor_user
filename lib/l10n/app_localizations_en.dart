// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PraniDoctor';

  @override
  String get navHome => 'Home';

  @override
  String get navServices => 'Services';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navSettings => 'Settings';

  @override
  String get drawerTitle => 'Menu';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginDevContinue => 'Continue (development)';
}
