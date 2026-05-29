class ConsentRecordDto {
  const ConsentRecordDto({
    required this.type,
    required this.key,
    required this.label,
    required this.requiredVersion,
    required this.accepted,
    this.acceptedVersion,
    this.acceptedAt,
    required this.hardGate,
  });

  final String type;
  final String key;
  final String label;
  final String requiredVersion;
  final bool accepted;
  final String? acceptedVersion;
  final DateTime? acceptedAt;
  final bool hardGate;

  factory ConsentRecordDto.fromJson(Map<String, dynamic> json) {
    return ConsentRecordDto(
      type: json['type'] as String? ?? '',
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      requiredVersion: json['requiredVersion'] as String? ?? '',
      accepted: json['accepted'] as bool? ?? false,
      acceptedVersion: json['acceptedVersion'] as String?,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      hardGate: json['hardGate'] as bool? ?? false,
    );
  }
}

class ConsentStatusDto {
  const ConsentStatusDto({
    required this.records,
    required this.reconsentRequired,
    required this.enforcePrivacyConsent,
  });

  final List<ConsentRecordDto> records;
  final List<String> reconsentRequired;
  final bool enforcePrivacyConsent;

  factory ConsentStatusDto.fromJson(Map<String, dynamic> json) {
    final recordsRaw = json['records'];
    return ConsentStatusDto(
      records: recordsRaw is List
          ? recordsRaw
                .whereType<Map>()
                .map((e) => ConsentRecordDto.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      reconsentRequired: (json['reconsentRequired'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      enforcePrivacyConsent: json['enforcePrivacyConsent'] as bool? ?? false,
    );
  }
}
