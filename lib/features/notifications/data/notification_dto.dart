class MobileNotificationDto {
  const MobileNotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
    this.metadata,
    this.fromCache = false,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? readAt;
  final String createdAt;
  final Map<String, dynamic>? metadata;
  final bool fromCache;

  bool get isUnread => readAt == null;

  String? get serviceRequestId {
    final value = metadata?['serviceRequestId'];
    return value is String ? value : null;
  }

  String? get animalId {
    final value = metadata?['animalId'];
    return value is String ? value : null;
  }

  String? get treatmentId {
    final value = metadata?['treatmentId'];
    return value is String ? value : null;
  }

  String? get target {
    final value = metadata?['target'];
    return value is String ? value : null;
  }

  MobileNotificationDto copyWith({String? readAt, bool? fromCache}) {
    return MobileNotificationDto(
      id: id,
      type: type,
      title: title,
      body: body,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      metadata: metadata,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'readAt': readAt,
    'createdAt': createdAt,
    if (metadata != null) 'metadata': metadata,
  };

  factory MobileNotificationDto.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
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
      fromCache: fromCache,
    );
  }
}

class NotificationListResultDto {
  const NotificationListResultDto({
    required this.items,
    required this.total,
    this.fromCache = false,
  });

  final List<MobileNotificationDto> items;
  final int total;
  final bool fromCache;
}

class NotificationSettingsDto {
  const NotificationSettingsDto({
    required this.pushEnabled,
    required this.marketingEnabled,
    required this.treatmentReminderEnabled,
    required this.vaccineReminderEnabled,
    required this.orderServiceEnabled,
    required this.updatedAt,
    this.fromCache = false,
  });

  final bool pushEnabled;
  final bool marketingEnabled;
  final bool treatmentReminderEnabled;
  final bool vaccineReminderEnabled;
  final bool orderServiceEnabled;
  final String updatedAt;
  final bool fromCache;

  NotificationSettingsDto copyWith({
    bool? pushEnabled,
    bool? marketingEnabled,
    bool? treatmentReminderEnabled,
    bool? vaccineReminderEnabled,
    bool? orderServiceEnabled,
    bool? fromCache,
  }) {
    return NotificationSettingsDto(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
      treatmentReminderEnabled:
          treatmentReminderEnabled ?? this.treatmentReminderEnabled,
      vaccineReminderEnabled:
          vaccineReminderEnabled ?? this.vaccineReminderEnabled,
      orderServiceEnabled: orderServiceEnabled ?? this.orderServiceEnabled,
      updatedAt: updatedAt,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'marketingEnabled': marketingEnabled,
    'treatmentReminderEnabled': treatmentReminderEnabled,
    'vaccineReminderEnabled': vaccineReminderEnabled,
    'orderServiceEnabled': orderServiceEnabled,
    'updatedAt': updatedAt,
  };

  factory NotificationSettingsDto.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return NotificationSettingsDto(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      marketingEnabled: json['marketingEnabled'] as bool? ?? false,
      treatmentReminderEnabled:
          json['treatmentReminderEnabled'] as bool? ?? true,
      vaccineReminderEnabled: json['vaccineReminderEnabled'] as bool? ?? true,
      orderServiceEnabled: json['orderServiceEnabled'] as bool? ?? true,
      updatedAt: json['updatedAt'] as String? ?? '',
      fromCache: fromCache,
    );
  }
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

enum NotificationTimeGroup { today, yesterday, earlier }

class NotificationGroupedSection {
  const NotificationGroupedSection({required this.group, required this.items});

  final NotificationTimeGroup group;
  final List<MobileNotificationDto> items;
}
