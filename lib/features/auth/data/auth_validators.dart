/// Client-side validation for auth forms (matches backend constraints).
abstract final class AuthValidators {
  AuthValidators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _otpPattern = RegExp(r'^\d{4,6}$');

  static String? validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// BD mobile: 11-digit local (`01…`) or E.164 (`8801…`).
  static String? validatePhone(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final requiredError = validateRequired(value, requiredMessage);
    if (requiredError != null) return requiredError;

    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880') && digits.length == 13) return null;
    if (digits.startsWith('01') && digits.length == 11) return null;
    return invalidMessage;
  }

  static String? validatePassword(
    String? value, {
    required String requiredMessage,
    required String weakMessage,
  }) {
    final requiredError = validateRequired(value, requiredMessage);
    if (requiredError != null) return requiredError;
    if (value!.length < 6) return weakMessage;
    return null;
  }

  static String? validateOtp(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final requiredError = validateRequired(value, requiredMessage);
    if (requiredError != null) return requiredError;
    if (!_otpPattern.hasMatch(value!.trim())) return invalidMessage;
    return null;
  }

  static String? validateEmailOptional(
    String? value, {
    required String invalidMessage,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailPattern.hasMatch(value.trim())) return invalidMessage;
    return null;
  }
}
