import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../features/app_config/data/app_config_repository.dart';
import '../features/app_config/presentation/app_config_provider.dart';
import '../features/area/data/area_repository.dart';
import '../features/feed/data/feed_repository.dart';
import '../features/finance/data/finance_repository.dart';
import '../features/health/data/health_repository.dart';
import '../features/vaccine/data/vaccine_repository.dart';
import '../features/treatment/data/treatment_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/milk/data/milk_repository.dart';
import '../features/batches/data/batch_repository.dart';
import '../features/animals/data/animal_repository.dart';
import '../features/farm/data/farm_repository.dart';
import '../features/home/data/dashboard_repository.dart';

/// Preloads cached app config after [ProviderScope] is available.
class AppStartup extends ConsumerStatefulWidget {
  const AppStartup({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<AppStartup> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_hydrateCachedConfig);
  }

  Future<void> _hydrateCachedConfig() async {
    final cached = await ref.read(appConfigRepositoryProvider).readCachedConfig();
    if (cached != null) {
      ref.read(appConfigProvider.notifier).state = cached;
    }
    unawaited(ref.read(areaRepositoryProvider).warmFromDisk());
    unawaited(ref.read(areaRepositoryProvider).warmFromDisk(locale: 'en'));
    unawaited(ref.read(dashboardRepositoryProvider).readCachedDashboard());
    unawaited(ref.read(farmRepositoryProvider).readCachedFarmList());
    unawaited(ref.read(animalRepositoryProvider).readCachedList());
    unawaited(ref.read(batchRepositoryProvider).readCachedList());
    unawaited(ref.read(milkRepositoryProvider).readCachedList());
    unawaited(ref.read(feedRepositoryProvider).readCachedList());
    unawaited(ref.read(financeRepositoryProvider).readCachedExpenses());
    unawaited(ref.read(financeRepositoryProvider).readCachedIncome());
    unawaited(ref.read(healthRepositoryProvider).readCachedList());
    unawaited(ref.read(healthRepositoryProvider).readCachedTimeline());
    unawaited(ref.read(vaccineRepositoryProvider).readCachedList());
    unawaited(ref.read(vaccineRepositoryProvider).readCachedReminders());
    unawaited(ref.read(treatmentRepositoryProvider).readCachedList());
    unawaited(ref.read(notificationRepositoryProvider).readCachedList());
    unawaited(ref.read(notificationRepositoryProvider).readCachedUnreadCount());
    unawaited(ref.read(notificationRepositoryProvider).readCachedSettings());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
