import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/network_errors.dart';
import '../../../core/offline/offline_dto.dart';
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
import '../offline_providers.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../health/presentation/health_providers.dart';
import '../../vaccine/presentation/vaccine_providers.dart';
import '../../treatment/presentation/treatment_providers.dart';
import '../../support/presentation/support_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../ai/presentation/ai_providers.dart';
import '../../milk/presentation/milk_providers.dart';
import '../../batches/presentation/batch_providers.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../service_requests/data/service_request_repository.dart';
import 'connectivity_service.dart';
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

  Stream<OfflineQueueUxState> get uxStateStream => _uxController.stream;

  Future<void> initialize() async {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(_backgroundSyncInterval, (_) {
      unawaited(syncNow(background: true));
    });
  }

  void dispose() {
    _backgroundTimer?.cancel();
    _uxController.close();
  }

  Future<void> onConnectivityRestored() => syncNow(background: true);

  Future<void> syncNow({bool background = false, bool foreground = true}) async {
    if (_paused || _syncing) return;
    if (!_ref.read(sessionControllerProvider).isAuthenticated) return;

    final connectivity = _ref.read(connectivityServiceProvider);
    if (!isOnlineMode(connectivity.currentMode)) return;

    _syncing = true;
    _uxController.add(OfflineQueueUxState.syncing);
    try {
      await _drainLocalOutbox();
      await _syncServerQueue(background: background);
    } finally {
      _syncing = false;
      final pending = await _ref.read(outboxServiceProvider).pendingCount();
      _uxController.add(
        pending > 0 ? OfflineQueueUxState.failed : OfflineQueueUxState.resolved,
      );
      _ref.invalidate(localOutboxCountProvider);
      _ref.invalidate(offlineSyncStatusProvider);
      _ref.invalidate(serviceRequestListProvider);
      _ref.invalidate(animalListProvider);
      _ref.invalidate(batchListProvider);
      _ref.invalidate(milkListProvider);
      _ref.invalidate(milkSummaryProvider);
      _ref.invalidate(milkChartsProvider);
      _ref.invalidate(feedListProvider);
      _ref.invalidate(feedCostProvider);
      _ref.invalidate(feedAnalyticsProvider);
      _ref.invalidate(financeExpenseListProvider);
      _ref.invalidate(financeIncomeListProvider);
      _ref.invalidate(financeProfitProvider);
      _ref.invalidate(financeChartsProvider);
      _ref.invalidate(financeReportsProvider);
      _ref.invalidate(healthProvider);
      _ref.invalidate(healthTimelineProvider);
      _ref.invalidate(vaccineProvider);
      _ref.invalidate(vaccineReminderProvider);
      _ref.invalidate(treatmentProvider);
      _ref.invalidate(supportTicketListProvider);
      _ref.invalidate(supportHelpProvider);
      _ref.invalidate(aiChatProvider);
      _ref.invalidate(settingsProvider);
    }
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
    await _ref.read(offlineRepositoryProvider).retrySync(includeDead: includeDead);
    await syncNow(foreground: true);
  }

  Future<void> _drainLocalOutbox() async {
    final outbox = _ref.read(outboxServiceProvider);
    final dio = _ref.read(dioProvider);
    final items = await outbox.listReady();

    for (final item in items) {
      try {
        switch (item.kind) {
          case OutboxKind.serviceRequest:
            await postJson(dio, ServiceRequestApiPaths.serviceRequests, item.payload);
          case OutboxKind.profilePatch:
            await patchJson(dio, ProfileApiPaths.me, item.payload);
          case OutboxKind.animalCreate:
            await postJson(dio, AnimalApiPaths.animals, item.payload);
          case OutboxKind.animalPatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing animal id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, AnimalApiPaths.animal(id), body);
          case OutboxKind.batchCreate:
            await postJson(dio, BatchApiPaths.batches, item.payload);
          case OutboxKind.batchPatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing batch id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, BatchApiPaths.batch(id), body);
          case OutboxKind.batchMove:
            final fromId = item.payload['fromBatchId'] as String?;
            if (fromId == null) throw const AppException(message: 'Missing batch id');
            await postJson(dio, BatchApiPaths.move(fromId), item.payload);
          case OutboxKind.batchMerge:
            await postJson(dio, BatchApiPaths.merge, item.payload);
          case OutboxKind.milkCreate:
            await postJson(dio, MilkApiPaths.milk, item.payload);
          case OutboxKind.milkPatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing milk record id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, MilkApiPaths.record(id), body);
          case OutboxKind.milkDelete:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing milk record id');
            await deleteJson(dio, MilkApiPaths.record(id));
          case OutboxKind.feedCreate:
            await postJson(dio, FeedApiPaths.feeds, item.payload);
          case OutboxKind.feedPatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing feed record id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, FeedApiPaths.record(id), body);
          case OutboxKind.feedDelete:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing feed record id');
            await deleteJson(dio, FeedApiPaths.record(id));
          case OutboxKind.financeExpenseCreate:
            await postJson(dio, FinanceApiPaths.expenses, item.payload);
          case OutboxKind.financeExpensePatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing expense id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, FinanceApiPaths.expense(id), body);
          case OutboxKind.financeExpenseDelete:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing expense id');
            await deleteJson(dio, FinanceApiPaths.expense(id));
          case OutboxKind.financeIncomeCreate:
            await postJson(dio, FinanceApiPaths.income, item.payload);
          case OutboxKind.financeIncomePatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing income id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, FinanceApiPaths.incomeRecord(id), body);
          case OutboxKind.financeIncomeDelete:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing income id');
            await deleteJson(dio, FinanceApiPaths.incomeRecord(id));
          case OutboxKind.healthCreate:
            await postJson(dio, HealthApiPaths.history, item.payload);
          case OutboxKind.healthPatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing health record id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, HealthApiPaths.record(id), body);
          case OutboxKind.healthDelete:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing health record id');
            await deleteJson(dio, HealthApiPaths.record(id));
          case OutboxKind.vaccineCreate:
            await postJson(dio, VaccineApiPaths.vaccines, item.payload);
          case OutboxKind.vaccinePatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing vaccine record id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, VaccineApiPaths.record(id), body);
          case OutboxKind.vaccineDelete:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing vaccine record id');
            await deleteJson(dio, VaccineApiPaths.record(id));
          case OutboxKind.treatmentCreate:
            await postJson(dio, TreatmentApiPaths.treatments, item.payload);
          case OutboxKind.treatmentPatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing treatment record id');
            final body = Map<String, dynamic>.from(item.payload)..remove('id');
            await patchJson(dio, TreatmentApiPaths.record(id), body);
          case OutboxKind.treatmentDelete:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing treatment record id');
            await deleteJson(dio, TreatmentApiPaths.record(id));
          case OutboxKind.supportTicketCreate:
            await _syncSupportTicketCreate(dio, item);
          case OutboxKind.supportTicketReply:
            await _syncSupportTicketReply(dio, item);
          case OutboxKind.supportTicketPatch:
            final id = item.payload['id'] as String?;
            if (id == null) throw const AppException(message: 'Missing support ticket id');
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
      } on AppException catch (e) {
        await _markOutboxFailure(outbox, item, e.message);
      } catch (e) {
        await _markOutboxFailure(outbox, item, e.toString());
      }
    }
  }

  Future<void> _syncSupportTicketCreate(Dio dio, OutboxItem item) async {
    final body = Map<String, dynamic>.from(item.payload);
    final localPaths = (body.remove('attachmentLocalPaths') as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final fileIds = await _uploadSupportLocalPaths(dio, localPaths);
    if (fileIds.isNotEmpty) body['attachmentFileIds'] = fileIds;
    await postJson(dio, SupportApiPaths.tickets, body);
  }

  Future<void> _syncSupportTicketReply(Dio dio, OutboxItem item) async {
    final ticketId = item.payload['ticketId'] as String?;
    if (ticketId == null) throw const AppException(message: 'Missing support ticket id');
    final body = Map<String, dynamic>.from(item.payload)..remove('ticketId');
    final localPaths = (body.remove('attachmentLocalPaths') as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final fileIds = await _uploadSupportLocalPaths(dio, localPaths);
    if (fileIds.isNotEmpty) body['attachmentFileIds'] = fileIds;
    await postJson(dio, SupportApiPaths.reply(ticketId), body);
  }

  Future<List<String>> _uploadSupportLocalPaths(Dio dio, List<String> paths) async {
    final ids = <String>[];
    for (final path in paths) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
      });
      final response = await dio.post<dynamic>(SupportApiPaths.upload, data: formData);
      final data = ApiEnvelope.unwrapData(response);
      if (data is Map<String, dynamic>) {
        final id = data['fileId'] as String?;
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  Future<void> _syncOfflineLeadItem(OutboxItem item) async {
    final repo = _ref.read(offlineRepositoryProvider);
    final deviceKey = await _ref.read(sessionControllerProvider.notifier).deviceKey();
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
            message: response.results.firstWhere((r) => r.error != null, orElse: () => response.results.first).error ??
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
    final deviceKey = await _ref.read(sessionControllerProvider.notifier).deviceKey();
    final connectivity = _ref.read(connectivityServiceProvider).currentMode;
    await repo.sync(
      deviceId: deviceKey,
      connectivityMode: connectivity,
      mode: background ? 'background' : 'foreground',
      items: const [],
    );
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
