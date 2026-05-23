/// Guards against null, NaN, and Infinity when parsing or converting numbers.
library;

double safeDouble(Object? value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value.isFinite ? value : fallback;
  if (value is int) return value.toDouble();
  if (value is num) {
    final parsed = value.toDouble();
    return parsed.isFinite ? parsed : fallback;
  }
  final parsed = double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) return fallback;
  return parsed;
}

int safeInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) {
    final parsed = value.toDouble();
    if (!parsed.isFinite) return fallback;
    return parsed.round();
  }
  final parsed = int.tryParse('$value');
  return parsed ?? fallback;
}

int? safeNullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) {
    final parsed = value.toDouble();
    if (!parsed.isFinite) return null;
    return parsed.round();
  }
  return int.tryParse('$value');
}

double? safeNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value.isFinite ? value : null;
  if (value is int) return value.toDouble();
  if (value is num) {
    final parsed = value.toDouble();
    return parsed.isFinite ? parsed : null;
  }
  final parsed = double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) return null;
  return parsed;
}

double safePercent(num? numerator, num? denominator, {double fallback = 0}) {
  if (numerator == null || denominator == null) return fallback;
  final n = safeDouble(numerator);
  final d = safeDouble(denominator);
  if (d <= 0) return fallback;
  final ratio = n / d;
  return ratio.isFinite ? ratio.clamp(0, 1) : fallback;
}

/// Returns a finite pixel cache dimension, or null when layout is unbounded.
int? safeCacheDimension(double? logicalSize, double devicePixelRatio) {
  if (logicalSize == null) return null;
  if (!logicalSize.isFinite || logicalSize <= 0) return null;
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) return null;
  final pixels = logicalSize * devicePixelRatio;
  if (!pixels.isFinite || pixels <= 0) return null;
  return pixels.round().clamp(1, 8192);
}
