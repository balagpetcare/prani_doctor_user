import 'package:flutter/material.dart';

import '../../../../routing/app_routes.dart';
import '../../../service_requests/data/service_request_dto.dart';
import '../../../vaccine/data/vaccine_dto.dart';
import '../../../treatment/data/treatment_dto.dart';

/// Aggregated animal summary metrics for the home dashboard cards.
class HomeAnimalSummaryMetrics {
  const HomeAnimalSummaryMetrics({
    required this.totalAnimals,
    required this.vaccineDue,
    required this.activeTreatments,
    required this.tasks,
    this.fromCache = false,
  });

  final int totalAnimals;
  final int vaccineDue;
  final int activeTreatments;
  final int tasks;
  final bool fromCache;

  static const empty = HomeAnimalSummaryMetrics(
    totalAnimals: 0,
    vaccineDue: 0,
    activeTreatments: 0,
    tasks: 0,
  );
}

enum HomeHealthTaskKind {
  vaccineOverdue,
  vaccineUpcoming,
  appointment,
  treatmentFollowUp,
}

class HomeHealthTask {
  const HomeHealthTask({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorKind,
    this.route,
  });

  final String id;
  final HomeHealthTaskKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final HomeHealthTaskColorKind colorKind;
  final String? route;
}

enum HomeHealthTaskColorKind { error, primary, secondary }

class HomeQuickActionItem {
  const HomeQuickActionItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isEmergency = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isEmergency;
}

extension HomeHealthTaskFromVaccine on VaccineRecord {
  HomeHealthTask toOverdueTask() => HomeHealthTask(
    id: 'vaccine-overdue-$id',
    kind: HomeHealthTaskKind.vaccineOverdue,
    title: vaccineName,
    subtitle: targetLabel,
    icon: Icons.warning_amber_outlined,
    colorKind: HomeHealthTaskColorKind.error,
    route: AppRoutes.vaccineReminders,
  );

  HomeHealthTask toUpcomingTask() => HomeHealthTask(
    id: 'vaccine-upcoming-$id',
    kind: HomeHealthTaskKind.vaccineUpcoming,
    title: vaccineName,
    subtitle: targetLabel,
    icon: Icons.event_outlined,
    colorKind: HomeHealthTaskColorKind.primary,
    route: AppRoutes.vaccineReminders,
  );
}

extension HomeHealthTaskFromAppointment on ServiceRequestDto {
  HomeHealthTask toTask(String fallbackLabel) => HomeHealthTask(
    id: 'appointment-$id',
    kind: HomeHealthTaskKind.appointment,
    title: serviceCategory?.name ?? problemOrSymptom.ifEmpty(fallbackLabel),
    subtitle: [
      if (animal?.name != null) animal!.name,
      scheduledStart ?? preferredTime ?? createdAt ?? '',
    ].where((e) => e.isNotEmpty).join(' · '),
    icon: Icons.event_available_outlined,
    colorKind: HomeHealthTaskColorKind.secondary,
    route: AppRoutes.serviceRequestDetail(id),
  );
}

extension HomeHealthTaskFromTreatment on FarmTreatment {
  HomeHealthTask toFollowUpTask() => HomeHealthTask(
    id: 'treatment-$id',
    kind: HomeHealthTaskKind.treatmentFollowUp,
    title: title.isNotEmpty ? title : (diagnosis ?? ''),
    subtitle: endDate != null
        ? endDate!.toIso8601String().substring(0, 10)
        : '',
    icon: Icons.medical_services_outlined,
    colorKind: HomeHealthTaskColorKind.primary,
  );
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

enum HomeMarketplaceItemKind { category, offer, product }

class HomeMarketplacePreviewItem {
  const HomeMarketplacePreviewItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.routeTargetId,
  });

  final String id;
  final String title;
  final String subtitle;
  final HomeMarketplaceItemKind kind;
  final String? routeTargetId;
}

class HomeMarketplacePreview {
  const HomeMarketplacePreview({
    required this.items,
    required this.categoryCount,
    required this.offerCount,
    this.fromCache = false,
  });

  final List<HomeMarketplacePreviewItem> items;
  final int categoryCount;
  final int offerCount;
  final bool fromCache;

  static const empty = HomeMarketplacePreview(
    items: [],
    categoryCount: 0,
    offerCount: 0,
  );

  bool get isEmpty => items.isEmpty;
}

enum HomeCommunityContentKind { tip, article, video, post }

class HomeCommunityItem {
  const HomeCommunityItem({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.category,
  });

  final String id;
  final String title;
  final String body;
  final HomeCommunityContentKind kind;
  final String category;
}

class HomeCommunityPreview {
  const HomeCommunityPreview({
    required this.items,
    required this.totalCount,
    this.fromCache = false,
  });

  final List<HomeCommunityItem> items;
  final int totalCount;
  final bool fromCache;

  static const empty = HomeCommunityPreview(items: [], totalCount: 0);

  bool get isEmpty => items.isEmpty;
}

class HomeOrdersSummary {
  const HomeOrdersSummary({
    required this.pending,
    required this.completed,
    required this.cancelled,
    required this.recent,
    this.fromCache = false,
  });

  final int pending;
  final int completed;
  final int cancelled;
  final List<ServiceRequestDto> recent;
  final bool fromCache;

  static const empty = HomeOrdersSummary(
    pending: 0,
    completed: 0,
    cancelled: 0,
    recent: [],
  );

  int get total => pending + completed + cancelled;
}
