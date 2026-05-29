import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import 'ai_phase8_api_paths.dart';
import 'ai_phase8_dto.dart';

class AiPhase8Repository {
  AiPhase8Repository(this._dio);

  final Dio _dio;

  Future<ApiResult<SymptomTaxonomyModel>> fetchTaxonomy(String species) async {
    try {
      final response = await _dio.get<dynamic>(
        AiPhase8ApiPaths.symptomTaxonomy,
        queryParameters: {'species': species},
      );
      final data = ApiEnvelope.unwrapData(response);
      return ApiResult.success(SymptomTaxonomyModel.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<SymptomCheckResultModel>> runSymptomCheck(
    SymptomCheckInput input,
  ) async {
    try {
      final data = await postJson(_dio, AiPhase8ApiPaths.symptomCheck, input.toJson());
      return ApiResult.success(SymptomCheckResultModel.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<KnowledgeHitModel>>> searchKnowledge(String query) async {
    try {
      final response = await _dio.get<dynamic>(
        AiPhase8ApiPaths.knowledgeSearch,
        queryParameters: {'q': query},
      );
      final list = ApiEnvelope.unwrapListData(response);
      return ApiResult.success(
        list.whereType<Map<String, dynamic>>().map(KnowledgeHitModel.fromJson).toList(),
      );
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<SmartRecommendationModel>>> fetchRecommendations({
    String? farmRef,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        AiPhase8ApiPaths.smartRecommendations,
        queryParameters: farmRef == null ? null : {'farmRef': farmRef},
      );
      final envelope = ApiEnvelope.unwrapData(response);
      final itemsRaw = envelope['items'];
      if (itemsRaw is List) {
        return ApiResult.success(
          itemsRaw
              .whereType<Map<String, dynamic>>()
              .map(SmartRecommendationModel.fromJson)
              .toList(),
        );
      }
      final list = ApiEnvelope.unwrapListData(response);
      return ApiResult.success(
        list.whereType<Map<String, dynamic>>().map(SmartRecommendationModel.fromJson).toList(),
      );
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<SmartAlertModel>>> fetchAlerts() async {
    try {
      final response = await _dio.get<dynamic>(AiPhase8ApiPaths.smartAlerts);
      final list = ApiEnvelope.unwrapListData(response);
      return ApiResult.success(
        list.whereType<Map<String, dynamic>>().map(SmartAlertModel.fromJson).toList(),
      );
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<FarmHealthDashboardModel>> fetchFarmHealth(String farmRef) async {
    try {
      final data = await getJson(
        _dio,
        AiPhase8ApiPaths.farmHealth,
        queryParameters: {'farmRef': farmRef},
      );
      return ApiResult.success(FarmHealthDashboardModel.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<FollowUpModel>>> fetchFollowUps() async {
    try {
      final response = await _dio.get<dynamic>(AiPhase8ApiPaths.followUps);
      final list = ApiEnvelope.unwrapListData(response);
      return ApiResult.success(
        list.whereType<Map<String, dynamic>>().map(FollowUpModel.fromJson).toList(),
      );
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<void>> dismissRecommendation(String id) async {
    try {
      await postJson(_dio, AiPhase8ApiPaths.dismissRecommendation(id), {});
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<void>> completeRecommendation(String id) async {
    try {
      await postJson(_dio, AiPhase8ApiPaths.completeRecommendation(id), {});
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<void>> dismissAlert(String id) async {
    try {
      await postJson(_dio, AiPhase8ApiPaths.dismissAlert(id), {});
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<void>> dismissFollowUp(String id) async {
    try {
      await postJson(_dio, AiPhase8ApiPaths.dismissFollowUp(id), {});
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }
}

final aiPhase8RepositoryProvider = Provider<AiPhase8Repository>((ref) {
  return AiPhase8Repository(ref.watch(dioProvider));
});
