import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai/data/ai_repository.dart';
import '../../features/animals/data/animal_repository.dart';
import '../../features/app_config/data/app_config_repository.dart';
import '../../features/app_config/presentation/app_config_provider.dart';
import '../../features/area/data/area_repository.dart';
import '../../features/batches/data/batch_repository.dart';
import '../../features/farm/data/farm_repository.dart';
import '../../features/feed/data/feed_repository.dart';
import '../../features/finance/data/finance_repository.dart';
import '../../features/health/data/health_repository.dart';
import '../../features/home/data/dashboard_repository.dart';
import '../../features/milk/data/milk_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/support/data/support_repository.dart';
import '../../features/treatment/data/treatment_repository.dart';
import '../../features/vaccine/data/vaccine_repository.dart';
import '../errors/safe_async.dart';
import '../localization/language_controller.dart';

/// Background Hive/cache warmups after [ProviderScope] is available.
///
/// Failures are logged via [SafeAsync] and never block first frame.
abstract final class StartupCacheWarmup {
  StartupCacheWarmup._();

  static Future<void> hydrate(WidgetRef ref) async {
    final cached = await ref.read(appConfigRepositoryProvider).readCachedConfig();
    if (cached != null) {
      ref.read(appConfigProvider.notifier).state = cached;
    }

    final localeCode = ref.read(languageControllerProvider).languageCode;
    _warm('area', () => ref.read(areaRepositoryProvider).warmFromDisk(locale: localeCode));
    if (localeCode != 'en') {
      _warm('area-en', () => ref.read(areaRepositoryProvider).warmFromDisk(locale: 'en'));
    }
    _warm('dashboard', ref.read(dashboardRepositoryProvider).readCachedDashboard);
    _warm('farms', ref.read(farmRepositoryProvider).readCachedFarmList);
    _warm('animals', ref.read(animalRepositoryProvider).readCachedList);
    _warm('batches', ref.read(batchRepositoryProvider).readCachedList);
    _warm('milk', ref.read(milkRepositoryProvider).readCachedList);
    _warm('feed', ref.read(feedRepositoryProvider).readCachedList);
    _warm('finance-expenses', ref.read(financeRepositoryProvider).readCachedExpenses);
    _warm('finance-income', ref.read(financeRepositoryProvider).readCachedIncome);
    _warm('health', ref.read(healthRepositoryProvider).readCachedList);
    _warm('health-timeline', ref.read(healthRepositoryProvider).readCachedTimeline);
    _warm('vaccine', ref.read(vaccineRepositoryProvider).readCachedList);
    _warm('vaccine-reminders', ref.read(vaccineRepositoryProvider).readCachedReminders);
    _warm('treatment', ref.read(treatmentRepositoryProvider).readCachedList);
    _warm('support-tickets', ref.read(supportRepositoryProvider).readCachedTickets);
    _warm('support-help', ref.read(supportRepositoryProvider).readCachedHelp);
    _warm('ai-history', ref.read(aiRepositoryProvider).readCachedHistory);
    _warm('ai-settings', ref.read(aiRepositoryProvider).readSettings);
    _warm('notifications', ref.read(notificationRepositoryProvider).readCachedList);
    _warm('notifications-unread', ref.read(notificationRepositoryProvider).readCachedUnreadCount);
    _warm('notifications-settings', ref.read(notificationRepositoryProvider).readCachedSettings);
    _warm('settings', ref.read(settingsRepositoryProvider).readCachedSettings);
  }

  static void _warm(String tag, Future<void> Function() action) {
    SafeAsync.fireAndForget(action, tag: 'Warmup:$tag');
  }
}
