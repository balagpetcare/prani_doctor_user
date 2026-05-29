/// Severity levels for [AppLog] output.
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

extension LogLevelX on LogLevel {
  String get label => switch (this) {
    LogLevel.debug => 'DEBUG',
    LogLevel.info => 'INFO',
    LogLevel.warn => 'WARN',
    LogLevel.error => 'ERROR',
  };
}
