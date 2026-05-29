import 'livestock_dto.dart';

class LivestockValidation {
  LivestockValidation._();

  static String? validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'livestockNameRequired';
    if (v.length > 120) return 'livestockNameTooLong';
    return null;
  }

  static String? validateSpecies(String? value) {
    if (value == null || value.isEmpty) return 'livestockSpeciesRequired';
    return null;
  }

  static String? validateCustomSpecies(String? species, String? custom) {
    if (species == 'CUSTOM' && (custom?.trim().isEmpty ?? true)) {
      return 'livestockCustomSpeciesRequired';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'livestockWeightInvalid';
    return null;
  }

  static bool isValid(LivestockInput input) {
    return validateName(input.name) == null &&
        validateSpecies(input.species) == null &&
        validateCustomSpecies(input.species, input.customSpeciesLabel) == null;
  }
}
