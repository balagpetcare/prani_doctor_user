import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/presentation/ai_providers.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../batches/presentation/batch_providers.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../health/presentation/health_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../milk/presentation/milk_providers.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../../service_requests/data/service_request_repository.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../support/presentation/support_providers.dart';
import '../../treatment/presentation/treatment_providers.dart';
import '../../vaccine/presentation/vaccine_providers.dart';
import '../offline_providers.dart';
import 'outbox_item.dart';

/// Domains affected by offline outbox drain — used for targeted invalidation.
enum SyncDomain {
  profile,
  serviceRequest,
  animal,
  batch,
  milk,
  feed,
  finance,
  health,
  vaccine,
  treatment,
  support,
  ai,
  settings,
}

SyncDomain? syncDomainForOutboxKind(OutboxKind kind) {
  switch (kind) {
    case OutboxKind.profilePatch:
      return SyncDomain.profile;
    case OutboxKind.serviceRequest:
      return SyncDomain.serviceRequest;
    case OutboxKind.animalCreate:
    case OutboxKind.animalPatch:
      return SyncDomain.animal;
    case OutboxKind.batchCreate:
    case OutboxKind.batchPatch:
    case OutboxKind.batchMove:
    case OutboxKind.batchMerge:
      return SyncDomain.batch;
    case OutboxKind.milkCreate:
    case OutboxKind.milkPatch:
    case OutboxKind.milkDelete:
      return SyncDomain.milk;
    case OutboxKind.feedCreate:
    case OutboxKind.feedPatch:
    case OutboxKind.feedDelete:
      return SyncDomain.feed;
    case OutboxKind.financeExpenseCreate:
    case OutboxKind.financeExpensePatch:
    case OutboxKind.financeExpenseDelete:
    case OutboxKind.financeIncomeCreate:
    case OutboxKind.financeIncomePatch:
    case OutboxKind.financeIncomeDelete:
      return SyncDomain.finance;
    case OutboxKind.healthCreate:
    case OutboxKind.healthPatch:
    case OutboxKind.healthDelete:
      return SyncDomain.health;
    case OutboxKind.vaccineCreate:
    case OutboxKind.vaccinePatch:
    case OutboxKind.vaccineDelete:
      return SyncDomain.vaccine;
    case OutboxKind.treatmentCreate:
    case OutboxKind.treatmentPatch:
    case OutboxKind.treatmentDelete:
      return SyncDomain.treatment;
    case OutboxKind.supportTicketCreate:
    case OutboxKind.supportTicketReply:
    case OutboxKind.supportTicketPatch:
      return SyncDomain.support;
    case OutboxKind.aiChatMessage:
      return SyncDomain.ai;
    case OutboxKind.settingsSync:
      return SyncDomain.settings;
    case OutboxKind.offlineLead:
      return null;
  }
}

void invalidateSyncDomains(Ref ref, Set<SyncDomain> domains) {
  if (domains.isEmpty) return;

  ref.invalidate(localOutboxCountProvider);
  ref.invalidate(offlineSyncStatusProvider);

  for (final domain in domains) {
    switch (domain) {
      case SyncDomain.profile:
        invalidateDashboardSections(ref);
      case SyncDomain.serviceRequest:
        ref.invalidate(serviceRequestListProvider);
        invalidateDashboardSections(ref);
      case SyncDomain.animal:
        ref.invalidate(animalListProvider);
      case SyncDomain.batch:
        ref.invalidate(batchListProvider);
      case SyncDomain.milk:
        ref.invalidate(milkListProvider);
        ref.invalidate(milkSummaryProvider);
        ref.invalidate(milkChartsProvider);
      case SyncDomain.feed:
        ref.invalidate(feedListProvider);
        ref.invalidate(feedCostProvider);
        ref.invalidate(feedAnalyticsProvider);
      case SyncDomain.finance:
        ref.invalidate(financeExpenseListProvider);
        ref.invalidate(financeIncomeListProvider);
        ref.invalidate(financeProfitProvider);
        ref.invalidate(financeChartsProvider);
        ref.invalidate(financeReportsProvider);
      case SyncDomain.health:
        ref.invalidate(healthProvider);
        ref.invalidate(healthTimelineProvider);
        ref.invalidate(healthSummaryProvider);
        ref.invalidate(healthAnalyticsProvider);
        ref.invalidate(healthRecentEventsProvider);
      case SyncDomain.vaccine:
        ref.invalidate(vaccineProvider);
        ref.invalidate(vaccineHistoryProvider);
        ref.invalidate(vaccineReminderProvider);
        ref.invalidate(vaccineSummaryProvider);
        ref.invalidate(vaccineCalendarProvider);
      case SyncDomain.treatment:
        ref.invalidate(treatmentProvider);
        ref.invalidate(treatmentSummaryProvider);
        ref.invalidate(treatmentTimelineProvider);
        ref.invalidate(treatmentMedicinePlanProvider);
        ref.invalidate(treatmentFollowUpProvider);
      case SyncDomain.support:
        ref.invalidate(supportTicketListProvider);
        ref.invalidate(supportHelpProvider);
      case SyncDomain.ai:
        ref.invalidate(aiChatProvider);
      case SyncDomain.settings:
        ref.invalidate(settingsProvider);
    }
  }

  if (domains.contains(SyncDomain.profile) ||
      domains.contains(SyncDomain.serviceRequest)) {
    ref.invalidate(unreadNotificationCountProvider);
  }
}
