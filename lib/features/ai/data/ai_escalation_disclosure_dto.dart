class AiEscalationDisclosureLocaleText {
  const AiEscalationDisclosureLocaleText({required this.en, required this.bn});

  factory AiEscalationDisclosureLocaleText.fromJson(Map<String, dynamic>? json) {
    return AiEscalationDisclosureLocaleText(
      en: json?['en'] as String? ?? '',
      bn: json?['bn'] as String? ?? '',
    );
  }

  final String en;
  final String bn;

  String forLocale(String locale) =>
      locale.toLowerCase().startsWith('bn') ? bn : en;
}

enum AiEscalationDisclosureTrigger {
  emergency,
  high,
  lowConfidence,
  policyRefusal,
  supportVsVet,
  humanReview,
  escalationRecorded,
  keywordLimitation,
}

extension AiEscalationDisclosureTriggerApi on AiEscalationDisclosureTrigger {
  static AiEscalationDisclosureTrigger? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final t in AiEscalationDisclosureTrigger.values) {
      if (t.name == value) return t;
    }
    return null;
  }
}

class AiEscalationDisclosureBundle {
  const AiEscalationDisclosureBundle({
    required this.contentVersion,
    required this.banner,
    required this.full,
    required this.contextual,
    this.fromCache = false,
  });

  factory AiEscalationDisclosureBundle.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final root = json['disclosure'] as Map<String, dynamic>? ?? json;
    final contextualRaw = root['contextual'] as Map<String, dynamic>? ?? {};
    return AiEscalationDisclosureBundle(
      contentVersion: root['contentVersion'] as String? ?? '',
      banner: AiEscalationDisclosureLocaleText.fromJson(
        root['banner'] as Map<String, dynamic>?,
      ),
      full: AiEscalationDisclosureLocaleText.fromJson(
        root['full'] as Map<String, dynamic>?,
      ),
      contextual: AiEscalationDisclosureContextual.fromJson(contextualRaw),
      fromCache: fromCache,
    );
  }

  final String contentVersion;
  final AiEscalationDisclosureLocaleText banner;
  final AiEscalationDisclosureLocaleText full;
  final AiEscalationDisclosureContextual contextual;
  final bool fromCache;

  String bannerForLocale(String locale) => banner.forLocale(locale);

  String textFor(AiEscalationDisclosureTrigger trigger, String locale) =>
      contextual.forTrigger(trigger).forLocale(locale);

  Map<String, dynamic> toJson() => {
    'disclosure': {
      'contentVersion': contentVersion,
      'banner': {'en': banner.en, 'bn': banner.bn},
      'full': {'en': full.en, 'bn': full.bn},
      'contextual': contextual.toJson(),
    },
  };
}

class AiEscalationDisclosureContextual {
  const AiEscalationDisclosureContextual({
    required this.emergency,
    required this.high,
    required this.lowConfidence,
    required this.policyRefusal,
    required this.supportVsVet,
    required this.humanReview,
    required this.escalationRecorded,
    required this.keywordLimitation,
  });

  factory AiEscalationDisclosureContextual.fromJson(Map<String, dynamic> json) {
    return AiEscalationDisclosureContextual(
      emergency: AiEscalationDisclosureLocaleText.fromJson(
        json['emergency'] as Map<String, dynamic>?,
      ),
      high: AiEscalationDisclosureLocaleText.fromJson(
        json['high'] as Map<String, dynamic>?,
      ),
      lowConfidence: AiEscalationDisclosureLocaleText.fromJson(
        json['lowConfidence'] as Map<String, dynamic>?,
      ),
      policyRefusal: AiEscalationDisclosureLocaleText.fromJson(
        json['policyRefusal'] as Map<String, dynamic>?,
      ),
      supportVsVet: AiEscalationDisclosureLocaleText.fromJson(
        json['supportVsVet'] as Map<String, dynamic>?,
      ),
      humanReview: AiEscalationDisclosureLocaleText.fromJson(
        json['humanReview'] as Map<String, dynamic>?,
      ),
      escalationRecorded: AiEscalationDisclosureLocaleText.fromJson(
        json['escalationRecorded'] as Map<String, dynamic>?,
      ),
      keywordLimitation: AiEscalationDisclosureLocaleText.fromJson(
        json['keywordLimitation'] as Map<String, dynamic>?,
      ),
    );
  }

  final AiEscalationDisclosureLocaleText emergency;
  final AiEscalationDisclosureLocaleText high;
  final AiEscalationDisclosureLocaleText lowConfidence;
  final AiEscalationDisclosureLocaleText policyRefusal;
  final AiEscalationDisclosureLocaleText supportVsVet;
  final AiEscalationDisclosureLocaleText humanReview;
  final AiEscalationDisclosureLocaleText escalationRecorded;
  final AiEscalationDisclosureLocaleText keywordLimitation;

  AiEscalationDisclosureLocaleText forTrigger(AiEscalationDisclosureTrigger trigger) =>
      switch (trigger) {
        AiEscalationDisclosureTrigger.emergency => emergency,
        AiEscalationDisclosureTrigger.high => high,
        AiEscalationDisclosureTrigger.lowConfidence => lowConfidence,
        AiEscalationDisclosureTrigger.policyRefusal => policyRefusal,
        AiEscalationDisclosureTrigger.supportVsVet => supportVsVet,
        AiEscalationDisclosureTrigger.humanReview => humanReview,
        AiEscalationDisclosureTrigger.escalationRecorded => escalationRecorded,
        AiEscalationDisclosureTrigger.keywordLimitation => keywordLimitation,
      };

  Map<String, dynamic> toJson() => {
    'emergency': {'en': emergency.en, 'bn': emergency.bn},
    'high': {'en': high.en, 'bn': high.bn},
    'lowConfidence': {'en': lowConfidence.en, 'bn': lowConfidence.bn},
    'policyRefusal': {'en': policyRefusal.en, 'bn': policyRefusal.bn},
    'supportVsVet': {'en': supportVsVet.en, 'bn': supportVsVet.bn},
    'humanReview': {'en': humanReview.en, 'bn': humanReview.bn},
    'escalationRecorded': {'en': escalationRecorded.en, 'bn': escalationRecorded.bn},
    'keywordLimitation': {'en': keywordLimitation.en, 'bn': keywordLimitation.bn},
  };
}

/// Fields returned on AI responses when escalation context applies.
class AiEscalationDisclosureFields {
  const AiEscalationDisclosureFields({
    this.disclosure,
    this.trigger,
    this.version,
  });

  factory AiEscalationDisclosureFields.fromJson(Map<String, dynamic> json) {
    return AiEscalationDisclosureFields(
      disclosure: json['escalationDisclosure'] as String?,
      trigger: AiEscalationDisclosureTriggerApi.fromApi(
        json['escalationTrigger'] as String?,
      ),
      version: json['escalationDisclosureVersion'] as String?,
    );
  }

  final String? disclosure;
  final AiEscalationDisclosureTrigger? trigger;
  final String? version;
}
