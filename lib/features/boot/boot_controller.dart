import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_env.dart';
import '../../core/branding/brand_assets.dart';
import '../../core/error/api_result.dart';
import '../../core/error/app_exception.dart';
import '../../core/utils/version_utils.dart';
import '../app_config/data/app_config_dto.dart';
import '../app_config/data/app_config_repository.dart';
import '../app_config/presentation/app_config_provider.dart';
import '../auth/data/auth_preferences.dart';
import '../offline/data/sync_coordinator.dart';
import '../profile/data/mobile_me_dto.dart';
import '../profile/data/profile_repository.dart';
import '../profile/presentation/profile_providers.dart';
import '../../core/network/dio_provider.dart';
import '../../core/session/session_auth.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_manager.dart';
import 'boot_state.dart';

/// Orchestrates cold-start: config → maintenance/update → session restore.
class BootController extends StateNotifier<BootState> {
  BootController(this._ref) : super(const BootState());

  final Ref _ref;
  bool _running = false;

  Future<void> run() async {
    if (_running || state.isReady || state.isBlocked) return;
    _running = true;

    try {
      state = state.copyWith(
        phase: BootPhase.splash,
        clearError: true,
        clearForceUpdate: true,
        clearOptionalUpdate: true,
        clearMaintenance: true,
      );

      _log('Boot pipeline started');

      final packageInfoFuture = PackageInfo.fromPlatform();
      final configFuture = _ref.read(appConfigRepositoryProvider).loadConfig();
      final sessionFuture = _ref
          .read(sessionControllerProvider.notifier)
          .restoreFromStorage();
      final splashFuture = Future<void>.delayed(
        const Duration(milliseconds: BrandAssets.splashMinDisplayMs),
      );

      state = state.copyWith(phase: BootPhase.initializing);

      final results = await Future.wait<Object?>([
        packageInfoFuture,
        configFuture,
        sessionFuture,
        splashFuture,
      ]);

      final packageInfo = results[0]! as PackageInfo;
      final configResult = results[1]! as ApiResult<AppConfigLoadResult>;
      final appVersion = packageInfo.version;
      state = state.copyWith(appVersion: appVersion);

      final configLoaded = configResult.when(
        success: (result) {
          _ref.read(appConfigProvider.notifier).state = result.config;
          state = state.copyWith(
            config: result.config,
            configFromCache: result.fromCache,
          );
          _log(
            'Config loaded (cache=${result.fromCache}, '
            'maintenance=${result.config.isMaintenanceMode})',
          );
          return true;
        },
        failure: (AppException error) {
          if (error.code == 'FORCE_UPDATE_REQUIRED') {
            _applyForceUpdateFromError(error, appVersion);
            return false;
          }
          if (error.code == 'SYS_MAINTENANCE') {
            _applyMaintenanceFromError(error);
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

      final maintenance = _resolveMaintenance(state.config);
      if (maintenance != null) {
        state = state.copyWith(
          phase: BootPhase.maintenance,
          maintenance: maintenance,
        );
        _log('Maintenance mode active');
        return;
      }

      final forceUpdate = _resolveForceUpdate(state.config, appVersion);
      if (forceUpdate != null) {
        state = state.copyWith(
          phase: BootPhase.forceUpdate,
          forceUpdate: forceUpdate,
        );
        _log('Force update required (${forceUpdate.minimumVersion})');
        return;
      }

      final optionalUpdate = _resolveOptionalUpdate(state.config, appVersion);
      if (optionalUpdate != null) {
        state = state.copyWith(
          phase: BootPhase.optionalUpdate,
          optionalUpdate: optionalUpdate,
        );
        _log(
          'Optional update available (${optionalUpdate.recommendedVersion})',
        );
        return;
      }

      await _finishBoot();
    } finally {
      _running = false;
    }
  }

  Future<void> retry() async {
    state = const BootState(phase: BootPhase.splash);
    await run();
  }

  Future<void> skipOptionalUpdate() async {
    if (!state.optionalUpdatePending) return;
    state = state.copyWith(clearOptionalUpdate: true);
    await _finishBoot();
  }

  Future<void> _finishBoot() async {
    state = state.copyWith(phase: BootPhase.restoringSession);
    await _restoreSession();
    state = state.copyWith(phase: BootPhase.ready);
    _log('Boot ready');
  }

  Future<void> _restoreSession() async {
    final remember = await _ref.read(authPreferencesProvider).rememberSession();
    if (!remember) {
      await _ref.read(sessionControllerProvider.notifier).signOut();
      _log('Remember session disabled — signed out');
      return;
    }

    final session = _ref.read(sessionControllerProvider.notifier);
    final sessionManager = _ref.read(sessionManagerProvider);
    final dio = _ref.read(dioProvider);
    final hasRefresh = await session.readRefreshToken();
    final expired = await session.isAccessTokenExpired();
    if (expired) {
      if (hasRefresh != null && hasRefresh.isNotEmpty) {
        final refreshed = await sessionManager.ensureValidAccessToken(dio: dio);
        if (!refreshed) {
          _log('Token refresh failed — guest fallback (session kept)');
          return;
        }
        _log('Access token refreshed');
      } else {
        await session.signOut();
        _log('No refresh token — signed out');
        return;
      }
    }

    if (!SessionAuth.canCallProtectedApis(
      _ref.read(sessionControllerProvider),
    )) {
      return;
    }

    var meResult = await _ref.read(profileRepositoryProvider).getMe();
    var validated = await _handleMeResult(meResult);
    if (!validated) {
      final authFailed = meResult.when(
        success: (_) => false,
        failure: _isAuthError,
      );
      if (authFailed) {
        final recovered = await sessionManager.recoverFromUnauthorized(
          dio: dio,
        );
        if (recovered) {
          meResult = await _ref.read(profileRepositoryProvider).getMe();
          validated = await _handleMeResult(meResult);
        }
        if (!validated &&
            meResult.when(
              success: (_) => false,
              failure: _isAuthError,
            )) {
          await sessionManager.invalidateSession(
            reason: '/me failed after refresh retry',
          );
          _log('Session invalid after /me — signed out');
        }
      }
    }

    if (validated) {
      unawaited(_ref.read(syncCoordinatorProvider).syncNow(background: true));
    }
  }

  Future<bool> _handleMeResult(ApiResult<MobileMeDto> meResult) async {
    return meResult.when(
      success: (profile) async {
        _ref.read(mobileMeProvider.notifier).hydrate(profile);
        return true;
      },
      failure: (error) async {
        if (_isAuthError(error)) {
          return false;
        }
        final cached = await _ref
            .read(profileRepositoryProvider)
            .readCachedProfile();
        if (cached != null) {
          _ref.read(mobileMeProvider.notifier).hydrate(cached);
          _log('Profile recovery — cached profile hydrated');
          return true;
        }
        _log(
          'Profile load failed (${error.code}) — continuing without profile',
        );
        return false;
      },
    );
  }

  bool _isAuthError(AppException error) {
    const codes = {
      '401',
      'UNAUTHORIZED',
      'UNAUTHORIZED_BEARER_REQUIRED',
      'TOKEN_INVALID',
      'FORBIDDEN_CUSTOMER_REQUIRED',
    };
    return codes.contains(error.code);
  }

  MaintenanceInfo? _resolveMaintenance(AppConfigDto? config) {
    if (config?.isMaintenanceMode != true) return null;
    return MaintenanceInfo(
      message: config?.maintenanceMessage?.trim().isNotEmpty == true
          ? config!.maintenanceMessage!.trim()
          : 'PraniDoctor is temporarily unavailable for maintenance. Please try again later.',
    );
  }

  ForceUpdateInfo? _resolveForceUpdate(
    AppConfigDto? config,
    String appVersion,
  ) {
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
      message:
          config?.updateMessage ??
          'A newer version of PraniDoctor is required to continue.',
    );
  }

  OptionalUpdateInfo? _resolveOptionalUpdate(
    AppConfigDto? config,
    String appVersion,
  ) {
    final recommended = config?.recommendedVersion?.trim();
    if (recommended == null || recommended.isEmpty) return null;
    if (!VersionUtils.isBelowMinimum(appVersion, recommended)) return null;

    final env = AppEnv.fromEnvironment();
    return OptionalUpdateInfo(
      recommendedVersion: recommended,
      currentVersion: appVersion,
      updateUrl: _firstNonEmpty([config?.updateUrl, env.updateUrl]),
      message:
          config?.updateMessage ??
          'A newer version of PraniDoctor is available with improvements and fixes.',
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

  void _applyMaintenanceFromError(AppException error) {
    state = state.copyWith(
      phase: BootPhase.maintenance,
      maintenance: MaintenanceInfo(message: error.message),
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

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Boot] $message');
    }
  }
}

final bootControllerProvider = StateNotifierProvider<BootController, BootState>(
  (ref) {
    return BootController(ref);
  },
);
