abstract final class FinanceValidation {
  FinanceValidation._();

  static String? validateAmount(String? value, {required String message}) {
    if (value == null || value.trim().isEmpty) return message;
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0 || n > 99999999) return message;
    return null;
  }

  static String? validateDate(DateTime date, {required String message}) {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
    if (date.isAfter(end)) return message;
    return null;
  }
}
