/// Client-side media ownership contract (aligns with backend upload purpose).
enum MediaOwnerType {
  user,
  animal,
}

enum MediaPurpose {
  profile,
  cover,
  animal,
  support,
}

extension MediaPurposeUpload on MediaPurpose {
  /// Maps to [UploadPurpose.apiValue] where applicable.
  String? get uploadPurposeApiValue {
    switch (this) {
      case MediaPurpose.profile:
        return 'CUSTOMER_PROFILE_PHOTO';
      case MediaPurpose.cover:
        return 'CUSTOMER_COVER_IMAGE';
      case MediaPurpose.animal:
        return 'ANIMAL_PHOTO';
      case MediaPurpose.support:
        return 'SUPPORT_ATTACHMENT';
    }
  }
}
