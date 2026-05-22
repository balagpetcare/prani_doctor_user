import 'support_dto.dart';

abstract final class SupportValidation {
  SupportValidation._();

  static const maxAttachmentBytes = 8 * 1024 * 1024;
  static const maxAttachments = 5;

  static const allowedMimePrefixes = ['image/', 'application/pdf'];
  static const allowedMimeExact = [
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
  ];

  static String? validateTicket({
    required SupportTicketCategory category,
    required String subject,
    required String description,
    required String subjectRequired,
    required String descriptionRequired,
    required String subjectTooShort,
    required String descriptionTooShort,
  }) {
    if (subject.trim().length < 3) return subjectTooShort;
    if (description.trim().length < 10) return descriptionTooShort;
    return null;
  }

  static String? validateReply(String body, String requiredMessage) {
    if (body.trim().isEmpty) return requiredMessage;
    return null;
  }

  static String? validateFile({
    required String mimeType,
    required int sizeBytes,
    required String unsupportedType,
    required String fileTooLarge,
  }) {
    if (!_isAllowedMime(mimeType)) return unsupportedType;
    if (sizeBytes > maxAttachmentBytes) return fileTooLarge;
    return null;
  }

  static bool _isAllowedMime(String mimeType) {
    final lower = mimeType.toLowerCase();
    if (allowedMimeExact.contains(lower)) return true;
    return allowedMimePrefixes.any(lower.startsWith);
  }
}
