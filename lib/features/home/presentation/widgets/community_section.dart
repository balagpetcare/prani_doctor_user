import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../models/home_section_models.dart';
import '../providers/home_community_provider.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';
import 'home_shimmer.dart';

class HomeCommunitySection extends ConsumerWidget {
  const HomeCommunitySection({super.key});

  IconData _iconFor(HomeCommunityContentKind kind) {
    return switch (kind) {
      HomeCommunityContentKind.tip => Icons.lightbulb_outline,
      HomeCommunityContentKind.article => Icons.article_outlined,
      HomeCommunityContentKind.video => Icons.play_circle_outline,
      HomeCommunityContentKind.post => Icons.forum_outlined,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final previewAsync = ref.watch(homeCommunityPreviewProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.homeCommunityTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: HomeTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(
                title: l10n.homeCommunityTitle,
                actionLabel: l10n.homeViewAll,
                onAction: () => context.push(AppRoutes.community),
              ),
              previewAsync.when(
                loading: () => Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: const HomeSectionShimmer(lines: 3),
                ),
                error: (_, _) => Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: HomeErrorRetry(
                    message: l10n.dashboardSectionError,
                    onRetry: () => ref.invalidate(homeCommunityPreviewProvider),
                  ),
                ),
                data: (preview) {
                  if (preview.isEmpty) {
                    return HomeEmptyState(
                      message: l10n.homeCommunityEmpty,
                      icon: Icons.groups_outlined,
                      actionLabel: l10n.dashboardSupportTitle,
                      onAction: () => context.push(AppRoutes.supportHelp),
                    );
                  }
                  return Padding(
                    padding: HomeTokens.pageHorizontal(context),
                    child: Column(
                      children: [
                        for (var i = 0; i < preview.items.length; i++) ...[
                          if (i > 0) const SizedBox(height: HomeTokens.space8),
                          HomeSurfaceCard(
                            onTap: () => context.push(AppRoutes.community),
                            semanticLabel: preview.items[i].title,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(_iconFor(preview.items[i].kind)),
                              title: Text(
                                preview.items[i].title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                preview.items[i].body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
