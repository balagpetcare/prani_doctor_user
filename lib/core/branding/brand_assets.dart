/// Single source of truth for bundled brand and marketing assets.
abstract final class BrandAssets {
  BrandAssets._();

  // Brand
  static const appIcon = 'assets/brand/app_icons/prani_doctor_app_icon.png';
  /// Native splash + launcher still use [primaryLogoPath]; UI uses alt mark until final export.
  static const primaryLogoPath =
      'assets/brand/logos/prani_doctor_primary_logo.png';
  static const primaryLogo =
      'assets/brand/logos/prani_doctor_alt_logo_earth_tone.png';
  static const splashIllustration =
      'assets/brand/illustrations/onboarding_farmer_livestock.png';

  // Onboarding
  static const onboardingSlides = <OnboardingSlideAsset>[
    OnboardingSlideAsset(
      image: 'assets/brand/illustrations/farm_service_banner.png',
      titleBn: 'প্রাণী ডাক্তার',
      subtitleBn: 'খামারের প্রাণীর স্বাস্থ্যসেবা এখন হাতের মুঠোয়',
    ),
    OnboardingSlideAsset(
      image: 'assets/brand/illustrations/onboarding_farmer_livestock.png',
      titleBn: 'খামারভিত্তিক সেবা',
      subtitleBn: 'কৃষক, ডাক্তার ও মাঠপর্যায়ের সেবাকে এক জায়গায় যুক্ত করা হয়েছে',
    ),
    OnboardingSlideAsset(
      image: 'assets/brand/illustrations/ai_technician_cattle_service.png',
      titleBn: 'AI টেকনিশিয়ান ও ভেট সাপোর্ট',
      subtitleBn:
          'কৃত্রিম প্রজনন, মাঠপর্যায়ের সহায়তা, স্বাস্থ্য পর্যবেক্ষণ ও প্রযুক্তিনির্ভর সেবা',
    ),
    OnboardingSlideAsset(
      image: 'assets/brand/illustrations/service_tracking_livestock_app.png',
      titleBn: 'শুরু করুন',
      subtitleBn: 'লোকেশন দিন, সেবা নির্বাচন করুন, নিরাপদ OTP দিয়ে এগিয়ে যান',
    ),
  ];

  // Home
  static const homeHero = 'assets/brand/illustrations/farm_service_banner.png';
  static const homeEmergency =
      'assets/brand/illustrations/doctor_visit_cow_farm.png';  static const homePromoVaccination = 'assets/images/home/promo_vaccination.png';
  static const homeEmptyDoctors = 'assets/images/home/empty_nearby_doctors.png';

  static const splashTitleBn = 'প্রাণী ডাক্তার';

  /// Every bundled asset path referenced by the app (for validation/tests).
  static List<String> get allReferencedPaths => [
        appIcon,
        primaryLogoPath,
        primaryLogo,
        splashIllustration,
        ...onboardingSlides.map((s) => s.image),
        homeHero,
        homeEmergency,
        homePromoVaccination,
        homeEmptyDoctors,
      ];
}
class OnboardingSlideAsset {
  const OnboardingSlideAsset({
    required this.image,
    required this.titleBn,
    required this.subtitleBn,
  });

  final String image;
  final String titleBn;
  final String subtitleBn;
}
