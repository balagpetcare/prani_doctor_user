/// Redacts sensitive values before they reach logs or crash reporters.
///
/// Applied to log messages, query strings, and header maps. Never log raw
/// tokens, passwords, or OTP codes — even in debug builds.
abstract final class LogRedactor {
  LogRedactor._();

  static final _patterns = <RegExp>[
    RegExp(
      r'(authorization|bearer|token|password|passwd|otp|secret|api[_-]?key|refresh[_-]?token)\s*[:=]\s*\S+',
      caseSensitive: false,
    ),
    RegExp(r'Bearer\s+[\w\-\.]+', caseSensitive: false),
  ];

  static const _replacement = '[REDACTED]';

  /// Redacts known sensitive patterns in [input].
  static String redact(String input) {
    var result = input;
    for (final pattern in _patterns) {
      result = result.replaceAllMapped(pattern, (_) => _replacement);
    }
    return result;
  }

  /// Returns a copy of [headers] with sensitive keys masked.
  static Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    const sensitiveKeys = {
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'x-auth-token',
    };
    return headers.map((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        return MapEntry(key, _replacement);
      }
      return MapEntry(key, value);
    });
  }

  /// Strips query parameters that commonly carry secrets.
  static String redactUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      const sensitiveParams = {'token', 'access_token', 'refresh_token', 'otp', 'code'};
      if (parsed.queryParameters.keys.every((k) => !sensitiveParams.contains(k.toLowerCase()))) {
        return redact(uri);
      }
      final filtered = Map<String, String>.from(parsed.queryParameters)
        ..removeWhere((k, _) => sensitiveParams.contains(k.toLowerCase()));
      return redact(parsed.replace(queryParameters: filtered).toString());
    } catch (_) {
      return redact(uri);
    }
  }
}
