import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/provider_stability.dart';
import '../../../../core/session/session_providers.dart';
import '../../../animals/presentation/animal_providers.dart';
import '../../../doctors/data/doctor_repository.dart';
import '../../../doctors/data/provider_dto.dart';
import '../../../finance/data/finance_dto.dart';
import '../../../finance/presentation/finance_providers.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../service_requests/data/service_request_repository.dart';
import '../../../support/presentation/support_providers.dart';
import '../../../treatment/presentation/treatment_providers.dart';
import '../../../vaccine/presentation/vaccine_providers.dart';
import '../home_analytics.dart';
import '../models/home_section_models.dart';
import 'home_community_provider.dart';
import 'home_marketplace_provider.dart';
import 'home_orders_provider.dart';

/// Composed summary from animal list + vaccine reminders + treatments (no dashboard metrics duplicate).
final homeAnimalSummaryProvider = FutureProvider<HomeAnimalSummaryMetrics>((
  ref,
) async {
  ref.persistProvider('homeAnimalSummary');
  if (!ref.watch(protectedApisEnabledProvider)) {
    return HomeAnimalSummaryMetrics.empty;
  }

  try {
    final animals = await ref.watch(animalListProvider.future);
    final reminders = await ref.watch(vaccineReminderProvider.future);

    var activeTreatments = 0;
    var treatmentFromCache = false;
    try {
      final treatment = await ref.watch(treatmentSummaryProvider.future);
      activeTreatments = treatment.active;
      treatmentFromCache = treatment.fromCache;
    } catch (_) {}

    final vaccineDue = reminders.overdue.length + reminders.upcoming.length;
    final fromCache =
        animals.fromCache || reminders.fromCache || treatmentFromCache;

    final metrics = HomeAnimalSummaryMetrics(
      totalAnimals: animals.total,
      vaccineDue: vaccineDue,
      activeTreatments: activeTreatments,
      tasks: vaccineDue,
      fromCache: fromCache,
    );
    HomeAnalytics.sectionLoaded('summary', fromCache: fromCache);
    return metrics;
  } catch (e) {
    HomeAnalytics.sectionError('summary');
    return HomeAnimalSummaryMetrics.empty;
  }
});

/// Health tasks from vaccine reminders API only (`/api/mobile/vaccines/reminders`).
final homeHealthTasksProvider = FutureProvider<List<HomeHealthTask>>((
  ref,
) async {
  ref.persistProvider('homeHealthTasks');
  if (!ref.watch(protectedApisEnabledProvider)) return const [];

  try {
    final reminders = await ref.watch(vaccineReminderProvider.future);
    final tasks = <HomeHealthTask>[
      ...reminders.overdue.map((r) => r.toOverdueTask()),
      ...reminders.upcoming.map((r) => r.toUpcomingTask()),
    ];
    if (tasks.isEmpty) {
      HomeAnalytics.sectionEmpty('tasks');
    } else {
      HomeAnalytics.sectionLoaded('tasks', fromCache: reminders.fromCache);
    }
    return tasks;
  } catch (e) {
    HomeAnalytics.sectionError('tasks');
    rethrow;
  }
});

/// Doctor preview via providers/clinic list API (shared [doctorListProvider]).
final homeDoctorsPreviewProvider =
    FutureProvider<List<ProviderDoctorListItemDto>>((ref) async {
      ref.persistProvider('homeDoctorsPreview');
      if (!ref.watch(protectedApisEnabledProvider)) return const [];

      try {
        final result = await ref.watch(doctorListProvider.future);
        final doctors = result.doctors.take(5).toList();
        if (doctors.isEmpty) {
          HomeAnalytics.sectionEmpty('doctors');
        } else {
          HomeAnalytics.sectionLoaded('doctors');
        }
        return doctors;
      } catch (e) {
        HomeAnalytics.sectionError('doctors');
        rethrow;
      }
    });

/// Paginated animal preview — single source with summary (`animalListProvider`).
final homeAnimalsPreviewProvider = Provider<AsyncValue<AnimalListState>>((ref) {
  return ref.watch(animalListProvider);
});

/// Recent notifications preview (`notificationListProvider` + cache).
final homeNotificationsPreviewProvider =
    Provider<AsyncValue<NotificationListState>>((ref) {
      return ref.watch(notificationListProvider);
    });

/// Finance/media reports preview (`financeReportsProvider` + cache).
final homeReportsPreviewProvider = Provider<AsyncValue<FinanceReportsData>>((
  ref,
) {
  return ref.watch(financeReportsProvider);
});

/// Invalidate all home-composed sections and their upstream cached providers.
void invalidateHomeSections(Ref ref) {
  ref.invalidate(homeAnimalSummaryProvider);
  ref.invalidate(homeHealthTasksProvider);
  ref.invalidate(homeDoctorsPreviewProvider);
  ref.invalidate(homeMarketplacePreviewProvider);
  ref.invalidate(homeCommunityPreviewProvider);
  ref.invalidate(homeOrdersSummaryProvider);
  ref.invalidate(homeOrdersListProvider);
  ref.invalidate(vaccineReminderProvider);
  ref.invalidate(treatmentSummaryProvider);
  ref.invalidate(doctorListProvider);
  ref.invalidate(serviceCategoriesProvider);
  ref.invalidate(financeReportsProvider);
  ref.invalidate(notificationListProvider);
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(supportHelpProvider);
  ref.invalidate(homeCommunityFeedProvider);
}
