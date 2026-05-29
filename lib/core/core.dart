/// Lean barrel for the most frequently imported core building blocks:
/// error model, network client/helpers, and the localization surface.
///
/// Feature code may still import individual core files directly; this barrel is
/// an optional convenience for common combinations.
library;

export 'errors/errors.dart';
export 'logging/logging.dart';
export 'network/api_envelope.dart';
export 'network/dio_helpers.dart';
export 'network/dio_provider.dart';
export 'localization/localization.dart';
export 'riverpod/riverpod_helpers.dart';
