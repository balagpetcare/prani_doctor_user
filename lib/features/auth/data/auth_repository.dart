import 'package:dio/dio.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/session/session_controller.dart';

/// Coordinates OAuth providers and backend token exchange (implement end-to-end later).
class AuthRepository {
  AuthRepository(this._dio, this._sessionController);

  // ignore: unused_field
  final Dio _dio;
  final SessionController _sessionController;

  final GoogleSignIn _google = GoogleSignIn(scopes: ['email', 'profile']);

  Future<ApiResult<void>> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) {
        return ApiResult.failure(
          AppException(message: 'Google sign-in cancelled'),
        );
      }
      // TODO: POST idToken to API using _dio
      await _sessionController.setSession(
        userId: account.id,
        displayName: account.displayName,
        accessToken: 'google-placeholder',
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Google sign-in failed', cause: e),
      );
    }
  }

  Future<ApiResult<void>> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        return ApiResult.failure(
          AppException(
            message: result.message ?? 'Facebook sign-in failed',
            code: result.status.name,
          ),
        );
      }
      final token = result.accessToken?.tokenString;
      // TODO: exchange token with backend via _dio
      await _sessionController.setSession(
        userId: 'facebook-user',
        accessToken: token ?? 'fb-placeholder',
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Facebook sign-in error', cause: e),
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final session = ref.watch(sessionControllerProvider.notifier);
  return AuthRepository(dio, session);
});
