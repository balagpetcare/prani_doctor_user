/// Mobile auth REST paths (legacy compat via web BFF or direct backend).
abstract final class AuthApiPaths {
  AuthApiPaths._();

  static const otpRequest = '/api/mobile/auth/otp/request';
  static const otpVerify = '/api/mobile/auth/otp/verify';
  static const login = '/api/mobile/auth/login';
  static const register = '/api/mobile/auth/register';
  static const refresh = '/api/mobile/auth/refresh';

  static bool isUnauthenticatedPath(String path) {
    return path.contains('/api/mobile/auth/') ||
        path.contains('/api/mobile/app-config');
  }
}
