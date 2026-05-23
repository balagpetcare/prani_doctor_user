class AnimalValidation {
  AnimalValidation._();

  static String? validateNameOrTag({
    String? name,
    String? tag,
    required String message,
  }) {
    final nameOk = name != null && name.trim().isNotEmpty;
    final tagOk = tag != null && tag.trim().isNotEmpty;
    if (!nameOk && !tagOk) return message;
    return null;
  }

  static String? validateAnimalType(String? type, {required String message}) {
    if (type == null || type.trim().isEmpty) return message;
    return null;
  }

  static String? validateWeight(
    String? raw, {
    String invalidMessage = 'Invalid weight',
  }) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = double.tryParse(raw.trim());
    if (value == null || value <= 0) return invalidMessage;
    return null;
  }

  static String? validateAgeYears(
    String? raw, {
    String invalidMessage = 'Invalid age',
  }) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = int.tryParse(raw.trim());
    if (value == null || value < 0 || value > 80) return invalidMessage;
    return null;
  }
}
