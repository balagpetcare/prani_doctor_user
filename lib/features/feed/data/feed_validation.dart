import 'feed_dto.dart';

abstract final class FeedValidation {
  FeedValidation._();

  static String? validateAmount(String? value, {required String message}) {
    if (value == null || value.trim().isEmpty) return message;
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0 || n > 999999) return message;
    return null;
  }

  static String? validateCost(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim());
    if (n == null || n < 0 || n > 99999999) return 'Invalid cost';
    return null;
  }

  static String? validateTarget({
    required FeedTarget target,
    String? animalId,
    String? batchId,
    required String message,
  }) {
    if (target == FeedTarget.animal && (animalId == null || animalId.isEmpty)) return message;
    if (target == FeedTarget.group && (batchId == null || batchId.isEmpty)) return message;
    return null;
  }

  static String? validateDate(DateTime date, {required String message}) {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
    if (date.isAfter(end)) return message;
    return null;
  }
}
