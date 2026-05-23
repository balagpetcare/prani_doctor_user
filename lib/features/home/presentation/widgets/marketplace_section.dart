import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../home_analytics.dart';
import '../models/home_section_models.dart';
import '../providers/home_marketplace_provider.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';
import 'home_shimmer.dart';

class HomeMarketplaceSection extends ConsumerWidget {
  const HomeMarketplaceSection({super.key});

  IconData _iconFor(HomeMarketplaceItemKind kind) {
    return switch (kind) {
      HomeMarketplaceItemKind.category => Icons.category_outlined,
      HomeMarketplaceItemKind.offer => Icons.local_offer_outlined,
      HomeMarketplaceItemKind.product => Icons.shopping_bag_outlined,
    };
  }

  void _openItem(BuildContext context, HomeMarketplacePreviewItem item) {
    if (item.kind == HomeMarketplaceItemKind.offer &&
        item.routeTargetId != null) {
      HomeAnalytics.navigate(AppRoutes.doctorDetail(item.routeTargetId!));
      context.push(AppRoutes.doctorDetail(item.routeTargetId!));
      return;
    }
    HomeAnalytics.navigate(AppRoutes.marketplace);
    context.push(AppRoutes.marketplace);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final previewAsync = ref.watch(homeMarketplacePreviewProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.homeMarketplaceTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: HomeTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(
                title: l10n.homeMarketplaceTitle,
                actionLabel: l10n.homeViewAll,
                onAction: () {
                  HomeAnalytics.navigate(AppRoutes.marketplace);
                  context.push(AppRoutes.marketplace);
                },
              ),
              previewAsync.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: HomeSectionShimmer(lines: 2),
                ),
                error: (_, _) => Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: HomeErrorRetry(
                    message: l10n.dashboardSectionError,
                    onRetry: () {
                      HomeAnalytics.sectionRetry('marketplace');
                      ref.invalidate(homeMarketplacePreviewProvider);
                    },
                  ),
                ),
                data: (preview) {
                  if (preview.isEmpty) {
                    HomeAnalytics.sectionEmpty('marketplace');
                    return HomeEmptyState(
                      message: l10n.homeMarketplaceEmpty,
                      icon: Icons.storefront_outlined,
                      actionLabel: l10n.findDoctors,
                      onAction: () => context.go(AppRoutes.services),
                    );
                  }
                  HomeAnalytics.sectionLoaded(
                    'marketplace',
                    fromCache: preview.fromCache,
                  );
                  return HomeHorizontalList(
                    height: 120,
                    itemCount: preview.items.length,
                    itemBuilder: (context, index) {
                      final item = preview.items[index];
                      return SizedBox(
                        width: 180,
                        child: HomeSurfaceCard(
                          onTap: () => _openItem(context, item),
                          semanticLabel: item.title,
                          padding: const EdgeInsets.all(HomeTokens.space12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconFor(item.kind),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: HomeTokens.space8),
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.subtitle.isNotEmpty)
                                Text(
                                  item.subtitle,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: HomeTokens.space8),
            ],
          ),
        ),
      ),
    );
  }
}
