import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cache_providers.dart';
import '../core/cache/cache_store.dart';
import '../core/cache/hive_bootstrap.dart';
import '../features/notifications/notification_coordinator.dart';
import 'app.dart';
import 'app_env.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initHiveCache();
  final cache = CacheStore(openCacheBox());
  final env = AppEnv.fromEnvironment();
  env.assertProductionReady();

  if (env.enablePush) {
    registerFcmBackgroundHandler();
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase not ready (add google-services / Firebase options): $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        cacheStoreProvider.overrideWithValue(cache),
      ],
      child: const PraniDoctorApp(),
    ),
  );
}
