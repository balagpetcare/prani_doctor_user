import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/network_errors.dart';
import '../../../core/offline/offline_dto.dart';
import '../../../core/session/session_controller.dart';
import '../../profile/data/profile_api_paths.dart';
import '../../service_requests/data/service_request_api_paths.dart';
import '../offline_providers.dart';
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
