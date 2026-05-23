import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app/app_env.dart';
import '../../features/app_config/data/app_config_api_paths.dart';
import '../../features/auth/data/auth_api_paths.dart';
import '../../features/profile/data/profile_api_paths.dart';
import '../../features/support/data/support_api_paths.dart';
import '../session/session_controller.dart';
import 'network_constants.dart';

enum NetworkProbeKind {
  apiLive,
  appConfig,
  authProfile,
  refreshToken,
  uploadEndpoint,
}

class NetworkProbeResult {
  const NetworkProbeResult({
    required this.kind,
    required this.success,
    required this.latencyMs,
    this.statusCode,
    this.message,
  });

  final NetworkProbeKind kind;
  final bool success;
  final int latencyMs;
  final int? statusCode;
  final String? message;
}

class NetworkDiagnostics {
  const NetworkDiagnostics({
    required this.apiBaseUrl,
    required this.webBaseUrl,
    required this.apiPort,
    required this.urlSource,
    required this.probes,
    required this.checkedAt,
    required this.deviceOnline,
  });

  final String apiBaseUrl;
  final String webBaseUrl;
  final int apiPort;
  final ApiUrlSource urlSource;
  final List<NetworkProbeResult> probes;
  final DateTime checkedAt;
  final bool deviceOnline;

  bool get allRequiredPassed => probes.where((p) => p.success).length >= 2;
}

/// Probes backend reachability over WiFi/LAN without mutating session on failure.
class NetworkService {
  NetworkService(this._env, this._session);

  final AppEnv _env;
  final SessionController _session;

  Dio _probeClient() {
    return Dio(
      BaseOptions(
        baseUrl: _env.apiBaseUrl,
        connectTimeout: const Duration(
          seconds: NetworkConstants.probeTimeoutSec,
        ),
        receiveTimeout: const Duration(
          seconds: NetworkConstants.probeTimeoutSec,
        ),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<NetworkDiagnostics> runDiagnostics({
    required bool deviceOnline,
  }) async {
    final dio = _probeClient();
    final probes = <NetworkProbeResult>[
      await _probeLive(dio),
      await _probeAppConfig(dio),
      await _probeAuthProfile(dio),
      await _probeRefreshToken(dio),
      await _probeUploadReachability(dio),
    ];

    if (_env.logNetwork && kDebugMode) {
      for (final p in probes) {
        debugPrint(
          '[NetworkService] ${p.kind.name} ok=${p.success} '
          '${p.latencyMs}ms ${p.message ?? ''}',
        );
      }
    }

    return NetworkDiagnostics(
      apiBaseUrl: _env.apiBaseUrl,
      webBaseUrl: _env.webBaseUrl,
      apiPort: _env.apiPort,
      urlSource: _env.apiUrlSource,
      probes: probes,
      checkedAt: DateTime.now(),
      deviceOnline: deviceOnline,
    );
  }

  Future<NetworkProbeResult> _probeLive(Dio dio) async {
    return _timed(NetworkProbeKind.apiLive, () async {
      final response = await dio.get<dynamic>(NetworkConstants.healthLive);
      final data = response.data;
      if (data is Map && data['alive'] == true) {
        return (
          success: true,
          statusCode: response.statusCode,
          message: 'Backend live',
        );
      }
      return (
        success: false,
        statusCode: response.statusCode,
        message: 'Unexpected live response',
      );
    });
  }

  Future<NetworkProbeResult> _probeAppConfig(Dio dio) async {
    return _timed(NetworkProbeKind.appConfig, () async {
      final response = await dio.get<dynamic>(AppConfigApiPaths.config);
      final data = response.data;
      if (data is Map && (data['ok'] == true || data['success'] == true)) {
        return (
          success: true,
          statusCode: response.statusCode,
          message: 'Mobile app-config OK',
        );
      }
      return (
        success: false,
        statusCode: response.statusCode,
        message: 'App-config envelope failed',
      );
    });
  }

  Future<NetworkProbeResult> _probeAuthProfile(Dio dio) async {
    final token = await _session.readAccessToken();
    if (token == null || token.isEmpty) {
      return const NetworkProbeResult(
        kind: NetworkProbeKind.authProfile,
        success: false,
        latencyMs: 0,
        message: 'Skipped — not signed in',
      );
    }
    return _timed(NetworkProbeKind.authProfile, () async {
      final response = await dio.get<dynamic>(
        ProfileApiPaths.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          (data['ok'] == true || data['success'] == true)) {
        return (
          success: true,
          statusCode: response.statusCode,
          message: 'Auth /me OK',
        );
      }
      return (
        success: false,
        statusCode: response.statusCode,
        message: 'Profile request failed',
      );
    });
  }

  Future<NetworkProbeResult> _probeRefreshToken(Dio dio) async {
    final refresh = await _session.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return const NetworkProbeResult(
        kind: NetworkProbeKind.refreshToken,
        success: false,
        latencyMs: 0,
        message: 'Skipped — no refresh token',
      );
    }
    return _timed(NetworkProbeKind.refreshToken, () async {
      final response = await dio.post<dynamic>(
        AuthApiPaths.refresh,
        data: {'refreshToken': refresh},
      );
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          (data['ok'] == true || data['success'] == true)) {
        return (
          success: true,
          statusCode: response.statusCode,
          message: 'Refresh token OK',
        );
      }
      return (
        success: false,
        statusCode: response.statusCode,
        message: 'Refresh failed',
      );
    });
  }

  Future<NetworkProbeResult> _probeUploadReachability(Dio dio) async {
    return _timed(NetworkProbeKind.uploadEndpoint, () async {
      final storage = await dio.get<dynamic>(NetworkConstants.healthStorage);
      final storageData = storage.data;
      if (storageData is Map) {
        final check = storageData['check'];
        if (check is Map && check['status'] == 'healthy') {
          return (
            success: true,
            statusCode: storage.statusCode,
            message: 'Storage healthy',
          );
        }
      }
      // Fallback: route exists (401/405 still proves API reachability).
      try {
        final response = await dio.head<dynamic>(SupportApiPaths.upload);
        if (response.statusCode != null && response.statusCode! < 500) {
          return (
            success: true,
            statusCode: response.statusCode,
            message: 'Upload route reachable',
          );
        }
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 405 || code == 404) {
          return (
            success: true,
            statusCode: code,
            message: 'Upload route reachable ($code)',
          );
        }
        rethrow;
      }
      return (
        success: false,
        statusCode: storage.statusCode,
        message: 'Storage/upload not ready',
      );
    });
  }

  Future<NetworkProbeResult> _timed(
    NetworkProbeKind kind,
    Future<({bool success, int? statusCode, String message})> Function() run,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final result = await run();
      sw.stop();
      return NetworkProbeResult(
        kind: kind,
        success: result.success,
        latencyMs: sw.elapsedMilliseconds,
        statusCode: result.statusCode,
        message: result.message,
      );
    } on DioException catch (e) {
      sw.stop();
      return NetworkProbeResult(
        kind: kind,
        success: false,
        latencyMs: sw.elapsedMilliseconds,
        statusCode: e.response?.statusCode,
        message: e.message ?? e.type.name,
      );
    } catch (e) {
      sw.stop();
      return NetworkProbeResult(
        kind: kind,
        success: false,
        latencyMs: sw.elapsedMilliseconds,
        message: e.toString(),
      );
    }
  }
}
