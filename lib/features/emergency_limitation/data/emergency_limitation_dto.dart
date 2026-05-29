class EmergencyLimitationLocaleText {
  const EmergencyLimitationLocaleText({required this.en, required this.bn});

  factory EmergencyLimitationLocaleText.fromJson(Map<String, dynamic>? json) {
    return EmergencyLimitationLocaleText(
      en: json?['en'] as String? ?? '',
      bn: json?['bn'] as String? ?? '',
    );
  }

  final String en;
  final String bn;

  String forLocale(String locale) =>
      locale.toLowerCase().startsWith('bn') ? bn : en;
}

enum EmergencyLimitationContext {
  instantCare('instantCare'),
  aiEmergency('aiEmergency'),
  bookingEmergency('bookingEmergency'),
  discoveryEmergency('discoveryEmergency'),
  requestPending('requestPending'),
  bookingOnline('bookingOnline'),
  phoneDial('phoneDial');

  const EmergencyLimitationContext(this.apiKey);
  final String apiKey;
}

enum EmergencyLimitationAcceptSurface {
  firstEmergencyUse('FIRST_EMERGENCY_USE'),
  instantCare('INSTANT_CARE'),
  bookingEmergency('BOOKING_EMERGENCY'),
  discoveryEmergency('DISCOVERY_EMERGENCY'),
  serviceRequestDetail('SERVICE_REQUEST_DETAIL'),
  aiEmergency('AI_EMERGENCY'),
  phoneDial('PHONE_DIAL'),
  settings('SETTINGS');

  const EmergencyLimitationAcceptSurface(this.apiValue);
  final String apiValue;
}

class EmergencyLimitationContextual {
  const EmergencyLimitationContextual({
    required this.instantCare,
    required this.aiEmergency,
    required this.bookingEmergency,
    required this.discoveryEmergency,
    required this.requestPending,
    required this.bookingOnline,
    required this.phoneDial,
  });

  factory EmergencyLimitationContextual.fromJson(Map<String, dynamic>? json) {
    return EmergencyLimitationContextual(
      instantCare: EmergencyLimitationLocaleText.fromJson(
        json?['instantCare'] as Map<String, dynamic>?,
      ),
      aiEmergency: EmergencyLimitationLocaleText.fromJson(
        json?['aiEmergency'] as Map<String, dynamic>?,
      ),
      bookingEmergency: EmergencyLimitationLocaleText.fromJson(
        json?['bookingEmergency'] as Map<String, dynamic>?,
      ),
      discoveryEmergency: EmergencyLimitationLocaleText.fromJson(
        json?['discoveryEmergency'] as Map<String, dynamic>?,
      ),
      requestPending: EmergencyLimitationLocaleText.fromJson(
        json?['requestPending'] as Map<String, dynamic>?,
      ),
      bookingOnline: EmergencyLimitationLocaleText.fromJson(
        json?['bookingOnline'] as Map<String, dynamic>?,
      ),
      phoneDial: EmergencyLimitationLocaleText.fromJson(
        json?['phoneDial'] as Map<String, dynamic>?,
      ),
    );
  }

  final EmergencyLimitationLocaleText instantCare;
  final EmergencyLimitationLocaleText aiEmergency;
  final EmergencyLimitationLocaleText bookingEmergency;
  final EmergencyLimitationLocaleText discoveryEmergency;
  final EmergencyLimitationLocaleText requestPending;
  final EmergencyLimitationLocaleText bookingOnline;
  final EmergencyLimitationLocaleText phoneDial;

  EmergencyLimitationLocaleText forContext(EmergencyLimitationContext context) =>
      switch (context) {
        EmergencyLimitationContext.instantCare => instantCare,
        EmergencyLimitationContext.aiEmergency => aiEmergency,
        EmergencyLimitationContext.bookingEmergency => bookingEmergency,
        EmergencyLimitationContext.discoveryEmergency => discoveryEmergency,
        EmergencyLimitationContext.requestPending => requestPending,
        EmergencyLimitationContext.bookingOnline => bookingOnline,
        EmergencyLimitationContext.phoneDial => phoneDial,
      };
}

class EmergencyLimitationBundle {
  const EmergencyLimitationBundle({
    required this.version,
    required this.contentVersion,
    required this.enforceAcceptance,
    required this.accepted,
    this.acceptedAt,
    required this.title,
    required this.full,
    required this.banner,
    required this.urgent,
    required this.contextual,
    this.fromCache = false,
  });

  factory EmergencyLimitationBundle.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final root = json['limitation'] as Map<String, dynamic>? ?? json;
    return EmergencyLimitationBundle(
      version: root['version'] as String? ?? '',
      contentVersion: root['contentVersion'] as String? ?? '',
      enforceAcceptance: root['enforceAcceptance'] as bool? ?? true,
      accepted: root['accepted'] as bool? ?? false,
      acceptedAt: root['acceptedAt'] != null
          ? DateTime.tryParse(root['acceptedAt'] as String)
          : null,
      title: root['title'] as String? ?? '',
      full: EmergencyLimitationLocaleText.fromJson(root['full'] as Map<String, dynamic>?),
      banner: EmergencyLimitationLocaleText.fromJson(root['banner'] as Map<String, dynamic>?),
      urgent: EmergencyLimitationLocaleText.fromJson(root['urgent'] as Map<String, dynamic>?),
      contextual: EmergencyLimitationContextual.fromJson(
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
  final EmergencyLimitationLocaleText full;
  final EmergencyLimitationLocaleText banner;
  final EmergencyLimitationLocaleText urgent;
  final EmergencyLimitationContextual contextual;
  final bool fromCache;

  bool get acceptanceRequired => enforceAcceptance && !accepted;

  String bannerForLocale(String locale) => banner.forLocale(locale);

  String urgentForLocale(String locale) => urgent.forLocale(locale);

  String contextualFor(EmergencyLimitationContext context, String locale) =>
      contextual.forContext(context).forLocale(locale);

  Map<String, dynamic> toJson() => {
    'limitation': {
      'version': version,
      'contentVersion': contentVersion,
      'enforceAcceptance': enforceAcceptance,
      'accepted': accepted,
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      'title': title,
      'full': {'en': full.en, 'bn': full.bn},
      'banner': {'en': banner.en, 'bn': banner.bn},
      'urgent': {'en': urgent.en, 'bn': urgent.bn},
      'contextual': {
        'instantCare': {'en': contextual.instantCare.en, 'bn': contextual.instantCare.bn},
        'aiEmergency': {'en': contextual.aiEmergency.en, 'bn': contextual.aiEmergency.bn},
        'bookingEmergency': {
          'en': contextual.bookingEmergency.en,
          'bn': contextual.bookingEmergency.bn,
        },
        'discoveryEmergency': {
          'en': contextual.discoveryEmergency.en,
          'bn': contextual.discoveryEmergency.bn,
        },
        'requestPending': {
          'en': contextual.requestPending.en,
          'bn': contextual.requestPending.bn,
        },
        'bookingOnline': {
          'en': contextual.bookingOnline.en,
          'bn': contextual.bookingOnline.bn,
        },
        'phoneDial': {'en': contextual.phoneDial.en, 'bn': contextual.phoneDial.bn},
      },
    },
  };
}
