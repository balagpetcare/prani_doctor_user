/// Maps profile locale tags to area engine locale query param.
abstract final class AreaLocale {
  AreaLocale._();

  static const defaultLocale = 'bn';

  static String fromProfileTag(String? profileLocale) {
    if (profileLocale != null && profileLocale.toLowerCase().startsWith('en')) {
      return 'en';
    }
    return defaultLocale;
  }
}
