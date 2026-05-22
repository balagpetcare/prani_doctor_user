abstract final class AiValidation {
  AiValidation._();

  static const maxMessageLength = 2000;
  static const minMessageLength = 1;
  static const minSymptomLength = 2;

  static String? validateMessage(String message, {required String emptyMessage, required String tooLong}) {
    final trimmed = message.trim();
    if (trimmed.length < minMessageLength) return emptyMessage;
    if (trimmed.length > maxMessageLength) return tooLong;
    return null;
  }

  static String? validateSymptoms(List<String> symptoms, {required String emptyMessage}) {
    final cleaned = symptoms.map((s) => s.trim()).where((s) => s.length >= minSymptomLength).toList();
    if (cleaned.isEmpty) return emptyMessage;
    return null;
  }
}
