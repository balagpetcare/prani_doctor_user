import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_auth.dart';
import 'session_controller.dart';
import 'session_state.dart';

/// Narrow watch — avoids rebuild when unrelated [SessionState] fields change.
final protectedApisEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    sessionControllerProvider.select(SessionAuth.canCallProtectedApis),
  );
});

final sessionAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(
    sessionControllerProvider.select((SessionState s) => s.isAuthenticated),
  );
});
