class FarmValidation {
  FarmValidation._();

  static String? validateName(String value, {required String requiredMessage}) {
    if (value.trim().isEmpty) return requiredMessage;
    if (value.trim().length < 2) return requiredMessage;
    return null;
  }

  static String? validateVillage(String? villageId, {required String requiredMessage}) {
    if (villageId == null || villageId.trim().isEmpty) return requiredMessage;
    return null;
  }
}
