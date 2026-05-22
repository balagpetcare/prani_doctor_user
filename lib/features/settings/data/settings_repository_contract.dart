import '../../../core/error/api_result.dart';
import 'settings_dto.dart';

abstract class SettingsRepositoryContract {
  Future<SettingsBundle?> readCachedSettings();

  Future<LegalDocumentDto?> readCachedPrivacy();

  Future<LegalDocumentDto?> readCachedTerms();

  Future<ApiResult<SettingsBundle>> getSettings({bool forceRefresh = false});

  Future<ApiResult<LegalDocumentDto>> getPrivacy({bool forceRefresh = false});

  Future<ApiResult<LegalDocumentDto>> getTerms({bool forceRefresh = false});

  Future<ApiResult<SettingsBundle>> sync(SettingsSyncInput input);

  Future<ApiResult<int>> syncPending();
}
