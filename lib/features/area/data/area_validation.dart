/// Client-side location hierarchy validation.
abstract final class AreaValidation {
  AreaValidation._();

  /// Division → district → upazila → union are required for profile address.
  static String? validateRequiredHierarchy({
    required String? divisionId,
    required String? districtId,
    required String? upazilaId,
    required String? unionId,
    required String message,
  }) {
    if (divisionId == null || divisionId.trim().isEmpty) return message;
    if (districtId == null || districtId.trim().isEmpty) return message;
    if (upazilaId == null || upazilaId.trim().isEmpty) return message;
    if (unionId == null || unionId.trim().isEmpty) return message;
    return null;
  }

  /// Village is optional; union satisfies location when village is omitted.
  static bool hasUnionOrVillage({
    String? unionId,
    String? villageId,
    String? villageName,
  }) {
    if (unionId != null && unionId.trim().isNotEmpty) return true;
    if (villageId != null && villageId.trim().isNotEmpty) return true;
    if (villageName != null && villageName.trim().isNotEmpty) return true;
    return false;
  }

  @Deprecated('Village is optional — use validateRequiredHierarchy')
  static String? validateVillageSelected(
    String? villageId, {
    required String message,
  }) {
    return null;
  }

  static bool isValidParentChain({
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
    String? villageId,
  }) {
    if (villageId != null && villageId.isNotEmpty) {
      return unionId != null &&
          unionId.isNotEmpty &&
          upazilaId != null &&
          upazilaId.isNotEmpty &&
          districtId != null &&
          districtId.isNotEmpty &&
          divisionId != null &&
          divisionId.isNotEmpty;
    }
    if (unionId != null && unionId.isNotEmpty) {
      return upazilaId != null &&
          upazilaId.isNotEmpty &&
          districtId != null &&
          districtId.isNotEmpty &&
          divisionId != null &&
          divisionId.isNotEmpty;
    }
    if (upazilaId != null && upazilaId.isNotEmpty) {
      return districtId != null &&
          districtId.isNotEmpty &&
          divisionId != null &&
          divisionId.isNotEmpty;
    }
    if (districtId != null && districtId.isNotEmpty) {
      return divisionId != null && divisionId.isNotEmpty;
    }
    return true;
  }
}
