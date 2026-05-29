import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/offline/offline_providers.dart';
import '../../offline/offline_dto.dart';

/// Fails fast when the device is hard-offline instead of waiting for a socket
/// timeout. Emits a `connectionError` [DioException] so the existing transient
/// handling (and offline outbox enqueue) treats it exactly like a normal
/// connection failure.
///
/// Only short-circuits on [OfflineConnectivityMode.offline] (the strongest
/// signal); `degraded` is allowed through. Rejects with
/// `callFollowingErrorInterceptor: false` so server-reachability state is not
/// flipped for a device-side outage.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final mode = _ref.read(connectivityServiceProvider).currentMode;
    if (mode == OfflineConnectivityMode.offline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Device offline',
          message: 'No internet connection',
        ),
      );
      return;
    }
    handler.next(options);
  }
}
