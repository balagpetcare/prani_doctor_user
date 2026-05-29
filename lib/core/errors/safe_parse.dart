import '../error/app_exception.dart';
import '../logging/app_logger.dart';

/// Safe JSON / DTO parsing helpers that never throw raw [TypeError]s to the UI.
///
/// Repositories should prefer these over unchecked casts so invalid API payloads
/// surface as typed [AppException]s and are logged consistently.
abstract final class SafeParse {
  SafeParse._();

  /// Returns [value] when it is a `Map<String, dynamic>`, otherwise throws
  /// a typed [AppException].
  static Map<String, dynamic> map(
    Object? value, {
    String context = 'response',
  }) {
    if (value is Map<String, dynamic>) return value;
    throw AppException(
      message: 'Invalid $context format',
      code: 'INVALID_PAYLOAD',
    );
  }

  /// Returns [value] when it is a `List`, otherwise throws [AppException].
  static List<dynamic> list(
    Object? value, {
    String context = 'response',
  }) {
    if (value is List) return value;
    throw AppException(
      message: 'Invalid $context format',
      code: 'INVALID_PAYLOAD',
    );
  }

  /// Parses with [parser]; returns `null` and logs on failure (no throw).
  static T? tryParse<T>(
    Object? value,
    T Function(Map<String, dynamic> json) parser, {
    String context = 'dto',
  }) {
    try {
      final json = map(value, context: context);
      return parser(json);
    } catch (e, st) {
      AppLog.warn(
        'SafeParse.tryParse failed',
        tag: 'Parse',
        error: e,
        stackTrace: st,
        data: {'context': context},
      );
      return null;
    }
  }

  /// Parses a list of maps; skips invalid entries instead of failing the batch.
  static List<T> tryParseList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) parser, {
    String context = 'list',
  }) {
    final raw = list(value, context: context);
    final results = <T>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      final parsed = tryParse(item, parser, context: '$context[$i]');
      if (parsed != null) results.add(parsed);
    }
    return results;
  }

  static String? string(Object? value) =>
      value is String ? value : value?.toString();

  static int? integer(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? decimal(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool boolean(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return false;
  }
}
