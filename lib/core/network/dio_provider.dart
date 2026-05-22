import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_env.dart';
import '../../features/auth/data/auth_api_paths.dart';
import '../auth/token_refresh.dart';
import '../session/session_controller.dart';

final dioProvider = Provider<Dio>((ref) {
  final env = AppEnv.fromEnvironment();
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!AuthApiPaths.isUnauthenticatedPath(options.path)) {
          final token =
              await ref.read(sessionControllerProvider.notifier).readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        if (env.logNetwork && kDebugMode) {
          debugPrint('→ ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final path = error.requestOptions.path;
        final is401 = response?.statusCode == 401;
        final canRefresh =
            is401 && !AuthApiPaths.isUnauthenticatedPath(path);

        if (canRefresh && error.requestOptions.extra['_retried'] != true) {
          final refreshed = await refreshAccessToken(
            dio: dio,
            session: ref.read(sessionControllerProvider.notifier),
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

        if (env.logNetwork && kDebugMode) {
          debugPrint('✗ ${error.requestOptions.method} ${error.requestOptions.uri}');
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
