import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/provider_stability.dart';
import '../../../../core/session/session_providers.dart';
import '../../../doctors/data/doctor_repository.dart';
import '../../../doctors/data/provider_dto.dart';
import '../../../service_requests/data/service_request_repository.dart';
import '../home_analytics.dart';
import '../models/home_section_models.dart';

/// Composed marketplace preview: service categories + featured provider offers.
/// Reuses [serviceCategoriesProvider] and [doctorListProvider] — no duplicate API layer.
final homeMarketplacePreviewProvider = FutureProvider<HomeMarketplacePreview>((
  ref,
) async {
  ref.persistProvider('homeMarketplacePreview');
  if (!ref.watch(protectedApisEnabledProvider)) {
    return HomeMarketplacePreview.empty;
  }

  try {
    final categories = await ref.watch(serviceCategoriesProvider.future);
    var offers = const <ProviderDoctorListItemDto>[];
    try {
      final doctors = await ref.watch(doctorListProvider.future);
      offers = doctors.doctors.take(6).toList();
    } catch (_) {}

    final items = <HomeMarketplacePreviewItem>[
      ...categories
          .take(6)
          .map(
            (c) => HomeMarketplacePreviewItem(
              id: 'cat-${c.id}',
              title: c.name,
              subtitle: c.description ?? c.slug,
              kind: HomeMarketplaceItemKind.category,
              routeTargetId: c.slug,
            ),
          ),
      ...offers.map(
        (d) => HomeMarketplacePreviewItem(
          id: 'doc-${d.id}',
          title: d.name,
          subtitle: d.fee ?? d.serviceType,
          kind: HomeMarketplaceItemKind.offer,
          routeTargetId: d.id,
        ),
      ),
    ];

    if (items.isEmpty) {
      HomeAnalytics.sectionEmpty('marketplace');
    } else {
      HomeAnalytics.sectionLoaded('marketplace');
    }

    return HomeMarketplacePreview(
      items: items.take(10).toList(),
      categoryCount: categories.length,
      offerCount: offers.length,
    );
  } catch (e) {
    HomeAnalytics.sectionError('marketplace');
    rethrow;
  }
});

/// Full marketplace catalog for the marketplace page (same upstream providers).
final homeMarketplaceCatalogProvider = FutureProvider<HomeMarketplacePreview>((
  ref,
) async {
  return ref.watch(homeMarketplacePreviewProvider.future);
});
