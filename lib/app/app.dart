import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/presentation/profile_providers.dart';
import '../routing/app_router.dart';
import '../theme/theme_controller.dart';
import '../core/network/app_lifecycle_coordinator.dart';
import '../features/notifications/notification_coordinator.dart';
import '../features/offline/offline_coordinator.dart';
import 'app_startup.dart';

class PraniDoctorApp extends ConsumerWidget {
  const PraniDoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(profileLocaleControllerProvider);
    final light = ref.watch(lightThemeProvider);
    final dark = ref.watch(darkThemeProvider);

    return AppStartup(
      child: AppLifecycleCoordinator(
        child: OfflineCoordinator(
          child: NotificationCoordinator(
            child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            theme: light,
            darkTheme: dark,
            themeMode: themeMode,
            routerConfig: router,
            ),
          ),
        ),
      ),
    );
  }
}
