import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_providers.dart';
import 'data/connectivity_service.dart';
import 'data/local_cache_service.dart';
import 'data/offline_repository.dart';
import 'data/outbox_service.dart';

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService(ref.watch(cacheStoreProvider));
});

final outboxServiceProvider = Provider<OutboxService>((ref) {
  return OutboxService(ref.watch(cacheStoreProvider));
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final offlineSyncStatusProvider = FutureProvider<int>((ref) async {
  final local = await ref.read(outboxServiceProvider).pendingCount();
  final remote = await ref.read(offlineRepositoryProvider).getSyncStatus();
  return remote.when(
    success: (status) => local + status.pendingCount,
    failure: (_) => local,
  );
});

final localOutboxCountProvider = FutureProvider<int>((ref) async {
  return ref.read(outboxServiceProvider).pendingCount();
});
