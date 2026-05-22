import '../app_config/data/app_config_dto.dart';

enum BootPhase {
  splash,
  initializing,
  checkingUpdate,
  restoringSession,
  ready,
  forceUpdate,
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

class BootState {
  const BootState({
    this.phase = BootPhase.splash,
    this.config,
    this.configFromCache = false,
    this.forceUpdate,
    this.errorMessage,
    this.appVersion = '0.0.0',
  });

  final BootPhase phase;
  final AppConfigDto? config;
  final bool configFromCache;
  final ForceUpdateInfo? forceUpdate;
  final String? errorMessage;
  final String appVersion;

  bool get isReady => phase == BootPhase.ready;
  bool get forceUpdateRequired => phase == BootPhase.forceUpdate;
  bool get hasError => phase == BootPhase.error;

  BootState copyWith({
    BootPhase? phase,
    AppConfigDto? config,
    bool? configFromCache,
    ForceUpdateInfo? forceUpdate,
    String? errorMessage,
    String? appVersion,
    bool clearForceUpdate = false,
    bool clearError = false,
  }) {
    return BootState(
      phase: phase ?? this.phase,
      config: config ?? this.config,
      configFromCache: configFromCache ?? this.configFromCache,
      forceUpdate: clearForceUpdate ? null : (forceUpdate ?? this.forceUpdate),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
