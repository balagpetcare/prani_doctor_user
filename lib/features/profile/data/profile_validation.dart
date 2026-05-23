/// Client-side profile field validation (mirrors backend limits).
abstract final class ProfileValidation {
  ProfileValidation._();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? validateName(
    String? value, {
    required String requiredMessage,
    required String tooLongMessage,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return requiredMessage;
    if (trimmed.length > 120) return tooLongMessage;
    return null;
  }

  static String? validateEmail(
    String? value, {
    required String invalidMessage,
    required String tooLongMessage,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 200) return tooLongMessage;
    if (!_emailPattern.hasMatch(trimmed)) return invalidMessage;
    return null;
  }

  static String? validateLine1(
    String? value, {
    required String tooLongMessage,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 500) return tooLongMessage;
    return null;
  }

  static String? validatePostalCode(
    String? value, {
    required String tooLongMessage,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 20) return tooLongMessage;
    return null;
  }

  static bool isSupportedLocale(String locale) {
    return locale == 'bn-BD' || locale == 'en-US';
  }
}
