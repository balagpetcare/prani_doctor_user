class AnimalValidation {
  AnimalValidation._();

  static String? validateNameOrTag({String? name, String? tag, required String message}) {
    final nameOk = name != null && name.trim().length >= 1;
    final tagOk = tag != null && tag.trim().length >= 1;
    if (!nameOk && !tagOk) return message;
    return null;
  }

  static String? validateAnimalType(String? type, {required String message}) {
    if (type == null || type.trim().isEmpty) return message;
    return null;
  }

  static String? validateWeight(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = double.tryParse(raw.trim());
    if (value == null || value <= 0) return 'Invalid weight';
    return null;
  }

  static String? validateAgeYears(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = int.tryParse(raw.trim());
    if (value == null || value < 0 || value > 80) return 'Invalid age';
    return null;
  }
}
