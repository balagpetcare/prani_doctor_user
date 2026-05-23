/// Aligns with backend [MobileUploadPurpose].
enum UploadPurpose {
  customerProfilePhoto('CUSTOMER_PROFILE_PHOTO'),
  customerCoverImage('CUSTOMER_COVER_IMAGE'),
  animalPhoto('ANIMAL_PHOTO'),
  supportAttachment('SUPPORT_ATTACHMENT');

  const UploadPurpose(this.apiValue);

  final String apiValue;
}
