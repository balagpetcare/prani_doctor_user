import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/flexible_http.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'settings_api_paths.dart';
import 'settings_dto.dart';
import 'settings_repository_contract.dart';

class SettingsRepository implements SettingsRepositoryContract {
  SettingsRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<SettingsBundle>>? _settingsInFlight;

  @override
  Future<SettingsBundle?> readCachedSettings() async {
    final cached = await _cache.read(LocalCacheContract.userSettingsKey);
    if (cached == null) return null;
    return SettingsBundle.fromJson(cached, fromCache: true);
  }

  @override
  Future<LegalDocumentDto?> readCachedPrivacy() async {
    final cached = await _cache.read(LocalCacheContract.privacyDocumentKey);
    if (cached == null) return null;
    return LegalDocumentDto.fromJson(cached, fromCache: true);
  }

  @override
  Future<LegalDocumentDto?> readCachedTerms() async {
    final cached = await _cache.read(LocalCacheContract.termsDocumentKey);
    if (cached == null) return null;
    return LegalDocumentDto.fromJson(cached, fromCache: true);
  }

  Future<void> _writeSettingsCache(SettingsBundle bundle) async {
    await _cache.write(
      LocalCacheContract.userSettingsKey,
      bundle.toJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<ApiResult<SettingsBundle>> getSettings({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _settingsInFlight != null) return _settingsInFlight!;
    final future = _loadSettings();
    _settingsInFlight = future;
    try {
      return await future;
    } finally {
      _settingsInFlight = null;
    }
  }

  Future<ApiResult<SettingsBundle>> _loadSettings() async {
    try {
      final data = await getJsonFlexible(
        _dio,
        SettingsApiPaths.settings,
        logTag: 'SETTINGS',
      );
      final bundle = SettingsBundle.fromJson(data);
      await _writeSettingsCache(bundle);
      return ApiResult.success(bundle);
    } on AppException catch (e) {
      final cached = await readCachedSettings();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<LegalDocumentDto>> getPrivacy({
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(_dio, SettingsApiPaths.privacy);
      final doc = LegalDocumentDto.fromJson(data);
      await _cache.write(
        LocalCacheContract.privacyDocumentKey,
        doc.toJson(),
        LocalCacheContract.appConfigTtl,
      );
      return ApiResult.success(doc);
    } on AppException catch (e) {
      final cached = await readCachedPrivacy();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<LegalDocumentDto>> getTerms({
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(_dio, SettingsApiPaths.terms);
      final doc = LegalDocumentDto.fromJson(data);
      await _cache.write(
        LocalCacheContract.termsDocumentKey,
        doc.toJson(),
        LocalCacheContract.appConfigTtl,
      );
      return ApiResult.success(doc);
    } on AppException catch (e) {
      final cached = await readCachedTerms();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  Future<void> _enqueueSync(SettingsSyncInput input) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey:
            'settings-sync-$sequence-${DateTime.now().millisecondsSinceEpoch}',
        kind: OutboxKind.settingsSync,
        payload: input.toJson(),
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<ApiResult<SettingsBundle>> sync(SettingsSyncInput input) async {
    try {
      final data = await postJson(_dio, SettingsApiPaths.sync, input.toJson());
      final bundle = SettingsBundle.fromJson(data);
      await _writeSettingsCache(bundle);
      return ApiResult.success(bundle);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueueSync(input);
        final cached = await readCachedSettings();
        if (cached != null) {
          return ApiResult.success(
            SettingsBundle(
              settings: cached.settings,
              legal: cached.legal,
              fromCache: true,
            ),
          );
        }
        return const ApiResult.failure(
          AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<int>> syncPending() async {
    final items = await _outbox.listReady();
    final pending = items
        .where((i) => i.kind == OutboxKind.settingsSync)
        .toList();
    var synced = 0;
    for (final item in pending) {
      try {
        final data = await postJson(_dio, SettingsApiPaths.sync, item.payload);
        final bundle = SettingsBundle.fromJson(data);
        await _writeSettingsCache(bundle);
        await _outbox.remove(item.idempotencyKey);
        synced++;
      } on AppException {
        continue;
      }
    }
    return ApiResult.success(synced);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
