import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/provider_stability.dart';
import '../../../../core/session/session_providers.dart';
import '../../../service_requests/data/service_request_dto.dart';
import '../../../service_requests/data/service_request_repository.dart';
import '../home_analytics.dart';
import '../models/home_section_models.dart';

/// All service requests for orders views — uses existing repository list endpoint.
final homeOrdersListProvider = FutureProvider<List<ServiceRequestDto>>((
  ref,
) async {
  ref.persistProvider('homeOrdersList');
  if (!ref.watch(protectedApisEnabledProvider)) return const [];

  final result = await ref
      .read(serviceRequestRepositoryProvider)
      .listRequests(limit: 100);
  return result.when(success: (data) => data.requests, failure: (e) => throw e);
});

/// Pending / completed / cancelled counts from service requests.
final homeOrdersSummaryProvider = FutureProvider<HomeOrdersSummary>((
  ref,
) async {
  ref.persistProvider('homeOrdersSummary');
  if (!ref.watch(protectedApisEnabledProvider)) {
    return HomeOrdersSummary.empty;
  }

  try {
    final requests = await ref.watch(homeOrdersListProvider.future);
    var pending = 0;
    var completed = 0;
    var cancelled = 0;

    for (final request in requests) {
      if (request.status.isActive ||
          request.status == ServiceRequestStatus.pending) {
        pending++;
      } else if (request.status.isCompleted) {
        completed++;
      } else if (request.status.isClosed) {
        cancelled++;
      }
    }

    HomeAnalytics.sectionLoaded('orders');

    return HomeOrdersSummary(
      pending: pending,
      completed: completed,
      cancelled: cancelled,
      recent: requests.take(20).toList(),
    );
  } catch (e) {
    HomeAnalytics.sectionError('orders');
    rethrow;
  }
});
