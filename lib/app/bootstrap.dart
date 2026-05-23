import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cache_providers.dart';
import '../core/cache/cache_store.dart';
import '../core/cache/hive_bootstrap.dart';
import '../core/firebase/firebase_bootstrap.dart';
import '../features/notifications/fcm_background.dart';
import 'app.dart';
import 'app_env.dart';

Future<void> bootstrap() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    developer.log(
      details.exceptionAsString(),
      name: 'FlutterError',
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initHiveCache();
  final cache = CacheStore(openCacheBox());
  final env = AppEnv.fromEnvironment();
  env.assertProductionReady();
  env.logDebugSummary();

  // Firebase must be ready before ProviderScope (NotificationService is lazy but
  // FCM background handler registration still requires a default app when push on).
  final firebaseReady = await ensureFirebaseInitialized();
  if (env.enablePush && firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    ProviderScope(
      overrides: [cacheStoreProvider.overrideWithValue(cache)],
      child: const PraniDoctorApp(),
    ),
  );
}
