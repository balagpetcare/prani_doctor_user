import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controller.dart' show secureStorageProvider;
import 'token_storage.dart';

/// Re-exports the shared secure-storage provider for discoverability from the
/// `core/storage` layer (its canonical definition stays in the session layer to
/// preserve existing imports).
export '../session/session_controller.dart' show secureStorageProvider;

/// Provides an isolated [TokenStorage] backed by the shared secure storage.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});
