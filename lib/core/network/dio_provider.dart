import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_providers.dart';
import 'interceptors/interceptors.dart';

/// Single shared, environment-configured Dio client.
///
/// Interceptor order is significant and mirrors the previous inline behavior:
///  1. [ConnectivityInterceptor] — fail fast when the device is offline.
///  2. [AuthInterceptor]         — multipart normalization + bearer token.
///  3. [RefreshInterceptor]      — 401 → refresh once → retry once.
///  4. [LoggingInterceptor]      — debug request/error logging (after auth).
///  5. [ErrorInterceptor]        — server-reachability tracking.
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
      sendTimeout: env.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    ConnectivityInterceptor(ref),
    AuthInterceptor(ref),
    RefreshInterceptor(ref, dio),
    LoggingInterceptor(enabled: env.logNetwork),
    ErrorInterceptor(ref),
    CrashReportingNetworkInterceptor.shared(),
  ]);

  return dio;
});
