/// Approved fallback copy when CMS is unavailable — docs/launch/ai-compliance-plan.md §D
class AiComplianceFallbackCopy {
  const AiComplianceFallbackCopy._();

  static const bannerEn =
      'Prani Doctor AI provides general livestock guidance. It cannot see or examine your animal, run tests, or verify what you report. Answers may be wrong, incomplete, or outdated.';

  static const bannerBn =
      'প্রাণী ডাক্তর AI সাধারণ পশুপালন নির্দেশিকা দেয়। এটি আপনার পশুকে দেখতে বা পরীক্ষা করতে পারে না। উত্তর ভুল, অসম্পূর্ণ বা পুরোনো হতে পারে।';

  static const inlineDisclaimerEn =
      'This is educational guidance only — not a veterinary diagnosis, prescription, or treatment plan.';

  static const inlineDisclaimerBn =
      'এটি শুধু শিক্ষামূলক নির্দেশিকা — প্রাণী চিকিৎসা নির্ণয়, প্রেসক্রিপশন বা চিকিৎসা পরিকল্পনা নয়।';

  static const emergencyEn =
      'This may be an emergency. Prani Doctor does not dispatch emergency services. Contact a veterinarian or emergency clinic immediately.';

  static const emergencyBn =
      'এটি জরুরি হতে পারে। প্রাণী ডাক্তার জরুরি সেবা পাঠায় না। অবিলম্বে প্রাণী চিকিৎসকের সহায়তা নিন।';

  static String bannerForLocale(String locale) =>
      locale.toLowerCase().startsWith('bn') ? bannerBn : bannerEn;

  static String inlineDisclaimerForLocale(String locale) =>
      locale.toLowerCase().startsWith('bn') ? inlineDisclaimerBn : inlineDisclaimerEn;

  static String emergencyForLocale(String locale) =>
      locale.toLowerCase().startsWith('bn') ? emergencyBn : emergencyEn;
}
