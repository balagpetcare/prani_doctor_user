abstract final class VaccineValidation {
  VaccineValidation._();

  static String? validateName(String? value, {required String message}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? validateAnimal(String? animalId, {required String message}) {
    if (animalId == null || animalId.isEmpty) return message;
    return null;
  }

  static String? validateScheduledDate(
    DateTime date, {
    required String message,
  }) {
    if (date.isBefore(DateTime(2020))) return message;
    return null;
  }
}
