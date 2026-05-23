import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_api_paths.dart';
import 'network_providers.dart';
import '../session/session_controller.dart';
import '../session/session_manager.dart';
import 'auto_refresh_guard.dart';

final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  if (env.logNetwork && kDebugMode) {
    debugPrint('[Dio] baseUrl=${env.apiBaseUrl}');
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: env.connectTimeout,
      receiveTimeout: env.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.data is FormData) {
          options.headers.remove('Content-Type');
          options.headers.remove('content-type');
          options.contentType = null;
        }
        if (!AuthApiPaths.isUnauthenticatedPath(options.path)) {
          final session = ref.read(sessionControllerProvider.notifier);
          final token = await session.readAccessToken();
          final hasAuth = token != null && token.isNotEmpty;
          if (hasAuth) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        if (env.logNetwork && kDebugMode) {
          final ct = options.headers['Content-Type'];
          debugPrint(
            '→ ${options.method} ${options.uri}'
            '${options.data is FormData ? ' [multipart]' : ''}'
            '${ct != null ? ' ct=$ct' : ''}',
          );
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final path = error.requestOptions.path;
        final is401 = response?.statusCode == 401;
        final canRefresh = is401 && !AuthApiPaths.isUnauthenticatedPath(path);

        if (canRefresh && error.requestOptions.extra['_retried'] != true) {
          if (kDebugMode) {
            debugPrint('[AUTH] 401 ${error.requestOptions.method} $path');
          }
          final sessionManager = ref.read(sessionManagerProvider);
          final refreshed = await sessionManager.recoverFromUnauthorized(
            dio: dio,
          );
          if (refreshed) {
            final token = await ref
                .read(sessionControllerProvider.notifier)
                .readAccessToken();
            final opts = error.requestOptions;
            opts.extra['_retried'] = true;
            if (token != null) {
              opts.headers['Authorization'] = 'Bearer $token';
            }
            if (kDebugMode) {
              debugPrint('[AUTH] retry once ${opts.method} ${opts.path}');
            }
            try {
              final retryResponse = await dio.fetch<dynamic>(opts);
              handler.resolve(retryResponse);
              return;
            } on DioException catch (retryError) {
              handler.next(retryError);
              return;
            }
          }
        }

        final status = response?.statusCode;
        if (status == 405 && kDebugMode) {
          debugPrint(
            '[API] 405 Method Not Allowed ${error.requestOptions.method} ${error.requestOptions.path}',
          );
        }
        if (env.logNetwork && kDebugMode) {
          debugPrint(
            '✗ ${error.requestOptions.method} ${error.requestOptions.uri} status=$status',
          );
        }

        final isTransient = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError ||
            (status != null && status >= 500);
        if (isTransient) {
          ref.read(autoRefreshGuardProvider.notifier).recordApiFailure();
        }

        handler.next(error);
      },
      onResponse: (response, handler) {
        if (response.statusCode != null && response.statusCode! < 500) {
          ref.read(autoRefreshGuardProvider.notifier).recordApiSuccess();
        }
        handler.next(response);
      },
    ),
  );

  return dio;
});
