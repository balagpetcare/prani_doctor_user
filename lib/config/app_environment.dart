/// Stable, standardized import surface for environment configuration.
///
/// The concrete implementation currently lives in `lib/app/app_env.dart` and
/// `lib/core/network/network_constants.dart`. This bridge gives the rest of the
/// app a single canonical import (`config/app_environment.dart`) without moving
/// the existing files, preserving backward compatibility of current imports.
library;

export '../app/app_env.dart';
export '../core/network/network_constants.dart';
export '../core/network/network_providers.dart' show appEnvProvider;
