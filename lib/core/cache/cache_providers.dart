import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_store.dart';

/// Overridden in [bootstrap] after Hive opens [kAppCacheBoxName].
final cacheStoreProvider = Provider<CacheStore>((ref) {
  throw StateError('CacheStore not bound; call bootstrap with ProviderScope overrides.');
});
