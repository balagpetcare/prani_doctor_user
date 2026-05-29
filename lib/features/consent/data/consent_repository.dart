import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import 'consent_api_paths.dart';
import 'consent_dto.dart';

class ConsentRepository {
  ConsentRepository(this._dio);

  final Dio _dio;

  Future<ApiResult<ConsentStatusDto>> getStatus() async {
    try {
      final data = await getJson(_dio, ConsentApiPaths.status);
      return ApiResult.success(ConsentStatusDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<ConsentStatusDto>> withdraw({
    required String consentType,
    String? reason,
  }) async {
    try {
      final data = await postJson(_dio, ConsentApiPaths.withdraw, {
        'consentType': consentType,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return ApiResult.success(ConsentStatusDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }
}

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return ConsentRepository(ref.watch(dioProvider));
});
