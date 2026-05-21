import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_env.dart';

final dioProvider = Provider<Dio>((ref) {
  final env = AppEnv.fromEnvironment();
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (e, handler) {
        // TODO: map DioException to AppException / logging
        handler.next(e);
      },
    ),
  );
  return dio;
});
