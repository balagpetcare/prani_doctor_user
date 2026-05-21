import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'mobile_me_dto.dart';
import 'profile_api_paths.dart';

class ProfileRepository {
  ProfileRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<MobileMeDto>> getMe() async {
    try {
      final data = await getJson(_dio, ProfileApiPaths.me);
      await _cache.write(
        LocalCacheContract.profileKey,
        data,
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(MobileMeDto.fromJson(data));
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.profileKey);
      if (cached != null) {
        return ApiResult.success(MobileMeDto.fromJson(cached));
      }
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Failed to load profile', cause: e));
    }
  }

  Future<ApiResult<MobileMeDto>> patchMe(PatchMobileMeInput input) async {
    final body = input.toJson();
    try {
      if (body.isEmpty) {
        return ApiResult.failure(const AppException(message: 'No changes to save'));
      }
      final data = await patchJson(_dio, ProfileApiPaths.me, body);
      await _cache.write(
        LocalCacheContract.profileKey,
        data,
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(MobileMeDto.fromJson(data));
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueuePatch(body: body);
        return ApiResult.failure(
          const AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Failed to update profile', cause: e));
    }
  }

  Future<void> _enqueuePatch({required Map<String, dynamic> body}) async {
    if (body.isEmpty) return;
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: 'profile-$sequence-${DateTime.now().millisecondsSinceEpoch}',
        kind: OutboxKind.profilePatch,
        payload: body,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
