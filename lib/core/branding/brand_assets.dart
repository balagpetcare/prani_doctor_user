/// Single source of truth for bundled brand and marketing assets.
abstract final class BrandAssets {
  BrandAssets._();

  // Brand
  static const appIcon = 'assets/brand/app_icons/prani_doctor_app_icon.png';

  /// Native splash uses solid white (see flutter_native_splash in pubspec).
  static const primaryLogoPath =
      'assets/brand/logos/prani_doctor_primary_logo.png';
  static const primaryLogo =
      'assets/brand/logos/prani_doctor_alt_logo_earth_tone.png';

  /// Full-bleed Flutter splash (matches pranidoctor_mobile).
  static const splashFarm =
      'assets/brand/illustrations/splash_farm_livestock.png';

  /// Legacy alias used by older splash code paths.
  static const splashIllustration = splashFarm;

  /// Bangladesh-context onboarding slides (matches pranidoctor_mobile).
  static const onboardingSlides = <OnboardingSlideAsset>[
    OnboardingSlideAsset(
      image: 'assets/images/onboarding/onboarding_01_service_overview_bd.png',
      titleBn: 'প্রাণী ডাক্তার',
      bodyBn:
          'খামারের প্রাণীর স্বাস্থ্যসেবা এখন হাতের মুঠোয়। ডাক্তার পরামর্শ, ওষুধ ও পণ্য, টিকাদান স্মরণী, স্বাস্থ্য রেকর্ড ও জরুরি সহায়তা—সব একসাথে।',
      semanticLabel: 'প্রাণী ডাক্তার সেবার পরিচিতি',
    ),
    OnboardingSlideAsset(
      image:
          'assets/images/onboarding/onboarding_02_farmer_vet_consultation_bd.png',
      titleBn: 'খামারভিত্তিক সেবা',
      bodyBn:
          'কৃষক, ডাক্তার ও মাঠপর্যায়ের সেবাকে এক জায়গায় যুক্ত করা হয়েছে, যাতে গরু, ছাগল, ভেড়া, হাঁস-মুরগি ও অন্যান্য খামারের প্রাণীর জন্য দ্রুত সহায়তা পাওয়া যায়।',
      semanticLabel: 'খামারে ডাক্তার পরামর্শ',
    ),
    OnboardingSlideAsset(
      image: 'assets/images/onboarding/onboarding_03_ai_field_support_bd.png',
      titleBn: 'AI টেকনিশিয়ান ও ভেট সাপোর্ট',
      bodyBn:
          'কৃত্রিম প্রজনন, মাঠপর্যায়ের সেবা, স্বাস্থ্য পর্যবেক্ষণ ও প্রযুক্তিনির্ভর সহায়তার মাধ্যমে খামারের প্রাণীর যত্ন হবে আরও সহজ ও কার্যকর।',
      semanticLabel: 'AI টেকনিশিয়ান ও মাঠপর্যায়ের সহায়তা',
    ),
    OnboardingSlideAsset(
      image: 'assets/images/onboarding/onboarding_04_get_started_bd.png',
      titleBn: 'শুরু করুন',
      bodyBn:
          'আপনার লোকেশন দিন, প্রয়োজনীয় সেবা নির্বাচন করুন এবং নিরাপদ OTP লগইনের মাধ্যমে সহজেই সেবা গ্রহণ শুরু করুন।',
      semanticLabel: 'শুরু করার ধাপ',
    ),
  ];

  // Home
  static const homeHero = 'assets/brand/illustrations/farm_service_banner.png';
  static const homeEmergency =
      'assets/brand/illustrations/doctor_visit_cow_farm.png';
  static const homePromoVaccination =
      'assets/images/home/promo_vaccination.png';
  static const homeEmptyDoctors = 'assets/images/home/empty_nearby_doctors.png';

  static const splashTitleBn = 'প্রাণী ডাক্তার';

  /// Minimum branded splash display (matches pranidoctor_mobile).
  static const splashMinDisplayMs = 700;

  /// Decode pixel budgets for full-bleed splash.
  static const splashDecodeMaxWidthPx = 1080;
  static const splashDecodeMaxHeightPx = 1920;

  /// Every bundled asset path referenced by the app (for validation/tests).
  static List<String> get allReferencedPaths => [
    appIcon,
    primaryLogoPath,
    primaryLogo,
    splashFarm,
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
    required this.bodyBn,
    required this.semanticLabel,
  });

  final String image;
  final String titleBn;
  final String bodyBn;
  final String semanticLabel;

  /// Backward-compatible alias.
  String get subtitleBn => bodyBn;
}
