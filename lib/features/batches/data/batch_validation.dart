abstract final class BatchValidation {
  BatchValidation._();

  static String? validateName(String? name, {required String message}) {
    if (name == null || name.trim().isEmpty) return message;
    if (name.trim().length < 2) return message;
    return null;
  }

  static String? validateMove({
    required String? fromBatchId,
    required String? toBatchId,
    required List<String> animalIds,
    required String message,
  }) {
    if (fromBatchId == null || toBatchId == null || fromBatchId == toBatchId) {
      return message;
    }
    if (animalIds.isEmpty) return message;
    return null;
  }

  static String? validateMerge({
    required String? sourceId,
    required String? targetId,
    required String message,
  }) {
    if (sourceId == null || targetId == null || sourceId == targetId) {
      return message;
    }
    return null;
  }
}
