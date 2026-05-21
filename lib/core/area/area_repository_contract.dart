import 'area_dto.dart';

/// Client contract for Bangladesh area engine (`/api/area/*`).
abstract class AreaRepositoryContract {
  Future<AreaPage<AreaNodeDto>> getDivisions({int page = 1, int pageSize = 20, String locale = 'bn'});

  Future<AreaPage<AreaNodeDto>> getDistricts(
    String divisionId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaNodeDto>> getUpazilas(
    String districtId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaNodeDto>> getUnions(
    String upazilaId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaNodeDto>> getVillages(
    String unionId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaSearchHitDto>> search({
    required String query,
    String level = 'ALL',
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
  });
}

/// HTTP path map for Dio implementations.
abstract class AreaApiPaths {
  static const divisions = '/api/area/divisions';
  static String districts(String divisionId) => '/api/area/divisions/$divisionId/districts';
  static String upazilas(String districtId) => '/api/area/districts/$districtId/upazilas';
  static String unions(String upazilaId) => '/api/area/upazilas/$upazilaId/unions';
  static String villages(String unionId) => '/api/area/unions/$unionId/villages';
  static const search = '/api/area/search';
}
