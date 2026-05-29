import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/cache/cache_providers.dart';
import '../core/cache/cache_store.dart';
import '../core/cache/hive_bootstrap.dart';
import '../core/errors/global_error_handler.dart';
import '../core/firebase/firebase_bootstrap.dart';
import '../core/localization/localization_loader.dart';
import '../core/logging/sentry_bootstrap.dart';
import '../core/logging/crash_reporter_factory.dart';
import '../core/logging/crash_reporting_bootstrap.dart';
import '../core/logging/crash_reporting_provider_observer.dart';
import '../core/startup/image_cache_config.dart';
import '../features/notifications/fcm_background.dart';
import 'app.dart';
import 'app_env.dart';

Future<void> bootstrap() async {
  final env = AppEnv.fromEnvironment();
  await SentryBootstrap.initIfConfigured(env);
  final crashReporter = resolveCrashReporter(env: env);
  await GlobalErrorHandler.runGuarded(
    () => _bootstrapApp(env),
    crashReporter: crashReporter,
  );
}

Future<void> _bootstrapApp(AppEnv env) async {
  CrashReportingBootstrap.applyEnvironment(env);

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  ImageCacheConfig.apply();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initHiveCache();

  // Locale strings + intl symbols can load in parallel after Hive is ready.
  await Future.wait([
    LocalizationLoader.ensureInitialized(),
    initializeDateFormatting('bn'),
    initializeDateFormatting('en'),
  ]);

  final cache = CacheStore(openCacheBox());
  env.assertProductionReady();
  env.logDebugSummary();

  final firebaseReady = await ensureFirebaseInitialized();
  if (firebaseReady) {
    await CrashReportingBootstrap.activateFirebaseReporting(env);
  }
  await CrashReportingBootstrap.applyReleaseInfo();

  env.assertPushReady(firebaseReady: firebaseReady);
  if (env.enablePush && firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } else if (env.enablePush && !firebaseReady && kReleaseMode) {
    // Push requested but Firebase not configured — non-fatal; logged for release audits.
    debugPrint(
      '[Bootstrap] ENABLE_PUSH=true but Firebase is not initialized. '
      'Add google-services.json and FlutterFire options for production push.',
    );
  }

  runApp(
    ProviderScope(
      observers: const [CrashReportingProviderObserver()],
      overrides: [cacheStoreProvider.overrideWithValue(cache)],
      child: const PraniDoctorApp(),
    ),
  );
}
