import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/offline/network_errors.dart';
import '../../../core/offline/offline_dto.dart';
import '../../../core/session/session_auth.dart';
import '../../../core/session/session_controller.dart';
import '../../profile/data/profile_api_paths.dart';
import '../../feed/data/feed_api_paths.dart';
import '../../finance/data/finance_api_paths.dart';
import '../../health/data/health_api_paths.dart';
import '../../vaccine/data/vaccine_api_paths.dart';
import '../../treatment/data/treatment_api_paths.dart';
import '../../support/data/support_api_paths.dart';
import '../../settings/data/settings_api_paths.dart';
import '../../ai/data/ai_api_paths.dart';
import '../../milk/data/milk_api_paths.dart';
import '../../batches/data/batch_api_paths.dart';
import '../../animals/data/animal_api_paths.dart';
import '../../service_requests/data/service_request_api_paths.dart';
import '../../../core/providers/provider_stability.dart';
import '../../shared/upload/services/upload_service.dart';
import '../offline_providers.dart';
import 'connectivity_service.dart';
import 'sync_invalidation.dart';
import 'offline_repository.dart';
import 'outbox_item.dart';
import 'outbox_service.dart';

const _backgroundSyncInterval = Duration(seconds: 60);

class SyncCoordinator {
  SyncCoordinator(this._ref);

  final Ref _ref;
  Timer? _backgroundTimer;
  bool _paused = false;
  bool _syncing = false;
  final _uxController = StreamController<OfflineQueueUxState>.broadcast();
  final _invalidateDebouncer = RefreshDebouncer(
    delay: const Duration(seconds: 1),
  );
  final Set<SyncDomain> _pendingInvalidations = {};

  Stream<OfflineQueueUxState> get uxStateStream => _uxController.stream;

  Future<void> initialize() async {
    _backgroundTimer?.cancel();
    if (_ref.read(appEnvProvider).isDev) {
      if (kDebugMode) {
        debugPrint('[SYNC] background server queue disabled in dev');
      }
      return;
    }
    _backgroundTimer = Timer.periodic(_backgroundSyncInterval, (_) {
      unawaited(syncNow(background: true));
    });
  }

  void dispose() {
    _backgroundTimer?.cancel();
    _invalidateDebouncer.dispose();
    _uxController.close();
  }

  Future<void> onConnectivityRestored() => syncNow(background: true);

  Future<void> syncNow({
    bool background = false,
    bool foreground = true,
  }) async {
    if (_paused || _syncing) return;
    if (!SessionAuth.canCallProtectedApis(
      _ref.read(sessionControllerProvider),
    )) {
      return;
    }

    final connectivity = _ref.read(connectivityServiceProvider);
    if (!isOnlineMode(connectivity.currentMode)) return;

    _syncing = true;
    _uxController.add(OfflineQueueUxState.syncing);
    final affectedDomains = <SyncDomain>{};
    try {
      affectedDomains.addAll(await _drainLocalOutbox());
      if (!_ref.read(appEnvProvider).isDev) {
        await _syncServerQueue(background: background);
      } else if (kDebugMode) {
        debugPrint('[SYNC] skipped /api/sync in dev');
      }
    } finally {
      _syncing = false;
      final pending = await _ref.read(outboxServiceProvider).pendingCount();
      _uxController.add(
        pending > 0 ? OfflineQueueUxState.failed : OfflineQueueUxState.resolved,
      );
      if (affectedDomains.isNotEmpty) {
        _scheduleInvalidation(affectedDomains);
      } else {
        _ref.invalidate(localOutboxCountProvider);
        _ref.invalidate(offlineSyncStatusProvider);
      }
    }
  }

  void _scheduleInvalidation(Set<SyncDomain> domains) {
    _pendingInvalidations.addAll(domains);
    _invalidateDebouncer.schedule(() async {
      final batch = Set<SyncDomain>.from(_pendingInvalidations);
      _pendingInvalidations.clear();
      ProviderLog.provider('sync invalidate domains=$batch');
      invalidateSyncDomains(_ref, batch);
    });
  }

  Future<void> setPaused(bool paused) async {
    _paused = paused;
    if (paused) {
      await _ref.read(offlineRepositoryProvider).retrySync(pause: true);
    } else {
      await _ref.read(offlineRepositoryProvider).retrySync(resume: true);
      await syncNow(background: true);
    }
  }

  Future<void> retryDead({bool includeDead = true}) async {
    await _ref
        .read(offlineRepositoryProvider)
        .retrySync(includeDead: includeDead);
    await syncNow(foreground: true);
  }

  Future<Set<SyncDomain>> _drainLocalOutbox() async {
    final outbox = _ref.read(outboxServiceProvider);
    final dio = _ref.read(dioProvider);
    final items = await outbox.listReady();
    final affected = <SyncDomain>{};

    for (final item in items) {
      try {
        switch (item.kind) {
          case OutboxKind.serviceRequest:
            await postJson(
              dio,
              ServiceRequestApiPaths.serviceRequests,
              item.payload,
            );
          case OutboxKind.profilePatch:
            await patchJson(dio, ProfileApiPaths.me, item.payload);
          case OutboxKind.animalCreate:
            await postJson(dio, AnimalApiPaths.animals, item.payload);
          case OutboxKind.animalPatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing animal id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, AnimalApiPaths.animal(id), body);
          case OutboxKind.batchCreate:
            await postJson(dio, BatchApiPaths.batches, item.payload);
          case OutboxKind.batchPatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing batch id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, BatchApiPaths.batch(id), body);
          case OutboxKind.batchMove:
            final fromId = item.payload['fromBatchId'] as String?;
            if (fromId == null) {
              throw const AppException(message: 'Missing batch id');
            }
            await postJson(dio, BatchApiPaths.move(fromId), item.payload);
          case OutboxKind.batchMerge:
            await postJson(dio, BatchApiPaths.merge, item.payload);
          case OutboxKind.milkCreate:
            await postJson(dio, MilkApiPaths.milk, item.payload);
          case OutboxKind.milkPatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing milk record id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, MilkApiPaths.record(id), body);
          case OutboxKind.milkDelete:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing milk record id');
            }
            await deleteJson(dio, MilkApiPaths.record(id));
          case OutboxKind.feedCreate:
            await postJson(dio, FeedApiPaths.feeds, item.payload);
          case OutboxKind.feedPatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing feed record id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, FeedApiPaths.record(id), body);
          case OutboxKind.feedDelete:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing feed record id');
            }
            await deleteJson(dio, FeedApiPaths.record(id));
          case OutboxKind.financeExpenseCreate:
            await postJson(dio, FinanceApiPaths.expenses, item.payload);
          case OutboxKind.financeExpensePatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing expense id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, FinanceApiPaths.expense(id), body);
          case OutboxKind.financeExpenseDelete:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing expense id');
            }
            await deleteJson(dio, FinanceApiPaths.expense(id));
          case OutboxKind.financeIncomeCreate:
            await postJson(dio, FinanceApiPaths.income, item.payload);
          case OutboxKind.financeIncomePatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing income id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, FinanceApiPaths.incomeRecord(id), body);
          case OutboxKind.financeIncomeDelete:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing income id');
            }
            await deleteJson(dio, FinanceApiPaths.incomeRecord(id));
          case OutboxKind.healthCreate:
            await postJson(dio, HealthApiPaths.history, item.payload);
          case OutboxKind.healthPatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing health record id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, HealthApiPaths.record(id), body);
          case OutboxKind.healthDelete:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing health record id');
            }
            await deleteJson(dio, HealthApiPaths.record(id));
          case OutboxKind.vaccineCreate:
            await postJson(dio, VaccineApiPaths.vaccines, item.payload);
          case OutboxKind.vaccinePatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing vaccine record id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, VaccineApiPaths.record(id), body);
          case OutboxKind.vaccineDelete:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing vaccine record id');
            }
            await deleteJson(dio, VaccineApiPaths.record(id));
          case OutboxKind.treatmentCreate:
            await postJson(dio, TreatmentApiPaths.treatments, item.payload);
          case OutboxKind.treatmentPatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing treatment record id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, TreatmentApiPaths.record(id), body);
          case OutboxKind.treatmentDelete:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing treatment record id');
            }
            await deleteJson(dio, TreatmentApiPaths.record(id));
          case OutboxKind.supportTicketCreate:
            await _syncSupportTicketCreate(dio, item);
          case OutboxKind.supportTicketReply:
            await _syncSupportTicketReply(dio, item);
          case OutboxKind.supportTicketPatch:
            final id = item.payload['id'] as String?;
            if (id == null) {
              throw const AppException(message: 'Missing support ticket id');
            }
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, SupportApiPaths.ticket(id), body);
          case OutboxKind.aiChatMessage:
            await postJson(dio, AiApiPaths.chat, item.payload);
          case OutboxKind.settingsSync:
            await postJson(dio, SettingsApiPaths.sync, item.payload);
          case OutboxKind.offlineLead:
            await _syncOfflineLeadItem(item);
        }
        await outbox.remove(item.idempotencyKey);
        final domain = syncDomainForOutboxKind(item.kind);
        if (domain != null) affected.add(domain);
      } on AppException catch (e) {
        await _markOutboxFailure(outbox, item, e.message);
      } catch (e) {
        await _markOutboxFailure(outbox, item, e.toString());
      }
    }
    return affected;
  }

  Future<void> _syncSupportTicketCreate(Dio dio, OutboxItem item) async {
    final body = Map<String, dynamic>.from(item.payload);
    final localPaths =
        (body.remove('attachmentLocalPaths') as List<dynamic>? ?? [])
            .whereType<String>()
            .toList();
    final fileIds = await _uploadSupportLocalPaths(dio, localPaths);
    if (fileIds.isNotEmpty) body['attachmentFileIds'] = fileIds;
    await postJson(dio, SupportApiPaths.tickets, body);
  }

  Future<void> _syncSupportTicketReply(Dio dio, OutboxItem item) async {
    final ticketId = item.payload['ticketId'] as String?;
    if (ticketId == null) {
      throw const AppException(message: 'Missing support ticket id');
    }
    final body = Map<String, dynamic>.from(item.payload)..remove('ticketId');
    final localPaths =
        (body.remove('attachmentLocalPaths') as List<dynamic>? ?? [])
            .whereType<String>()
            .toList();
    final fileIds = await _uploadSupportLocalPaths(dio, localPaths);
    if (fileIds.isNotEmpty) body['attachmentFileIds'] = fileIds;
    await postJson(dio, SupportApiPaths.reply(ticketId), body);
  }

  Future<List<String>> _uploadSupportLocalPaths(
    Dio dio,
    List<String> paths,
  ) async {
    final uploads = _ref.read(uploadServiceProvider);
    final ids = <String>[];
    for (final path in paths) {
      final result = await uploads.uploadSupportAttachment(path);
      result.when(
        success: (upload) {
          if (upload.fileId.isNotEmpty) ids.add(upload.fileId);
        },
        failure: (_) {},
      );
    }
    return ids;
  }

  Future<void> _syncOfflineLeadItem(OutboxItem item) async {
    final repo = _ref.read(offlineRepositoryProvider);
    final deviceKey = await _ref
        .read(sessionControllerProvider.notifier)
        .deviceKey();
    final connectivity = _ref.read(connectivityServiceProvider).currentMode;
    final result = await repo.sync(
      deviceId: deviceKey,
      connectivityMode: connectivity,
      mode: 'foreground',
      items: [
        SyncItemInput(
          idempotencyKey: item.idempotencyKey,
          entityType: OfflineSyncEntityType.offlineLead,
          payload: item.payload,
          clientSequence: item.clientSequence,
        ),
      ],
    );
    result.when(
      success: (response) {
        final failed = response.results.any(
          (r) =>
              r.status == OfflineSyncItemStatus.failed ||
              r.status == OfflineSyncItemStatus.dead ||
              r.status == OfflineSyncItemStatus.conflict,
        );
        if (failed) {
          throw AppException(
            message:
                response.results
                    .firstWhere(
                      (r) => r.error != null,
                      orElse: () => response.results.first,
                    )
                    .error ??
                'Lead sync failed',
          );
        }
      },
      failure: (e) => throw e,
    );
  }

  Future<void> _markOutboxFailure(
    OutboxService outbox,
    OutboxItem item,
    String message,
  ) async {
    final nextAttempt = item.attemptCount + 1;
    if (nextAttempt >= offlineMaxAttempts) {
      await outbox.update(
        item.copyWith(
          attemptCount: nextAttempt,
          lastError: message,
          nextRetryAt: null,
        ),
      );
      return;
    }
    final delay = offlineRetryDelay(nextAttempt);
    await outbox.update(
      item.copyWith(
        attemptCount: nextAttempt,
        lastError: message,
        nextRetryAt: DateTime.now().add(delay).toIso8601String(),
      ),
    );
  }

  Future<void> _syncServerQueue({required bool background}) async {
    final repo = _ref.read(offlineRepositoryProvider);
    final deviceKey = await _ref
        .read(sessionControllerProvider.notifier)
        .deviceKey();
    final connectivity = _ref.read(connectivityServiceProvider).currentMode;
    try {
      final result = await repo.sync(
        deviceId: deviceKey,
        connectivityMode: connectivity,
        mode: background ? 'background' : 'foreground',
        items: const [],
      );
      result.when(
        success: (_) {
          if (kDebugMode) debugPrint('[SYNC] server queue ok');
        },
        failure: (error) {
          if (kDebugMode) {
            debugPrint(
              '[SYNC] server queue skipped: ${error.code ?? error.message}',
            );
          }
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[SYNC] server queue error: $e');
    }
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
