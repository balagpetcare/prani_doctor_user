import '../../../core/error/api_result.dart';
import '../data/mobile_me_dto.dart';

/// Offline-ready profile repository contract.
abstract class ProfileRepositoryContract {
  Future<ApiResult<MobileMeDto>> getMe({bool forceRefresh = false});

  Future<ApiResult<MobileMeDto>> patchMe(PatchMobileMeInput input);

  Future<ApiResult<String>> uploadProfilePhoto(String filePath);

  Future<MobileMeAddressDto?> readCachedAddress();
}
