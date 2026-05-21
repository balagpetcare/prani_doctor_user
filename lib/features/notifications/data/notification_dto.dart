class MobileNotificationDto {
  const MobileNotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
    this.metadata,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? readAt;
  final String createdAt;
  final Map<String, dynamic>? metadata;

  bool get isUnread => readAt == null;

  String? get serviceRequestId {
    final value = metadata?['serviceRequestId'];
    return value is String ? value : null;
  }

  factory MobileNotificationDto.fromJson(Map<String, dynamic> json) {
    return MobileNotificationDto(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }
}

class NotificationListResultDto {
  const NotificationListResultDto({
    required this.items,
    required this.total,
  });

  final List<MobileNotificationDto> items;
  final int total;
}

class DeviceRegistrationResultDto {
  const DeviceRegistrationResultDto({
    required this.deviceId,
    required this.deviceKey,
    required this.registered,
    this.replaced,
  });

  final String deviceId;
  final String deviceKey;
  final bool registered;
  final bool? replaced;

  factory DeviceRegistrationResultDto.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResultDto(
      deviceId: json['deviceId'] as String? ?? '',
      deviceKey: json['deviceKey'] as String? ?? '',
      registered: json['registered'] as bool? ?? true,
      replaced: json['replaced'] as bool?,
    );
  }
}
