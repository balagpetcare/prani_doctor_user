import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import 'provider_api_paths.dart';
import 'provider_dto.dart';

class DoctorDiscoveryFilters {
  const DoctorDiscoveryFilters({
    this.emergencyOnly = false,
    this.onlineOnly = false,
    this.homeVisitOnly = false,
    this.villageId,
    this.locationLabel,
    this.areaSlug,
  });

  final bool emergencyOnly;
  final bool onlineOnly;
  final bool homeVisitOnly;
  final String? villageId;
  final String? locationLabel;
  final String? areaSlug;

  DoctorDiscoveryFilters copyWith({
    bool? emergencyOnly,
    bool? onlineOnly,
    bool? homeVisitOnly,
    String? villageId,
    String? locationLabel,
    String? areaSlug,
    bool clearLocation = false,
  }) {
    return DoctorDiscoveryFilters(
      emergencyOnly: emergencyOnly ?? this.emergencyOnly,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      homeVisitOnly: homeVisitOnly ?? this.homeVisitOnly,
      villageId: clearLocation ? null : villageId ?? this.villageId,
      locationLabel: clearLocation ? null : locationLabel ?? this.locationLabel,
      areaSlug: clearLocation ? null : areaSlug ?? this.areaSlug,
    );
  }
}

class DoctorRepository {
  DoctorRepository(this._dio);

  final Dio _dio;

  Future<ApiResult<DoctorListResultDto>> listDoctors(
    DoctorDiscoveryFilters filters,
  ) async {
    try {
      final params = <String, dynamic>{
        'limit': 50,
        'offset': 0,
        if (filters.emergencyOnly) 'emergency': 'true',
        if (filters.onlineOnly) 'onlineConsultation': 'true',
        if (filters.homeVisitOnly) 'homeVisit': 'true',
        if (filters.areaSlug != null) 'areaSlug': filters.areaSlug,
      };

      final data = await getJson(_dio, ProviderApiPaths.doctors, queryParameters: params);
      final doctors = (data['doctors'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProviderDoctorListItemDto.fromJson)
          .toList();

      var filtered = doctors;
      if (filters.locationLabel != null && filters.locationLabel!.isNotEmpty) {
        final needle = filters.locationLabel!.toLowerCase();
        filtered = doctors
            .where((d) => d.areaText.toLowerCase().contains(needle))
            .toList();
      }

      final pagination = ProviderPaginationDto.fromJson(
        data['pagination'] as Map<String, dynamic>? ?? {},
      );

      return ApiResult.success(
        DoctorListResultDto(doctors: filtered, pagination: pagination),
      );
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Could not load doctors', cause: e));
    }
  }

  Future<ApiResult<ProviderDoctorDetailDto>> getDoctor(String id) async {
    try {
      final data = await getJson(_dio, ProviderApiPaths.doctor(id));
      final doctor = data['doctor'];
      if (doctor is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Doctor not found'));
      }
      return ApiResult.success(ProviderDoctorDetailDto.fromJson(doctor));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Could not load doctor', cause: e));
    }
  }
}

final doctorDiscoveryFiltersProvider =
    StateProvider<DoctorDiscoveryFilters>((ref) => const DoctorDiscoveryFilters());

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(dioProvider));
});

final doctorListProvider = FutureProvider<DoctorListResultDto>((ref) async {
  final filters = ref.watch(doctorDiscoveryFiltersProvider);
  final result = await ref.read(doctorRepositoryProvider).listDoctors(filters);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final doctorDetailProvider =
    FutureProvider.family<ProviderDoctorDetailDto, String>((ref, id) async {
  final result = await ref.read(doctorRepositoryProvider).getDoctor(id);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});
