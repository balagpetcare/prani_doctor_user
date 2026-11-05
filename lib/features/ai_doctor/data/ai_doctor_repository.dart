import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'ai_doctor_api_paths.dart';
import 'ai_doctor_dto.dart';

class AiDoctorRepository {
  AiDoctorRepository(this._dio, this._cache);

  final Dio _dio;
  final LocalCacheService _cache;

  Future<void> _persistCaseSummary(Map<String, dynamic> caseJson) async {
    final aiCase = AiDoctorCaseModel.fromJson(caseJson);
    final list = await readCaseHistory();
    final updated = [
      aiCase.toSummaryJson(),
      ...list
          .where((c) => c.id != aiCase.id)
          .map((c) => c.toSummaryJson()),
    ];
    await _cache.write(
      LocalCacheContract.aiDoctorCaseListKey,
      {'cases': updated.take(50).toList()},
      LocalCacheContract.profileTtl,
    );
    await _cache.write(
      LocalCacheContract.aiDoctorCaseKey(aiCase.id),
      {'case': caseJson},
      LocalCacheContract.profileTtl,
    );
    await _cache.write(
      LocalCacheContract.aiDoctorActiveCaseKey,
      {'caseId': aiCase.id},
      LocalCacheContract.profileTtl,
    );
  }

  Future<List<AiDoctorCaseModel>> readCaseHistory() async {
    final cached = await _cache.read(LocalCacheContract.aiDoctorCaseListKey);
    final cases = cached?['cases'] as List<dynamic>? ?? [];
    return cases
        .whereType<Map<String, dynamic>>()
        .map(AiDoctorCaseModel.fromSummaryJson)
        .toList();
  }

  Future<String?> readActiveCaseId() async {
    final cached = await _cache.read(LocalCacheContract.aiDoctorActiveCaseKey);
    return cached?['caseId'] as String?;
  }

  Future<List<AiDoctorChatMessage>> readChatMessages(String caseId) async {
    final cached = await _cache.read(LocalCacheContract.aiDoctorChatKey(caseId));
    final messages = cached?['messages'] as List<dynamic>? ?? [];
    return messages
        .whereType<Map<String, dynamic>>()
        .map(AiDoctorChatMessage.fromJson)
        .toList();
  }

  Future<void> writeChatMessages(
    String caseId,
    List<AiDoctorChatMessage> messages,
  ) async {
    await _cache.write(
      LocalCacheContract.aiDoctorChatKey(caseId),
      {
        'caseId': caseId,
        'messages': messages.map((m) => m.toJson()).toList(),
      },
      LocalCacheContract.profileTtl,
    );
  }

  Future<ApiResult<AiDoctorCaseModel>> createCase(
    CreateAiDoctorCaseInput input,
  ) async {
    try {
      final data = await postJson(
        _dio,
        AiDoctorApiPaths.createCase,
        input.toJson(),
      );
      final caseJson = data['case'] as Map<String, dynamic>? ?? data;
      await _persistCaseSummary(caseJson);
      return ApiResult.success(AiDoctorCaseModel.fromJson(caseJson));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AiDoctorCaseModel>> getCase(String caseId) async {
    try {
      final data = await getJson(_dio, AiDoctorApiPaths.caseDetail(caseId));
      final caseJson = data['case'] as Map<String, dynamic>? ?? data;
      await _persistCaseSummary(caseJson);
      return ApiResult.success(AiDoctorCaseModel.fromJson(caseJson));
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.aiDoctorCaseKey(caseId));
      if (cached != null && cached['case'] is Map<String, dynamic>) {
        return ApiResult.success(
          AiDoctorCaseModel.fromJson(cached['case'] as Map<String, dynamic>),
        );
      }
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnalyzeCaseResultModel>> submitIntake(
    String caseId,
    SubmitIntakeInput input,
  ) async {
    try {
      final data = await postJson(
        _dio,
        AiDoctorApiPaths.intake(caseId),
        input.toJson(),
      );
      final result = AnalyzeCaseResultModel.fromJson(data);
      await _persistCaseSummary(
        data['case'] as Map<String, dynamic>? ?? result.aiCase.toSummaryJson(),
      );
      return ApiResult.success(result);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnalyzeCaseResultModel>> analyze(String caseId) async {
    try {
      final data = await postJson(_dio, AiDoctorApiPaths.analyze(caseId), {});
      final result = AnalyzeCaseResultModel.fromJson(data);
      await _persistCaseSummary(
        data['case'] as Map<String, dynamic>? ?? result.aiCase.toSummaryJson(),
      );
      return ApiResult.success(result);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<EscalateCaseResultModel>> escalate(String caseId) async {
    try {
      final data = await postJson(
        _dio,
        AiDoctorApiPaths.escalate(caseId),
        {},
      );
      final result = EscalateCaseResultModel.fromJson(data);
      await _persistCaseSummary(
        data['case'] as Map<String, dynamic>? ?? {},
      );
      return ApiResult.success(result);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AiDoctorAssistantResponse>> askAssistant(
    AiDoctorAssistantInput input,
  ) async {
    try {
      final data = await postJson(
        _dio,
        AiDoctorApiPaths.assistant,
        input.toJson(),
      );
      return ApiResult.success(AiDoctorAssistantResponse.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }
}

final aiDoctorRepositoryProvider = Provider<AiDoctorRepository>((ref) {
  return AiDoctorRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
  );
});
