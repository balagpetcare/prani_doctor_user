/// Centralized asset path references.
///
/// Replaces scattered magic strings for bundled assets. Keep these aligned with
/// the `flutter > assets:` section of `pubspec.yaml`.
abstract final class AppAssets {
  AppAssets._();

  // Base directories (must match pubspec asset declarations).
  static const String i18nDir = 'assets/i18n/';
  static const String brandIconsDir = 'assets/brand/app_icons/';
  static const String brandLogosDir = 'assets/brand/logos/';
  static const String brandIllustrationsDir = 'assets/brand/illustrations/';
  static const String onboardingImagesDir = 'assets/images/onboarding/';
  static const String homeImagesDir = 'assets/images/home/';
  static const String seedsDir = 'assets/seeds/';

  // Known seed / data files.
  static const String feedCatalogSeed = '${seedsDir}feed_catalog.json';

  // Localization JSON (generated from ARB by tool/i18n/build_localization.dart).
  static String i18nFile(String languageCode) => '$i18nDir$languageCode.json';
}
