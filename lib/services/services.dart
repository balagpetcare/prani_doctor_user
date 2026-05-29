/// Discoverability facade for cross-cutting application services.
///
/// The concrete service implementations and their Riverpod providers continue
/// to live under `lib/core/**` (network, session, cache). This barrel offers a
/// single standardized import for the most commonly wired services without
/// moving the existing files, preserving backward compatibility.
///
/// `import 'package:pranidoctor_user/services/services.dart';`
library;

export '../core/errors/errors.dart';
export '../core/logging/logging.dart';
export '../core/network/dio_provider.dart';
// `appEnvProvider` is surfaced via config/app_environment.dart to avoid an
// ambiguous re-export; hide it here.
export '../core/network/network_providers.dart' hide appEnvProvider;
export '../core/session/session_providers.dart';
export '../core/cache/cache_providers.dart';
