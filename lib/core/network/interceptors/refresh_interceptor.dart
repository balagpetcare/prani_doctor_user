import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/data/auth_api_paths.dart';
import '../../session/session_controller.dart';
import '../../session/session_manager.dart';

/// Handles 401 recovery: refresh the access token once (de-duplicated by
/// [SessionManager]) and retry the original request exactly once.
///
/// De-duplication of concurrent refreshes is owned by [SessionManager]
/// (`_refreshInFlight` + waiter queue), so multiple simultaneous 401s share a
/// single refresh call. Never signs the user out here.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final path = err.requestOptions.path;
    final is401 = response?.statusCode == 401;
    final canRefresh = is401 && !AuthApiPaths.isUnauthenticatedPath(path);

    if (canRefresh && err.requestOptions.extra['_retried'] != true) {
      if (kDebugMode) {
        debugPrint('[AUTH] 401 ${err.requestOptions.method} $path');
      }
      final sessionManager = _ref.read(sessionManagerProvider);
      final refreshed = await sessionManager.recoverFromUnauthorized(
        dio: _dio,
      );
      if (refreshed) {
        final token = await _ref
            .read(sessionControllerProvider.notifier)
            .readAccessToken();
        final opts = err.requestOptions;
        opts.extra['_retried'] = true;
        if (token != null) {
          opts.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[AUTH] retry once ${opts.method} ${opts.path}');
        }
        try {
          final retryResponse = await _dio.fetch<dynamic>(opts);
          handler.resolve(retryResponse);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }

    handler.next(err);
  }
}
