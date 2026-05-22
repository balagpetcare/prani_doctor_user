import 'treatment_dto.dart';

abstract final class TreatmentValidation {
  TreatmentValidation._();

  static String? validateTitle(String? value, {required String message}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? validateAnimal(String? animalId, {required String message}) {
    if (animalId == null || animalId.isEmpty) return message;
    return null;
  }

  static String? validateMedicine(MedicineItem item, {required String message}) {
    if (item.name.trim().isEmpty || item.dosage.trim().isEmpty) return message;
    return null;
  }

  static String? validateStartDate(DateTime date, {required String message}) {
    if (date.isBefore(DateTime(2020))) return message;
    return null;
  }
}
