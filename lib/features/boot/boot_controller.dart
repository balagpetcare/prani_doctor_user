import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_env.dart';
import '../../core/error/app_exception.dart';
import '../../core/utils/version_utils.dart';
import '../app_config/data/app_config_dto.dart';
import '../app_config/data/app_config_repository.dart';
import '../app_config/presentation/app_config_provider.dart';
import '../auth/data/auth_preferences.dart';
import '../auth/data/auth_repository.dart';
import '../offline/data/sync_coordinator.dart';
import '../profile/presentation/profile_providers.dart';
import '../../core/session/session_controller.dart';
import 'boot_state.dart';

/// Orchestrates cold-start: config → update check → session restore.
class BootController extends StateNotifier<BootState> {
  BootController(this._ref) : super(const BootState());

  final Ref _ref;
  bool _running = false;

  Future<void> run() async {
    if (_running || state.isReady || state.forceUpdateRequired) return;
    _running = true;

    try {
      state = state.copyWith(
        phase: BootPhase.splash,
        clearError: true,
        clearForceUpdate: true,
      );

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      state = state.copyWith(appVersion: appVersion);

      await Future<void>.delayed(const Duration(milliseconds: 400));

      state = state.copyWith(phase: BootPhase.initializing);
      final configFuture = _ref.read(appConfigRepositoryProvider).loadConfig();
      final sessionFuture =
          _ref.read(sessionControllerProvider.notifier).restoreFromStorage();

      final configResult = await configFuture;
      await sessionFuture;

      final configLoaded = configResult.when(
        success: (result) {
          _ref.read(appConfigProvider.notifier).state = result.config;
          state = state.copyWith(
            config: result.config,
            configFromCache: result.fromCache,
          );
          return true;
        },
        failure: (error) {
          if (error.code == 'FORCE_UPDATE_REQUIRED') {
            _applyForceUpdateFromError(error, appVersion);
            return false;
          }
          state = state.copyWith(
            phase: BootPhase.error,
            errorMessage: error.message,
          );
          return false;
        },
      );
      if (!configLoaded) return;

      state = state.copyWith(phase: BootPhase.checkingUpdate);
      final forceUpdate = _resolveForceUpdate(state.config, appVersion);
      if (forceUpdate != null) {
        state = state.copyWith(
          phase: BootPhase.forceUpdate,
          forceUpdate: forceUpdate,
        );
        return;
      }

      state = state.copyWith(phase: BootPhase.restoringSession);
      await _restoreSession();

      state = state.copyWith(phase: BootPhase.ready);
    } finally {
      _running = false;
    }
  }

  Future<void> retry() async {
    state = const BootState(phase: BootPhase.splash);
    await run();
  }

  Future<void> _restoreSession() async {
    final remember = await _ref.read(authPreferencesProvider).rememberSession();
    if (!remember) {
      await _ref.read(sessionControllerProvider.notifier).signOut();
      return;
    }

    final session = _ref.read(sessionControllerProvider.notifier);
    final expired = await session.isAccessTokenExpired();
    if (expired) {
      final refreshToken = await session.readRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final refreshed = await _ref.read(authRepositoryProvider).refreshSession();
        if (!refreshed) return;
      } else {
        await session.signOut();
        return;
      }
    }

    if (_ref.read(sessionControllerProvider).isAuthenticated) {
      await _ref.read(mobileMeProvider.notifier).reload();
      await _ref.read(syncCoordinatorProvider).syncNow(background: true);
    }
  }

  ForceUpdateInfo? _resolveForceUpdate(AppConfigDto? config, String appVersion) {
    final env = AppEnv.fromEnvironment();

    final minimum = _firstNonEmpty([
      config?.minimumVersion,
      env.minimumAppVersion,
    ]);
    if (minimum == null || minimum.isEmpty) return null;

    final belowMinimum = VersionUtils.isBelowMinimum(appVersion, minimum);
    final forcedByFlag = config?.updateRequired == true;
    if (!belowMinimum && !forcedByFlag) return null;

    return ForceUpdateInfo(
      minimumVersion: minimum,
      currentVersion: appVersion,
      updateUrl: _firstNonEmpty([config?.updateUrl, env.updateUrl]),
      message: config?.updateMessage ??
          'A newer version of PraniDoctor is required to continue.',
    );
  }

  void _applyForceUpdateFromError(AppException error, String appVersion) {
    final details = _errorDetails(error);
    final minimum = details?['minimumVersion'] as String? ?? 'unknown';
    state = state.copyWith(
      phase: BootPhase.forceUpdate,
      forceUpdate: ForceUpdateInfo(
        minimumVersion: minimum,
        currentVersion: details?['currentVersion'] as String? ?? appVersion,
        updateUrl: details?['updateUrl'] as String?,
        message: error.message,
      ),
    );
  }

  Map<String, dynamic>? _errorDetails(AppException error) {
    final cause = error.cause;
    if (cause is Map<String, dynamic>) return cause;
    return null;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

final bootControllerProvider =
    StateNotifierProvider<BootController, BootState>((ref) {
  return BootController(ref);
});
