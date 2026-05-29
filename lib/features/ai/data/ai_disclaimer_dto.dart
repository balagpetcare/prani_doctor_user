class AiDisclaimerLocaleText {
  const AiDisclaimerLocaleText({required this.en, required this.bn});

  factory AiDisclaimerLocaleText.fromJson(Map<String, dynamic>? json) {
    return AiDisclaimerLocaleText(
      en: json?['en'] as String? ?? '',
      bn: json?['bn'] as String? ?? '',
    );
  }

  final String en;
  final String bn;

  String forLocale(String locale) =>
      locale.toLowerCase().startsWith('bn') ? bn : en;
}

class AiDisclaimerBundle {
  const AiDisclaimerBundle({
    required this.version,
    required this.contentVersion,
    required this.enforceAcceptance,
    required this.accepted,
    this.acceptedAt,
    required this.title,
    required this.full,
    required this.banner,
    required this.contextual,
    this.fromCache = false,
  });

  factory AiDisclaimerBundle.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final root = json['disclaimer'] as Map<String, dynamic>? ?? json;
    return AiDisclaimerBundle(
      version: root['version'] as String? ?? '',
      contentVersion: root['contentVersion'] as String? ?? '',
      enforceAcceptance: root['enforceAcceptance'] as bool? ?? true,
      accepted: root['accepted'] as bool? ?? false,
      acceptedAt: root['acceptedAt'] != null
          ? DateTime.tryParse(root['acceptedAt'] as String)
          : null,
      title: root['title'] as String? ?? '',
      full: AiDisclaimerLocaleText.fromJson(
        root['full'] as Map<String, dynamic>?,
      ),
      banner: AiDisclaimerLocaleText.fromJson(
        root['banner'] as Map<String, dynamic>?,
      ),
      contextual: AiDisclaimerContextual.fromJson(
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
  final AiDisclaimerLocaleText full;
  final AiDisclaimerLocaleText banner;
  final AiDisclaimerContextual contextual;
  final bool fromCache;

  bool get acceptanceRequired => enforceAcceptance && !accepted;

  String bannerForLocale(String locale) => banner.forLocale(locale);

  String contextualFor(AiDisclaimerFeature feature, String locale) =>
      contextual.forFeature(feature).forLocale(locale);

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
      'contextual': {
        'chat': {'en': contextual.chat.en, 'bn': contextual.chat.bn},
        'recommendations': {
          'en': contextual.recommendations.en,
          'bn': contextual.recommendations.bn,
        },
        'advisory': {'en': contextual.advisory.en, 'bn': contextual.advisory.bn},
      },
    },
  };
}

enum AiDisclaimerFeature { chat, recommendations, advisory }

enum AiDisclaimerAcceptSurface {
  firstAiUse('FIRST_AI_USE'),
  aiHome('AI_HOME'),
  aiChat('AI_CHAT'),
  aiRecommendations('AI_RECOMMENDATIONS'),
  aiAdvisory('AI_ADVISORY'),
  settings('SETTINGS');

  const AiDisclaimerAcceptSurface(this.apiValue);
  final String apiValue;
}

class AiDisclaimerContextual {
  const AiDisclaimerContextual({
    required this.chat,
    required this.recommendations,
    required this.advisory,
  });

  factory AiDisclaimerContextual.fromJson(Map<String, dynamic>? json) {
    return AiDisclaimerContextual(
      chat: AiDisclaimerLocaleText.fromJson(json?['chat'] as Map<String, dynamic>?),
      recommendations: AiDisclaimerLocaleText.fromJson(
        json?['recommendations'] as Map<String, dynamic>?,
      ),
      advisory: AiDisclaimerLocaleText.fromJson(
        json?['advisory'] as Map<String, dynamic>?,
      ),
    );
  }

  final AiDisclaimerLocaleText chat;
  final AiDisclaimerLocaleText recommendations;
  final AiDisclaimerLocaleText advisory;

  AiDisclaimerLocaleText forFeature(AiDisclaimerFeature feature) => switch (feature) {
    AiDisclaimerFeature.chat => chat,
    AiDisclaimerFeature.recommendations => recommendations,
    AiDisclaimerFeature.advisory => advisory,
  };
}
