/// Aligns with backend [MobileUploadPurpose].
enum UploadPurpose {
  customerProfilePhoto('CUSTOMER_PROFILE_PHOTO'),
  customerCoverImage('CUSTOMER_COVER_IMAGE'),
  animalPhoto('ANIMAL_PHOTO'),
  animalWeightScalePhoto('ANIMAL_WEIGHT_SCALE_PHOTO'),
  animalWeightAiImage('ANIMAL_WEIGHT_AI_IMAGE'),
  animalWeightAiVideo('ANIMAL_WEIGHT_AI_VIDEO'),
  supportAttachment('SUPPORT_ATTACHMENT');

  const UploadPurpose(this.apiValue);

  final String apiValue;
}
