enum SettingsTheme { system, light, dark }

extension SettingsThemeApi on SettingsTheme {
  String get apiValue => name.toUpperCase();

  static SettingsTheme fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'LIGHT':
        return SettingsTheme.light;
      case 'DARK':
        return SettingsTheme.dark;
      default:
        return SettingsTheme.system;
    }
  }
}

class UserSettingsDto {
  const UserSettingsDto({
    required this.theme,
    this.locale,
    this.privacyAcceptedVersion,
    this.privacyAcceptedAt,
    this.termsAcceptedVersion,
    this.termsAcceptedAt,
    required this.updatedAt,
    this.fromCache = false,
  });

  final SettingsTheme theme;
  final String? locale;
  final String? privacyAcceptedVersion;
  final DateTime? privacyAcceptedAt;
  final String? termsAcceptedVersion;
  final DateTime? termsAcceptedAt;
  final DateTime updatedAt;
  final bool fromCache;

  factory UserSettingsDto.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return UserSettingsDto(
      theme: SettingsThemeApi.fromApi(json['theme'] as String?),
      locale: json['locale'] as String?,
      privacyAcceptedVersion: json['privacyAcceptedVersion'] as String?,
      privacyAcceptedAt: json['privacyAcceptedAt'] != null
          ? DateTime.tryParse(json['privacyAcceptedAt'] as String)
          : null,
      termsAcceptedVersion: json['termsAcceptedVersion'] as String?,
      termsAcceptedAt: json['termsAcceptedAt'] != null
          ? DateTime.tryParse(json['termsAcceptedAt'] as String)
          : null,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme.apiValue,
    if (locale != null) 'locale': locale,
    if (privacyAcceptedVersion != null)
      'privacyAcceptedVersion': privacyAcceptedVersion,
    if (privacyAcceptedAt != null)
      'privacyAcceptedAt': privacyAcceptedAt!.toIso8601String(),
    if (termsAcceptedVersion != null)
      'termsAcceptedVersion': termsAcceptedVersion,
    if (termsAcceptedAt != null)
      'termsAcceptedAt': termsAcceptedAt!.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class LegalSummaryDto {
  const LegalSummaryDto({
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    required this.privacyVersion,
    required this.termsVersion,
    required this.privacyAccepted,
    required this.termsAccepted,
  });

  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final String privacyVersion;
  final String termsVersion;
  final bool privacyAccepted;
  final bool termsAccepted;

  factory LegalSummaryDto.fromJson(Map<String, dynamic> json) {
    return LegalSummaryDto(
      privacyPolicyUrl: json['privacyPolicyUrl'] as String? ?? '',
      termsOfServiceUrl: json['termsOfServiceUrl'] as String? ?? '',
      privacyVersion: json['privacyVersion'] as String? ?? '',
      termsVersion: json['termsVersion'] as String? ?? '',
      privacyAccepted: json['privacyAccepted'] as bool? ?? false,
      termsAccepted: json['termsAccepted'] as bool? ?? false,
    );
  }
}

class SettingsBundle {
  const SettingsBundle({
    required this.settings,
    required this.legal,
    this.fromCache = false,
  });

  final UserSettingsDto settings;
  final LegalSummaryDto legal;
  final bool fromCache;

  factory SettingsBundle.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final settingsRaw = json['settings'];
    final legalRaw = json['legal'];
    return SettingsBundle(
      settings: UserSettingsDto.fromJson(
        settingsRaw is Map
            ? Map<String, dynamic>.from(settingsRaw)
            : <String, dynamic>{},
        fromCache: fromCache,
      ),
      legal: LegalSummaryDto.fromJson(
        legalRaw is Map
            ? Map<String, dynamic>.from(legalRaw)
            : <String, dynamic>{},
      ),
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'settings': settings.toJson(),
    'legal': {
      'privacyPolicyUrl': legal.privacyPolicyUrl,
      'termsOfServiceUrl': legal.termsOfServiceUrl,
      'privacyVersion': legal.privacyVersion,
      'termsVersion': legal.termsVersion,
      'privacyAccepted': legal.privacyAccepted,
      'termsAccepted': legal.termsAccepted,
    },
  };
}

class LegalDocumentDto {
  const LegalDocumentDto({
    required this.type,
    required this.version,
    required this.url,
    required this.title,
    required this.content,
    required this.accepted,
    this.acceptedAt,
    this.fromCache = false,
  });

  final String type;
  final String version;
  final String url;
  final String title;
  final String content;
  final bool accepted;
  final DateTime? acceptedAt;
  final bool fromCache;

  factory LegalDocumentDto.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final doc = json['document'] as Map<String, dynamic>? ?? json;
    return LegalDocumentDto(
      type: doc['type'] as String? ?? '',
      version: doc['version'] as String? ?? '',
      url: doc['url'] as String? ?? '',
      title: doc['title'] as String? ?? '',
      content: doc['content'] as String? ?? '',
      accepted: doc['accepted'] as bool? ?? false,
      acceptedAt: doc['acceptedAt'] != null
          ? DateTime.tryParse(doc['acceptedAt'] as String)
          : null,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'document': {
      'type': type,
      'version': version,
      'url': url,
      'title': title,
      'content': content,
      'accepted': accepted,
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
    },
  };
}

class SettingsSyncInput {
  const SettingsSyncInput({
    this.theme,
    this.locale,
    this.acceptPrivacyVersion,
    this.acceptTermsVersion,
  });

  final SettingsTheme? theme;
  final String? locale;
  final String? acceptPrivacyVersion;
  final String? acceptTermsVersion;

  Map<String, dynamic> toJson() => {
    if (theme != null) 'theme': theme!.apiValue,
    if (locale != null) 'locale': locale,
    if (acceptPrivacyVersion != null)
      'acceptPrivacyVersion': acceptPrivacyVersion,
    if (acceptTermsVersion != null) 'acceptTermsVersion': acceptTermsVersion,
  };
}
