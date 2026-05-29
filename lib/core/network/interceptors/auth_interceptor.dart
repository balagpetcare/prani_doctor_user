import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/data/auth_api_paths.dart';
import '../../session/session_controller.dart';

/// Injects the bearer access token on authenticated requests and normalizes
/// multipart `Content-Type` so Dio can set the correct boundary.
///
/// Behavior is unchanged from the previous inline interceptor.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.data is FormData) {
      options.headers.remove('Content-Type');
      options.headers.remove('content-type');
      options.contentType = null;
    }
    if (!AuthApiPaths.isUnauthenticatedPath(options.path)) {
      final session = _ref.read(sessionControllerProvider.notifier);
      final token = await session.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
