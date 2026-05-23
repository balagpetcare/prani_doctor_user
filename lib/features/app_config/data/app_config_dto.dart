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
  });

  factory AppConfigDto.fromJson(Map<String, dynamic> json) {
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

  bool get hasSupportContacts =>
      (emergencyPhone?.isNotEmpty ?? false) ||
      (supportPhone?.isNotEmpty ?? false) ||
      (supportWhatsapp?.isNotEmpty ?? false);

  bool get isMaintenanceMode => maintenanceMode == true;

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
  };
}

class AppConfigLoadResult {
  const AppConfigLoadResult({required this.config, required this.fromCache});

  final AppConfigDto config;
  final bool fromCache;
}
