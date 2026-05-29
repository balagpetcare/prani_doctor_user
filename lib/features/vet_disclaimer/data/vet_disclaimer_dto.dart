class VetDisclaimerLocaleText {
  const VetDisclaimerLocaleText({required this.en, required this.bn});

  factory VetDisclaimerLocaleText.fromJson(Map<String, dynamic>? json) {
    return VetDisclaimerLocaleText(
      en: json?['en'] as String? ?? '',
      bn: json?['bn'] as String? ?? '',
    );
  }

  final String en;
  final String bn;

  String forLocale(String locale) =>
      locale.toLowerCase().startsWith('bn') ? bn : en;
}

enum VetDisclaimerContext {
  bookingHome('bookingHome'),
  bookingEmergency('bookingEmergency'),
  bookingOnline('bookingOnline'),
  treatmentJournal('treatmentJournal'),
  prescriptionView('prescriptionView'),
  feedRation('feedRation'),
  instantCare('instantCare');

  const VetDisclaimerContext(this.apiKey);
  final String apiKey;
}

enum VetDisclaimerAcceptSurface {
  firstVetUse('FIRST_VET_USE'),
  bookingHome('BOOKING_HOME'),
  bookingEmergency('BOOKING_EMERGENCY'),
  bookingOnline('BOOKING_ONLINE'),
  treatmentJournal('TREATMENT_JOURNAL'),
  instantCare('INSTANT_CARE'),
  serviceRequestDetail('SERVICE_REQUEST_DETAIL'),
  settings('SETTINGS');

  const VetDisclaimerAcceptSurface(this.apiValue);
  final String apiValue;
}

class VetDisclaimerContextual {
  const VetDisclaimerContextual({
    required this.bookingHome,
    required this.bookingEmergency,
    required this.bookingOnline,
    required this.treatmentJournal,
    required this.prescriptionView,
    required this.feedRation,
    required this.instantCare,
  });

  factory VetDisclaimerContextual.fromJson(Map<String, dynamic>? json) {
    return VetDisclaimerContextual(
      bookingHome: VetDisclaimerLocaleText.fromJson(
        json?['bookingHome'] as Map<String, dynamic>?,
      ),
      bookingEmergency: VetDisclaimerLocaleText.fromJson(
        json?['bookingEmergency'] as Map<String, dynamic>?,
      ),
      bookingOnline: VetDisclaimerLocaleText.fromJson(
        json?['bookingOnline'] as Map<String, dynamic>?,
      ),
      treatmentJournal: VetDisclaimerLocaleText.fromJson(
        json?['treatmentJournal'] as Map<String, dynamic>?,
      ),
      prescriptionView: VetDisclaimerLocaleText.fromJson(
        json?['prescriptionView'] as Map<String, dynamic>?,
      ),
      feedRation: VetDisclaimerLocaleText.fromJson(
        json?['feedRation'] as Map<String, dynamic>?,
      ),
      instantCare: VetDisclaimerLocaleText.fromJson(
        json?['instantCare'] as Map<String, dynamic>?,
      ),
    );
  }

  final VetDisclaimerLocaleText bookingHome;
  final VetDisclaimerLocaleText bookingEmergency;
  final VetDisclaimerLocaleText bookingOnline;
  final VetDisclaimerLocaleText treatmentJournal;
  final VetDisclaimerLocaleText prescriptionView;
  final VetDisclaimerLocaleText feedRation;
  final VetDisclaimerLocaleText instantCare;

  VetDisclaimerLocaleText forContext(VetDisclaimerContext context) =>
      switch (context) {
        VetDisclaimerContext.bookingHome => bookingHome,
        VetDisclaimerContext.bookingEmergency => bookingEmergency,
        VetDisclaimerContext.bookingOnline => bookingOnline,
        VetDisclaimerContext.treatmentJournal => treatmentJournal,
        VetDisclaimerContext.prescriptionView => prescriptionView,
        VetDisclaimerContext.feedRation => feedRation,
        VetDisclaimerContext.instantCare => instantCare,
      };
}

class VetDisclaimerBundle {
  const VetDisclaimerBundle({
    required this.version,
    required this.contentVersion,
    required this.enforceAcceptance,
    required this.accepted,
    this.acceptedAt,
    required this.title,
    required this.full,
    required this.banner,
    required this.emergency,
    required this.contextual,
    this.fromCache = false,
  });

  factory VetDisclaimerBundle.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final root = json['disclaimer'] as Map<String, dynamic>? ?? json;
    return VetDisclaimerBundle(
      version: root['version'] as String? ?? '',
      contentVersion: root['contentVersion'] as String? ?? '',
      enforceAcceptance: root['enforceAcceptance'] as bool? ?? true,
      accepted: root['accepted'] as bool? ?? false,
      acceptedAt: root['acceptedAt'] != null
          ? DateTime.tryParse(root['acceptedAt'] as String)
          : null,
      title: root['title'] as String? ?? '',
      full: VetDisclaimerLocaleText.fromJson(root['full'] as Map<String, dynamic>?),
      banner: VetDisclaimerLocaleText.fromJson(root['banner'] as Map<String, dynamic>?),
      emergency: VetDisclaimerLocaleText.fromJson(
        root['emergency'] as Map<String, dynamic>?,
      ),
      contextual: VetDisclaimerContextual.fromJson(
        root['contextual'] as Map<String, dynamic>?,
      ),
      fromCache: fromCache,
    );
  }

  final String version;
  final String contentVersion;
  final bool enforceAcceptance;
  final bool accepted;
  final DateTime? acceptedAt;
  final String title;
  final VetDisclaimerLocaleText full;
  final VetDisclaimerLocaleText banner;
  final VetDisclaimerLocaleText emergency;
  final VetDisclaimerContextual contextual;
  final bool fromCache;

  bool get acceptanceRequired => enforceAcceptance && !accepted;

  String bannerForLocale(String locale) => banner.forLocale(locale);

  String emergencyForLocale(String locale) => emergency.forLocale(locale);

  String contextualFor(VetDisclaimerContext context, String locale) =>
      contextual.forContext(context).forLocale(locale);

  Map<String, dynamic> toJson() => {
    'disclaimer': {
      'version': version,
      'contentVersion': contentVersion,
      'enforceAcceptance': enforceAcceptance,
      'accepted': accepted,
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      'title': title,
      'full': {'en': full.en, 'bn': full.bn},
      'banner': {'en': banner.en, 'bn': banner.bn},
      'emergency': {'en': emergency.en, 'bn': emergency.bn},
      'contextual': {
        'bookingHome': {'en': contextual.bookingHome.en, 'bn': contextual.bookingHome.bn},
        'bookingEmergency': {
          'en': contextual.bookingEmergency.en,
          'bn': contextual.bookingEmergency.bn,
        },
        'bookingOnline': {
          'en': contextual.bookingOnline.en,
          'bn': contextual.bookingOnline.bn,
        },
        'treatmentJournal': {
          'en': contextual.treatmentJournal.en,
          'bn': contextual.treatmentJournal.bn,
        },
        'prescriptionView': {
          'en': contextual.prescriptionView.en,
          'bn': contextual.prescriptionView.bn,
        },
        'feedRation': {'en': contextual.feedRation.en, 'bn': contextual.feedRation.bn},
        'instantCare': {'en': contextual.instantCare.en, 'bn': contextual.instantCare.bn},
      },
    },
  };
}
