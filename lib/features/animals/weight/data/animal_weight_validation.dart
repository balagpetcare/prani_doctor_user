import 'animal_weight_capture_draft.dart';
import 'animal_weight_method.dart';

class AnimalWeightValidation {
  AnimalWeightValidation._();

  static String? validateCm(String? raw, {String message = 'Invalid measurement'}) {
    if (raw == null || raw.trim().isEmpty) return message;
    final v = double.tryParse(raw.trim());
    if (v == null || v <= 0 || v > 300) return message;
    return null;
  }

  static String? validateWeightKg(String? raw, {String message = 'Invalid weight'}) {
    if (raw == null || raw.trim().isEmpty) return message;
    final v = double.tryParse(raw.trim());
    if (v == null || v <= 0 || v > 99999) return message;
    return null;
  }

  static String? validateCapture(
    AnimalWeightCaptureDraft draft, {
    required String animalType,
    required String methodRequiredMessage,
    required String tapeHeartMessage,
    required String tapeLengthMessage,
    required String weightMessage,
    required String aiMediaMessage,
    required String aiDisclaimerMessage,
    required String tapeUnsupportedMessage,
  }) {
    final method = draft.method;
    if (method == null) return methodRequiredMessage;

    switch (method) {
      case AnimalWeightMethod.tape:
        if (!AnimalWeightMethodX.supportsTape(animalType)) {
          return tapeUnsupportedMessage;
        }
        return validateCm(draft.heartGirthCm?.toString(), message: tapeHeartMessage) ??
            validateCm(draft.bodyLengthCm?.toString(), message: tapeLengthMessage);
      case AnimalWeightMethod.scale:
        return validateWeightKg(draft.scaleWeightKg?.toString(), message: weightMessage);
      case AnimalWeightMethod.aiCamera:
        if (!draft.aiDisclaimerAck) return aiDisclaimerMessage;
        if (draft.aiUploadIds.isEmpty && draft.aiLocalPaths.isEmpty) {
          return aiMediaMessage;
        }
        return null;
    }
  }
}
