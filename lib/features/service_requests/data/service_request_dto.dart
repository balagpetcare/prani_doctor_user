enum ServiceRequestStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  assigned('ASSIGNED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  rejected('REJECTED');

  const ServiceRequestStatus(this.apiValue);

  final String apiValue;

  static ServiceRequestStatus fromApi(String value) {
    return ServiceRequestStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => ServiceRequestStatus.pending,
    );
  }

  bool get isActive =>
      this == pending ||
      this == assigned ||
      this == accepted ||
      this == inProgress;

  bool get isCompleted => this == completed;

  bool get isClosed => this == cancelled || this == rejected;

  bool get isCustomerCancellable =>
      this == pending || this == accepted || this == assigned;
}

class ServiceRequestCategoryDto {
  const ServiceRequestCategoryDto({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory ServiceRequestCategoryDto.fromJson(Map<String, dynamic> json) {
    return ServiceRequestCategoryDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class ServiceRequestAnimalDto {
  const ServiceRequestAnimalDto({
    required this.id,
    required this.name,
    required this.animalType,
    this.species,
  });

  final String id;
  final String name;
  final String animalType;
  final String? species;

  factory ServiceRequestAnimalDto.fromJson(Map<String, dynamic> json) {
    return ServiceRequestAnimalDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['tag'] as String? ?? 'Animal',
      animalType: json['animalType'] as String? ?? '',
      species: json['species'] as String?,
    );
  }
}

class ServiceRequestAssigneeDto {
  const ServiceRequestAssigneeDto({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory ServiceRequestAssigneeDto.fromJson(Map<String, dynamic> json) {
    return ServiceRequestAssigneeDto(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
    );
  }
}

class ServiceRequestDto {
  const ServiceRequestDto({
    required this.id,
    required this.status,
    required this.serviceType,
    required this.problemOrSymptom,
    this.description,
    this.locationText,
    this.preferredTime,
    this.scheduledStart,
    this.scheduledEnd,
    this.serviceCategory,
    this.animal,
    this.assignedDoctor,
    this.assignedTechnician,
    this.submittedAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.createdAt,
  });

  final String id;
  final ServiceRequestStatus status;
  final String serviceType;
  final String problemOrSymptom;
  final String? description;
  final String? locationText;
  final String? preferredTime;
  final String? scheduledStart;
  final String? scheduledEnd;
  final ServiceRequestCategoryDto? serviceCategory;
  final ServiceRequestAnimalDto? animal;
  final ServiceRequestAssigneeDto? assignedDoctor;
  final ServiceRequestAssigneeDto? assignedTechnician;
  final String? submittedAt;
  final String? assignedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? cancelReason;
  final String? createdAt;

  String? get assigneeName =>
      assignedDoctor?.displayName ?? assignedTechnician?.displayName;

  factory ServiceRequestDto.fromJson(Map<String, dynamic> json) {
    return ServiceRequestDto(
      id: json['id'] as String,
      status: ServiceRequestStatus.fromApi(json['status'] as String? ?? ''),
      serviceType: json['serviceType'] as String? ?? '',
      problemOrSymptom: json['problemOrSymptom'] as String? ?? '',
      description: json['description'] as String?,
      locationText: json['locationText'] as String?,
      preferredTime: json['preferredTime'] as String?,
      scheduledStart: json['scheduledStart'] as String?,
      scheduledEnd: json['scheduledEnd'] as String?,
      serviceCategory: json['serviceCategory'] is Map<String, dynamic>
          ? ServiceRequestCategoryDto.fromJson(
              json['serviceCategory'] as Map<String, dynamic>,
            )
          : null,
      animal: json['animal'] is Map<String, dynamic>
          ? ServiceRequestAnimalDto.fromJson(
              json['animal'] as Map<String, dynamic>,
            )
          : null,
      assignedDoctor: json['assignedDoctor'] is Map<String, dynamic>
          ? ServiceRequestAssigneeDto.fromJson(
              json['assignedDoctor'] as Map<String, dynamic>,
            )
          : null,
      assignedTechnician: json['assignedTechnician'] is Map<String, dynamic>
          ? ServiceRequestAssigneeDto.fromJson(
              json['assignedTechnician'] as Map<String, dynamic>,
            )
          : null,
      submittedAt: json['submittedAt'] as String?,
      assignedAt: json['assignedAt'] as String?,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      cancelReason: json['cancelReason'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class ServiceRequestListResultDto {
  const ServiceRequestListResultDto({
    required this.requests,
    required this.total,
  });

  final List<ServiceRequestDto> requests;
  final int total;
}

class CreateServiceRequestInput {
  const CreateServiceRequestInput({
    required this.animalId,
    required this.serviceCategoryId,
    required this.serviceType,
    required this.problemOrSymptom,
    this.description,
    this.villageId,
    this.locationText,
    this.preferredTime,
  });

  final String animalId;
  final String serviceCategoryId;
  final String serviceType;
  final String problemOrSymptom;
  final String? description;
  final String? villageId;
  final String? locationText;
  final String? preferredTime;

  Map<String, dynamic> toJson() {
    return {
      'animalId': animalId,
      'serviceCategoryId': serviceCategoryId,
      'serviceType': serviceType,
      'problemOrSymptom': problemOrSymptom,
      if (description != null) 'description': description,
      if (villageId != null) 'villageId': villageId,
      if (locationText != null) 'locationText': locationText,
      if (preferredTime != null) 'preferredTime': preferredTime,
    };
  }
}

class ServiceRequestTimelineEventDto {
  const ServiceRequestTimelineEventDto({
    required this.id,
    required this.eventType,
    this.actorRole,
    this.actorDisplayName,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final String? actorRole;
  final String? actorDisplayName;
  final String? note;
  final String createdAt;

  factory ServiceRequestTimelineEventDto.fromJson(Map<String, dynamic> json) {
    return ServiceRequestTimelineEventDto(
      id: json['id'] as String,
      eventType: json['eventType'] as String? ?? '',
      actorRole: json['actorRole'] as String?,
      actorDisplayName: json['actorDisplayName'] as String?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class ServiceRequestTimelineDto {
  const ServiceRequestTimelineDto({
    required this.requestId,
    required this.events,
  });

  final String requestId;
  final List<ServiceRequestTimelineEventDto> events;

  factory ServiceRequestTimelineDto.fromJson(Map<String, dynamic> json) {
    return ServiceRequestTimelineDto(
      requestId: json['requestId'] as String? ?? '',
      events: (json['events'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ServiceRequestTimelineEventDto.fromJson)
          .toList(),
    );
  }
}
