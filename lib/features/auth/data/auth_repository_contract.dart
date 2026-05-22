import '../../../core/error/api_result.dart';
import 'auth_dto.dart';

/// Offline-ready auth repository contract.
abstract class AuthRepositoryContract {
  Future<ApiResult<OtpRequestResultDto>> requestOtp(String phone);

  Future<ApiResult<AuthTokensDto>> verifyOtp({
    required String phone,
    required String code,
    String? pushToken,
    bool rememberSession = true,
  });

  Future<ApiResult<AuthTokensDto>> loginWithPassword({
    required String identifier,
    required String password,
    String? pushToken,
    bool rememberSession = true,
  });

  Future<ApiResult<AuthTokensDto>> register({
    required String name,
    required String mobile,
    required String password,
    String? email,
    String? pushToken,
    bool rememberSession = true,
  });

  Future<bool> refreshSession();

  Future<void> signOut({bool clearPreferences = false});

  Future<String?> readCachedPhone();

  Future<OtpRequestResultDto?> readCachedOtpRequest(String phone);
}
