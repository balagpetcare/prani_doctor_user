/// Client-side profile field validation (mirrors backend limits).
abstract final class ProfileValidation {
  ProfileValidation._();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? validateName(String? value, {required String requiredMessage}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return requiredMessage;
    if (trimmed.length > 120) return 'Name must be 120 characters or fewer';
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 200) return 'Email must be 200 characters or fewer';
    if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? validateLine1(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 500) return 'Address line must be 500 characters or fewer';
    return null;
  }

  static String? validatePostalCode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 20) return 'Postal code must be 20 characters or fewer';
    return null;
  }

  static bool isSupportedLocale(String locale) {
    return locale == 'bn-BD' || locale == 'en-US';
  }
}
