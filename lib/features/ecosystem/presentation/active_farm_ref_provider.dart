import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../farm/presentation/farm_providers.dart';

/// Active farm scope for Phase 4 APIs (`farmRef` = farm id).
final activeFarmRefProvider = Provider<String?>((ref) {
  return ref.watch(activeFarmIdProvider).valueOrNull;
});
