import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/navigation/navigation_guard.dart';
import '../../../../routing/app_routes.dart';
import '../../../doctors/data/doctor_repository.dart';
import '../../../service_requests/data/service_request_repository.dart';
import '../home_analytics.dart';
import '../models/home_section_models.dart';
import '../providers/home_marketplace_provider.dart';
import '../theme/home_tokens.dart';
import '../widgets/home_card.dart';

class MarketplacePage extends ConsumerWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalogAsync = ref.watch(homeMarketplaceCatalogProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.homeMarketplaceTitle)),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: HomeErrorRetry(
            message: l10n.dashboardSectionError,
            onRetry: () => ref.invalidate(homeMarketplaceCatalogProvider),
          ),
        ),
        data: (preview) {
          if (preview.isEmpty) {
            return HomeEmptyState(
              message: l10n.homeMarketplaceEmpty,
              icon: Icons.storefront_outlined,
              actionLabel: l10n.findDoctors,
              onAction: () => context.go(AppRoutes.services),
            );
          }

          final categories = preview.items
              .where((i) => i.kind == HomeMarketplaceItemKind.category)
              .toList();
          final offers = preview.items
              .where((i) => i.kind == HomeMarketplaceItemKind.offer)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(serviceCategoriesProvider);
              ref.invalidate(doctorListProvider);
              ref.invalidate(homeMarketplaceCatalogProvider);
            },
            child: ListView(
              padding: EdgeInsetsDirectional.fromSTEB(
                HomeTokens.space16,
                HomeTokens.space16,
                HomeTokens.space16,
                HomeTokens.bottomScrollPadding(context),
              ),
              children: [
                Text(
                  l10n.homeMarketplaceSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: HomeTokens.space16),
                if (categories.isNotEmpty) ...[
                  Text(
                    l10n.homeMarketplaceCategories,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: HomeTokens.space8),
                  ...categories.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: HomeTokens.space8),
                      child: HomeSurfaceCard(
                        onTap: () {
                          HomeAnalytics.navigate(AppRoutes.services);
                          context.go(AppRoutes.services);
                        },
                        semanticLabel: item.title,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.category_outlined),
                          title: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (offers.isNotEmpty) ...[
                  const SizedBox(height: HomeTokens.space12),
                  Text(
                    l10n.findDoctors,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: HomeTokens.space8),
                  ...offers.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: HomeTokens.space8),
                      child: HomeSurfaceCard(
                        onTap: () => context.push(
                          AppRoutes.doctorDetail(item.routeTargetId!),
                        ),
                        semanticLabel: item.title,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_offer_outlined),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
