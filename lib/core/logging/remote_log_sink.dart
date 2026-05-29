import 'log_level.dart';

/// Contract for shipping structured logs to a remote backend (Datadog, Cloud Logging).
abstract interface class RemoteLogSink {
  void write({
    required LogLevel level,
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  });
}

/// No-op until a remote sink is configured.
final class NoOpRemoteLogSink implements RemoteLogSink {
  const NoOpRemoteLogSink();

  @override
  void write({
    required LogLevel level,
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {}
}
