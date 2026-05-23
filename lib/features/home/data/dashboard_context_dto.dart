/// Dashboard routing context from `GET /api/mobile/profile/dashboard-context`.
import '../../../core/util/safe_numeric.dart';

enum DashboardType { general, aiTechnician, doctor }

DashboardType dashboardTypeFromApiString(Object? raw) {
  if (raw is! String) return DashboardType.general;
  switch (raw.trim()) {
    case 'GENERAL':
      return DashboardType.general;
    case 'AI_TECHNICIAN':
      return DashboardType.aiTechnician;
    case 'DOCTOR':
      return DashboardType.doctor;
    case 'AI_TECHNICIAN_PENDING':
    case 'AI_TECHNICIAN_REJECTED':
    case 'AI_TECHNICIAN_SUSPENDED':
      return DashboardType.general;
    default:
      return DashboardType.general;
  }
}

class DashboardContextRating {
  const DashboardContextRating({this.average, required this.count});

  final double? average;
  final int count;

  factory DashboardContextRating.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const DashboardContextRating(average: null, count: 0);
    }
    final avg = json['average'];
    final c = json['count'];
    return DashboardContextRating(
      average: avg is num
          ? avg.toDouble()
          : (avg is String ? double.tryParse(avg) : null),
      count: c is int ? c : int.tryParse('$c') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (average != null) 'average': average,
    'count': count,
  };
}

class DashboardContextUser {
  const DashboardContextUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String? avatarUrl;

  factory DashboardContextUser.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const DashboardContextUser(id: '', name: '', phone: '', email: '');
    }
    return DashboardContextUser(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}'.trim(),
      phone: '${json['phone'] ?? ''}'.trim(),
      email: '${json['email'] ?? ''}'.trim(),
      avatarUrl: _nullableString(json['avatarUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };
}

class FarmSummary {
  const FarmSummary({
    required this.animalCount,
    required this.activeAnimalCount,
    this.primaryVillageId,
    this.primaryVillageLabelBn,
  });

  final int animalCount;
  final int activeAnimalCount;
  final String? primaryVillageId;
  final String? primaryVillageLabelBn;

  /// Backend does not expose farm count yet — derive from primary location.
  int get totalFarms =>
      (primaryVillageId != null && primaryVillageId!.isNotEmpty) ? 1 : 0;

  factory FarmSummary.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const FarmSummary(animalCount: 0, activeAnimalCount: 0);
    }
    return FarmSummary(
      animalCount: _int(json['animalCount']),
      activeAnimalCount: _int(json['activeAnimalCount']),
      primaryVillageId: _nullableString(json['primaryVillageId']),
      primaryVillageLabelBn: _nullableString(json['primaryVillageLabelBn']),
    );
  }

  Map<String, dynamic> toJson() => {
    'animalCount': animalCount,
    'activeAnimalCount': activeAnimalCount,
    if (primaryVillageId != null) 'primaryVillageId': primaryVillageId,
    if (primaryVillageLabelBn != null)
      'primaryVillageLabelBn': primaryVillageLabelBn,
  };
}

class DashboardContextAiTechnician {
  const DashboardContextAiTechnician({
    required this.id,
    required this.status,
    this.displayName,
    required this.serviceAreas,
    required this.todayRequestCount,
    required this.pendingRequestCount,
    required this.completedServiceCount,
    required this.rating,
  });

  final String id;
  final String status;
  final String? displayName;
  final List<String> serviceAreas;
  final int todayRequestCount;
  final int pendingRequestCount;
  final int completedServiceCount;
  final DashboardContextRating rating;

  factory DashboardContextAiTechnician.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const DashboardContextAiTechnician(
        id: '',
        status: '',
        serviceAreas: [],
        todayRequestCount: 0,
        pendingRequestCount: 0,
        completedServiceCount: 0,
        rating: DashboardContextRating(average: null, count: 0),
      );
    }
    final areas = json['serviceAreas'];
    final list = <String>[];
    if (areas is List) {
      for (final e in areas) {
        if (e is String && e.trim().isNotEmpty) list.add(e.trim());
      }
    }
    return DashboardContextAiTechnician(
      id: '${json['id'] ?? ''}',
      status: '${json['status'] ?? ''}',
      displayName: _nullableString(json['displayName']),
      serviceAreas: list,
      todayRequestCount: _int(json['todayRequestCount']),
      pendingRequestCount: _int(json['pendingRequestCount']),
      completedServiceCount: _int(json['completedServiceCount']),
      rating: DashboardContextRating.fromJson(json['rating']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    if (displayName != null) 'displayName': displayName,
    'serviceAreas': serviceAreas,
    'todayRequestCount': todayRequestCount,
    'pendingRequestCount': pendingRequestCount,
    'completedServiceCount': completedServiceCount,
    'rating': rating.toJson(),
  };
}

class DashboardContext {
  const DashboardContext({
    required this.dashboardType,
    required this.user,
    this.farmSummary,
    this.aiTechnician,
    this.hasAiTechnicianApplication = false,
    this.aiTechnicianApplicationStatus,
    this.fromCache = false,
  });

  final DashboardType dashboardType;
  final DashboardContextUser user;
  final FarmSummary? farmSummary;
  final DashboardContextAiTechnician? aiTechnician;
  final bool hasAiTechnicianApplication;
  final String? aiTechnicianApplicationStatus;
  final bool fromCache;

  bool get isEmpty =>
      user.id.isEmpty && (farmSummary == null || farmSummary!.animalCount == 0);

  DashboardContext copyWith({bool? fromCache}) {
    return DashboardContext(
      dashboardType: dashboardType,
      user: user,
      farmSummary: farmSummary,
      aiTechnician: aiTechnician,
      hasAiTechnicianApplication: hasAiTechnicianApplication,
      aiTechnicianApplicationStatus: aiTechnicianApplicationStatus,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory DashboardContext.fromJson(Object? json, {bool fromCache = false}) {
    if (json is! Map<String, dynamic>) {
      return const DashboardContext(
        dashboardType: DashboardType.general,
        user: DashboardContextUser(id: '', name: '', phone: '', email: ''),
      );
    }
    final type = dashboardTypeFromApiString(json['dashboardType']);
    final rawDash = json['dashboardType'];
    final rawDashStr = rawDash is String ? rawDash.trim() : '';

    var hasAi = _boolField(json['hasAiTechnicianApplication']);
    if (!hasAi &&
        (rawDashStr == 'AI_TECHNICIAN_PENDING' ||
            rawDashStr == 'AI_TECHNICIAN_REJECTED' ||
            rawDashStr == 'AI_TECHNICIAN_SUSPENDED')) {
      hasAi = true;
    }

    final aiRaw = json['aiTechnician'];
    final statusRaw = json['aiTechnicianApplicationStatus'];
    String? appStatusStr = statusRaw is String && statusRaw.trim().isNotEmpty
        ? statusRaw.trim()
        : null;
    if (appStatusStr == null && rawDashStr == 'AI_TECHNICIAN_REJECTED') {
      appStatusStr = 'REJECTED';
    } else if (appStatusStr == null &&
        rawDashStr == 'AI_TECHNICIAN_SUSPENDED') {
      appStatusStr = 'SUSPENDED';
    } else if (appStatusStr == null && rawDashStr == 'AI_TECHNICIAN_PENDING') {
      appStatusStr = 'UNDER_REVIEW';
    }

    final farmRaw = json['farmSummary'];
    return DashboardContext(
      dashboardType: type,
      user: DashboardContextUser.fromJson(json['user']),
      farmSummary: farmRaw == null ? null : FarmSummary.fromJson(farmRaw),
      aiTechnician: aiRaw == null
          ? null
          : DashboardContextAiTechnician.fromJson(aiRaw),
      hasAiTechnicianApplication: hasAi,
      aiTechnicianApplicationStatus: appStatusStr,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'dashboardType': _dashboardTypeApiValue(dashboardType),
    'user': user.toJson(),
    if (farmSummary != null) 'farmSummary': farmSummary!.toJson(),
    if (aiTechnician != null) 'aiTechnician': aiTechnician!.toJson(),
    'hasAiTechnicianApplication': hasAiTechnicianApplication,
    if (aiTechnicianApplicationStatus != null)
      'aiTechnicianApplicationStatus': aiTechnicianApplicationStatus,
  };
}

String _dashboardTypeApiValue(DashboardType type) {
  switch (type) {
    case DashboardType.general:
      return 'GENERAL';
    case DashboardType.aiTechnician:
      return 'AI_TECHNICIAN';
    case DashboardType.doctor:
      return 'DOCTOR';
  }
}

bool _boolField(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) {
    final s = raw.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

String? _nullableString(Object? v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

int _int(Object? v) {
  if (v is int) return v;
  if (v is num) return safeInt(v);
  return int.tryParse('$v') ?? 0;
}
