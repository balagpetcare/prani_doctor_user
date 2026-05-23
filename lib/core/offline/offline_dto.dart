/// Offline sync DTOs — mirrors foundation `{ success, data }` payloads.
library;

enum OfflineConnectivityMode { online, degraded, offline }

enum OfflineSyncEntityType {
  authSnapshot,
  areaData,
  caseDraft,
  voiceDraft,
  profile,
  offlineLead,
}

enum OfflineSyncOperation { upsert, delete }

enum OfflineSyncItemStatus { pending, syncing, synced, failed, dead, conflict }

enum OfflineQueueUxState { queued, syncing, failed, resolved }

class SyncStatusDto {
  const SyncStatusDto({
    required this.sessionId,
    required this.connectivityMode,
    required this.manualOverride,
    required this.pendingCount,
    required this.deadCount,
    required this.conflictCount,
    this.lastSyncAt,
    this.lastClientSnapshotAt,
    required this.cacheTtlMs,
  });

  final String sessionId;
  final OfflineConnectivityMode connectivityMode;
  final bool manualOverride;
  final int pendingCount;
  final int deadCount;
  final int conflictCount;
  final String? lastSyncAt;
  final String? lastClientSnapshotAt;
  final Map<String, int> cacheTtlMs;

  factory SyncStatusDto.fromJson(Map<String, dynamic> json) {
    return SyncStatusDto(
      sessionId: json['sessionId'] as String? ?? '',
      connectivityMode: parseConnectivity(json['connectivityMode'] as String?),
      manualOverride: json['manualOverride'] as bool? ?? false,
      pendingCount: json['pendingCount'] as int? ?? 0,
      deadCount: json['deadCount'] as int? ?? 0,
      conflictCount: json['conflictCount'] as int? ?? 0,
      lastSyncAt: json['lastSyncAt'] as String?,
      lastClientSnapshotAt: json['lastClientSnapshotAt'] as String?,
      cacheTtlMs: (json['cacheTtlMs'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }
}

class SyncItemInput {
  const SyncItemInput({
    required this.idempotencyKey,
    required this.entityType,
    required this.payload,
    required this.clientSequence,
    this.operation = OfflineSyncOperation.upsert,
    this.clientVersion,
    this.serverVersion,
  });

  final String idempotencyKey;
  final OfflineSyncEntityType entityType;
  final Map<String, dynamic> payload;
  final int clientSequence;
  final OfflineSyncOperation operation;
  final String? clientVersion;
  final String? serverVersion;

  Map<String, dynamic> toJson() => {
    'idempotencyKey': idempotencyKey,
    'entityType': entityTypeToApi(entityType),
    'operation': operation == OfflineSyncOperation.delete ? 'DELETE' : 'UPSERT',
    'payload': payload,
    'clientSequence': clientSequence,
    if (clientVersion != null) 'clientVersion': clientVersion,
    if (serverVersion != null) 'serverVersion': serverVersion,
  };
}

class SyncItemResultDto {
  const SyncItemResultDto({
    required this.idempotencyKey,
    required this.status,
    this.serverEntityId,
    required this.conflict,
    this.resolution,
    this.error,
  });

  final String idempotencyKey;
  final OfflineSyncItemStatus status;
  final String? serverEntityId;
  final bool conflict;
  final String? resolution;
  final String? error;

  factory SyncItemResultDto.fromJson(Map<String, dynamic> json) {
    return SyncItemResultDto(
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      status: parseSyncStatus(json['status'] as String?),
      serverEntityId: json['serverEntityId'] as String?,
      conflict: json['conflict'] as bool? ?? false,
      resolution: json['resolution'] as String?,
      error: json['error'] as String?,
    );
  }
}

class SyncResponseDto {
  const SyncResponseDto({
    required this.sessionId,
    required this.mode,
    required this.processed,
    required this.synced,
    required this.failed,
    required this.conflicts,
    required this.results,
  });

  final String sessionId;
  final String mode;
  final int processed;
  final int synced;
  final int failed;
  final int conflicts;
  final List<SyncItemResultDto> results;

  factory SyncResponseDto.fromJson(Map<String, dynamic> json) {
    return SyncResponseDto(
      sessionId: json['sessionId'] as String? ?? '',
      mode: json['mode'] as String? ?? 'foreground',
      processed: json['processed'] as int? ?? 0,
      synced: json['synced'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      conflicts: json['conflicts'] as int? ?? 0,
      results: (json['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SyncItemResultDto.fromJson)
          .toList(),
    );
  }
}

class SyncRetryItemDto {
  const SyncRetryItemDto({
    required this.idempotencyKey,
    required this.status,
    required this.attemptCount,
    this.nextRetryAt,
  });

  final String idempotencyKey;
  final OfflineSyncItemStatus status;
  final int attemptCount;
  final String? nextRetryAt;

  factory SyncRetryItemDto.fromJson(Map<String, dynamic> json) {
    return SyncRetryItemDto(
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      status: parseSyncStatus(json['status'] as String?),
      attemptCount: json['attemptCount'] as int? ?? 0,
      nextRetryAt: json['nextRetryAt'] as String?,
    );
  }
}

class SyncRetryResponseDto {
  const SyncRetryResponseDto({
    required this.retried,
    required this.paused,
    required this.items,
  });

  final int retried;
  final bool paused;
  final List<SyncRetryItemDto> items;

  factory SyncRetryResponseDto.fromJson(Map<String, dynamic> json) {
    return SyncRetryResponseDto(
      retried: json['retried'] as int? ?? 0,
      paused: json['paused'] as bool? ?? false,
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SyncRetryItemDto.fromJson)
          .toList(),
    );
  }
}

class OfflineLeadDraftDto {
  const OfflineLeadDraftDto({
    required this.clientLeadId,
    required this.phone,
    this.name,
    required this.status,
    this.serverLeadId,
  });

  final String clientLeadId;
  final String phone;
  final String? name;
  final String status;
  final String? serverLeadId;

  factory OfflineLeadDraftDto.fromJson(Map<String, dynamic> json) {
    return OfflineLeadDraftDto(
      clientLeadId: json['clientLeadId'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String?,
      status: json['status'] as String? ?? '',
      serverLeadId: json['serverLeadId'] as String?,
    );
  }
}

class OfflineQueueItemDto {
  const OfflineQueueItemDto({
    required this.id,
    required this.idempotencyKey,
    required this.entityType,
    required this.status,
    required this.attemptCount,
    this.lastError,
    this.nextRetryAt,
    required this.clientSequence,
    this.serverEntityId,
    required this.createdAt,
    this.leadDraft,
    this.uxState,
  });

  final String id;
  final String idempotencyKey;
  final OfflineSyncEntityType entityType;
  final OfflineSyncItemStatus status;
  final int attemptCount;
  final String? lastError;
  final String? nextRetryAt;
  final int clientSequence;
  final String? serverEntityId;
  final String createdAt;
  final OfflineLeadDraftDto? leadDraft;
  final OfflineQueueUxState? uxState;

  factory OfflineQueueItemDto.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItemDto(
      id: json['id'] as String? ?? '',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      entityType: parseEntityType(json['entityType'] as String?),
      status: parseSyncStatus(json['status'] as String?),
      attemptCount: json['attemptCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      nextRetryAt: json['nextRetryAt'] as String?,
      clientSequence: json['clientSequence'] as int? ?? 0,
      serverEntityId: json['serverEntityId'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      leadDraft: json['leadDraft'] is Map<String, dynamic>
          ? OfflineLeadDraftDto.fromJson(
              json['leadDraft'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class OfflineQueueDto {
  const OfflineQueueDto({
    required this.queued,
    required this.syncing,
    required this.failed,
    required this.resolved,
    required this.total,
  });

  final List<OfflineQueueItemDto> queued;
  final List<OfflineQueueItemDto> syncing;
  final List<OfflineQueueItemDto> failed;
  final List<OfflineQueueItemDto> resolved;
  final int total;

  factory OfflineQueueDto.fromJson(Map<String, dynamic> json) {
    List<OfflineQueueItemDto> parseList(String key) {
      return (json[key] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OfflineQueueItemDto.fromJson)
          .toList();
    }

    return OfflineQueueDto(
      queued: parseList('queued'),
      syncing: parseList('syncing'),
      failed: parseList('failed'),
      resolved: parseList('resolved'),
      total: json['total'] as int? ?? 0,
    );
  }
}

OfflineConnectivityMode parseConnectivity(String? raw) {
  switch (raw) {
    case 'DEGRADED':
      return OfflineConnectivityMode.degraded;
    case 'OFFLINE':
      return OfflineConnectivityMode.offline;
    default:
      return OfflineConnectivityMode.online;
  }
}

String connectivityToApi(OfflineConnectivityMode mode) {
  switch (mode) {
    case OfflineConnectivityMode.degraded:
      return 'DEGRADED';
    case OfflineConnectivityMode.offline:
      return 'OFFLINE';
    case OfflineConnectivityMode.online:
      return 'ONLINE';
  }
}

OfflineSyncEntityType parseEntityType(String? raw) {
  switch (raw) {
    case 'AUTH_SNAPSHOT':
      return OfflineSyncEntityType.authSnapshot;
    case 'AREA_DATA':
      return OfflineSyncEntityType.areaData;
    case 'CASE_DRAFT':
      return OfflineSyncEntityType.caseDraft;
    case 'VOICE_DRAFT':
      return OfflineSyncEntityType.voiceDraft;
    case 'PROFILE':
      return OfflineSyncEntityType.profile;
    case 'OFFLINE_LEAD':
      return OfflineSyncEntityType.offlineLead;
    default:
      return OfflineSyncEntityType.offlineLead;
  }
}

String entityTypeToApi(OfflineSyncEntityType type) {
  switch (type) {
    case OfflineSyncEntityType.authSnapshot:
      return 'AUTH_SNAPSHOT';
    case OfflineSyncEntityType.areaData:
      return 'AREA_DATA';
    case OfflineSyncEntityType.caseDraft:
      return 'CASE_DRAFT';
    case OfflineSyncEntityType.voiceDraft:
      return 'VOICE_DRAFT';
    case OfflineSyncEntityType.profile:
      return 'PROFILE';
    case OfflineSyncEntityType.offlineLead:
      return 'OFFLINE_LEAD';
  }
}

OfflineSyncItemStatus parseSyncStatus(String? raw) {
  switch (raw) {
    case 'SYNCING':
      return OfflineSyncItemStatus.syncing;
    case 'SYNCED':
      return OfflineSyncItemStatus.synced;
    case 'FAILED':
      return OfflineSyncItemStatus.failed;
    case 'DEAD':
      return OfflineSyncItemStatus.dead;
    case 'CONFLICT':
      return OfflineSyncItemStatus.conflict;
    default:
      return OfflineSyncItemStatus.pending;
  }
}
