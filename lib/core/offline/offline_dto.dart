/// Offline sync DTOs — mirrors foundation `{ success, data }` payloads.

enum OfflineConnectivityMode { online, degraded, offline }

enum OfflineSyncEntityType {
  authSnapshot,
  areaData,
  caseDraft,
  voiceDraft,
  profile,
  offlineLead,
}

enum OfflineSyncItemStatus {
  pending,
  syncing,
  synced,
  failed,
  dead,
  conflict,
}

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
      sessionId: json['sessionId'] as String,
      connectivityMode: _connectivity(json['connectivityMode'] as String),
      manualOverride: json['manualOverride'] as bool? ?? false,
      pendingCount: json['pendingCount'] as int? ?? 0,
      deadCount: json['deadCount'] as int? ?? 0,
      conflictCount: json['conflictCount'] as int? ?? 0,
      lastSyncAt: json['lastSyncAt'] as String?,
      lastClientSnapshotAt: json['lastClientSnapshotAt'] as String?,
      cacheTtlMs: (json['cacheTtlMs'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as int)),
    );
  }
}

class SyncItemInput {
  const SyncItemInput({
    required this.idempotencyKey,
    required this.entityType,
    required this.payload,
    required this.clientSequence,
    this.clientVersion,
    this.serverVersion,
  });

  final String idempotencyKey;
  final OfflineSyncEntityType entityType;
  final Map<String, dynamic> payload;
  final int clientSequence;
  final String? clientVersion;
  final String? serverVersion;

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'entityType': _entityType(entityType),
        'payload': payload,
        'clientSequence': clientSequence,
        if (clientVersion != null) 'clientVersion': clientVersion,
        if (serverVersion != null) 'serverVersion': serverVersion,
      };
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
  final OfflineQueueUxState? uxState;
}

OfflineConnectivityMode _connectivity(String raw) {
  switch (raw) {
    case 'DEGRADED':
      return OfflineConnectivityMode.degraded;
    case 'OFFLINE':
      return OfflineConnectivityMode.offline;
    default:
      return OfflineConnectivityMode.online;
  }
}

String _entityType(OfflineSyncEntityType type) {
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
