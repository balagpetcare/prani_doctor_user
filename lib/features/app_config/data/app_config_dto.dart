class AppConfigDto {
  const AppConfigDto({
    this.emergencyPhone,
    this.supportPhone,
    this.supportWhatsapp,
    this.minimumVersion,
    this.recommendedVersion,
    this.updateUrl,
    this.updateRequired,
    this.updateMessage,
    this.maintenanceMode,
    this.maintenanceMessage,
    this.closedBeta,
  });

  factory AppConfigDto.fromJson(Map<String, dynamic> json) {
    final closedBetaRaw = json['closedBeta'];
    ClosedBetaAppConfig? closedBeta;
    if (closedBetaRaw is Map<String, dynamic>) {
      closedBeta = ClosedBetaAppConfig.fromJson(closedBetaRaw);
    }
    return AppConfigDto(
      emergencyPhone: json['emergencyPhone'] as String?,
      supportPhone: json['supportPhone'] as String?,
      supportWhatsapp: json['supportWhatsapp'] as String?,
      minimumVersion: json['minimumVersion'] as String?,
      recommendedVersion: json['recommendedVersion'] as String?,
      updateUrl: json['updateUrl'] as String?,
      updateRequired: json['updateRequired'] as bool?,
      updateMessage: json['updateMessage'] as String?,
      maintenanceMode: json['maintenanceMode'] as bool?,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      closedBeta: closedBeta,
    );
  }

  final String? emergencyPhone;
  final String? supportPhone;
  final String? supportWhatsapp;

  /// Minimum semver required to use the app (force update when below).
  final String? minimumVersion;

  /// Soft-update prompt when below this version but above [minimumVersion].
  final String? recommendedVersion;
  final String? updateUrl;
  final bool? updateRequired;
  final String? updateMessage;

  /// When true, boot blocks with maintenance screen.
  final bool? maintenanceMode;
  final String? maintenanceMessage;
  final ClosedBetaAppConfig? closedBeta;

  bool get hasSupportContacts =>
      (emergencyPhone?.isNotEmpty ?? false) ||
      (supportPhone?.isNotEmpty ?? false) ||
      (supportWhatsapp?.isNotEmpty ?? false);

  bool get isMaintenanceMode => maintenanceMode == true;

  bool get isClosedBetaActive => closedBeta?.enabled == true;

  Map<String, dynamic> toJson() => {
    if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
    if (supportPhone != null) 'supportPhone': supportPhone,
    if (supportWhatsapp != null) 'supportWhatsapp': supportWhatsapp,
    if (minimumVersion != null) 'minimumVersion': minimumVersion,
    if (recommendedVersion != null) 'recommendedVersion': recommendedVersion,
    if (updateUrl != null) 'updateUrl': updateUrl,
    if (updateRequired != null) 'updateRequired': updateRequired,
    if (updateMessage != null) 'updateMessage': updateMessage,
    if (maintenanceMode != null) 'maintenanceMode': maintenanceMode,
    if (maintenanceMessage != null) 'maintenanceMessage': maintenanceMessage,
    if (closedBeta != null) 'closedBeta': closedBeta!.toJson(),
  };
}

class ClosedBetaAppConfig {
  const ClosedBetaAppConfig({
    required this.enabled,
    required this.feedbackEnabled,
    this.activeCohort,
    this.betaBannerEn,
    this.betaBannerBn,
    this.supportWhatsapp,
  });

  factory ClosedBetaAppConfig.fromJson(Map<String, dynamic> json) {
    String? bannerEn;
    String? bannerBn;
    final banner = json['betaBanner'];
    if (banner is Map<String, dynamic>) {
      bannerEn = banner['en'] as String?;
      bannerBn = banner['bn'] as String?;
    }
    return ClosedBetaAppConfig(
      enabled: json['enabled'] as bool? ?? false,
      feedbackEnabled: json['feedbackEnabled'] as bool? ?? true,
      activeCohort: json['activeCohort'] as String?,
      betaBannerEn: bannerEn,
      betaBannerBn: bannerBn,
      supportWhatsapp: json['supportWhatsapp'] as String?,
    );
  }

  final bool enabled;
  final bool feedbackEnabled;
  final String? activeCohort;
  final String? betaBannerEn;
  final String? betaBannerBn;
  final String? supportWhatsapp;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'feedbackEnabled': feedbackEnabled,
    if (activeCohort != null) 'activeCohort': activeCohort,
    if (betaBannerEn != null || betaBannerBn != null)
      'betaBanner': {
        if (betaBannerEn != null) 'en': betaBannerEn,
        if (betaBannerBn != null) 'bn': betaBannerBn,
      },
    if (supportWhatsapp != null) 'supportWhatsapp': supportWhatsapp,
  };
}

class AppConfigLoadResult {
  const AppConfigLoadResult({required this.config, required this.fromCache});

  final AppConfigDto config;
  final bool fromCache;
}
