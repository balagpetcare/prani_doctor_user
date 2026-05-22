class AppConfigDto {
  const AppConfigDto({
    this.emergencyPhone,
    this.supportPhone,
    this.supportWhatsapp,
    this.minimumVersion,
    this.updateUrl,
    this.updateRequired,
    this.updateMessage,
  });

  factory AppConfigDto.fromJson(Map<String, dynamic> json) {
    return AppConfigDto(
      emergencyPhone: json['emergencyPhone'] as String?,
      supportPhone: json['supportPhone'] as String?,
      supportWhatsapp: json['supportWhatsapp'] as String?,
      minimumVersion: json['minimumVersion'] as String?,
      updateUrl: json['updateUrl'] as String?,
      updateRequired: json['updateRequired'] as bool?,
      updateMessage: json['updateMessage'] as String?,
    );
  }

  final String? emergencyPhone;
  final String? supportPhone;
  final String? supportWhatsapp;

  /// Optional — not yet returned by backend; parsed when available.
  final String? minimumVersion;
  final String? updateUrl;
  final bool? updateRequired;
  final String? updateMessage;

  bool get hasSupportContacts =>
      (emergencyPhone?.isNotEmpty ?? false) ||
      (supportPhone?.isNotEmpty ?? false) ||
      (supportWhatsapp?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
        if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
        if (supportPhone != null) 'supportPhone': supportPhone,
        if (supportWhatsapp != null) 'supportWhatsapp': supportWhatsapp,
        if (minimumVersion != null) 'minimumVersion': minimumVersion,
        if (updateUrl != null) 'updateUrl': updateUrl,
        if (updateRequired != null) 'updateRequired': updateRequired,
        if (updateMessage != null) 'updateMessage': updateMessage,
      };
}

class AppConfigLoadResult {
  const AppConfigLoadResult({
    required this.config,
    required this.fromCache,
  });

  final AppConfigDto config;
  final bool fromCache;
}
