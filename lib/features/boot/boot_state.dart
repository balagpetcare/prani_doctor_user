import '../app_config/data/app_config_dto.dart';

enum BootPhase {
  splash,
  initializing,
  checkingUpdate,
  restoringSession,
  ready,
  forceUpdate,
  optionalUpdate,
  maintenance,
  error,
}

class ForceUpdateInfo {
  const ForceUpdateInfo({
    required this.minimumVersion,
    required this.currentVersion,
    required this.message,
    this.updateUrl,
  });

  final String minimumVersion;
  final String currentVersion;
  final String message;
  final String? updateUrl;
}

class OptionalUpdateInfo {
  const OptionalUpdateInfo({
    required this.recommendedVersion,
    required this.currentVersion,
    required this.message,
    this.updateUrl,
  });

  final String recommendedVersion;
  final String currentVersion;
  final String message;
  final String? updateUrl;
}

class MaintenanceInfo {
  const MaintenanceInfo({required this.message});

  final String message;
}

class BootState {
  const BootState({
    this.phase = BootPhase.splash,
    this.config,
    this.configFromCache = false,
    this.forceUpdate,
    this.optionalUpdate,
    this.maintenance,
    this.errorMessage,
    this.appVersion = '0.0.0',
  });

  final BootPhase phase;
  final AppConfigDto? config;
  final bool configFromCache;
  final ForceUpdateInfo? forceUpdate;
  final OptionalUpdateInfo? optionalUpdate;
  final MaintenanceInfo? maintenance;
  final String? errorMessage;
  final String appVersion;

  bool get isReady => phase == BootPhase.ready;
  bool get forceUpdateRequired => phase == BootPhase.forceUpdate;
  bool get optionalUpdatePending => phase == BootPhase.optionalUpdate;
  bool get maintenanceActive => phase == BootPhase.maintenance;
  bool get hasError => phase == BootPhase.error;
  bool get isBlocked =>
      forceUpdateRequired || maintenanceActive || optionalUpdatePending;

  BootState copyWith({
    BootPhase? phase,
    AppConfigDto? config,
    bool? configFromCache,
    ForceUpdateInfo? forceUpdate,
    OptionalUpdateInfo? optionalUpdate,
    MaintenanceInfo? maintenance,
    String? errorMessage,
    String? appVersion,
    bool clearForceUpdate = false,
    bool clearOptionalUpdate = false,
    bool clearMaintenance = false,
    bool clearError = false,
  }) {
    return BootState(
      phase: phase ?? this.phase,
      config: config ?? this.config,
      configFromCache: configFromCache ?? this.configFromCache,
      forceUpdate: clearForceUpdate ? null : (forceUpdate ?? this.forceUpdate),
      optionalUpdate: clearOptionalUpdate
          ? null
          : (optionalUpdate ?? this.optionalUpdate),
      maintenance: clearMaintenance ? null : (maintenance ?? this.maintenance),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
