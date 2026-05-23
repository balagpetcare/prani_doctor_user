import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/navigation/navigation_guard.dart';
import '../../../../routing/app_routes.dart';
import '../models/home_section_models.dart';
import '../providers/home_community_provider.dart';
import '../theme/home_tokens.dart';
import '../widgets/home_card.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 160) {
      ref.read(homeCommunityFeedProvider.notifier).loadMore();
    }
  }

  IconData _iconFor(HomeCommunityContentKind kind) {
    return switch (kind) {
      HomeCommunityContentKind.tip => Icons.lightbulb_outline,
      HomeCommunityContentKind.article => Icons.article_outlined,
      HomeCommunityContentKind.video => Icons.play_circle_outline,
      HomeCommunityContentKind.post => Icons.forum_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(homeCommunityFeedProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.homeCommunityTitle)),
      body: feed.isLoading
          ? const Center(child: CircularProgressIndicator())
          : feed.items.isEmpty
          ? HomeEmptyState(
              message: l10n.homeCommunityEmpty,
              icon: Icons.groups_outlined,
              actionLabel: l10n.dashboardSupportTitle,
              onAction: () => context.push(AppRoutes.supportHelp),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(homeCommunityFeedProvider.notifier).refresh(),
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsetsDirectional.fromSTEB(
                  HomeTokens.space16,
                  HomeTokens.space16,
                  HomeTokens.space16,
                  HomeTokens.bottomScrollPadding(context),
                ),
                itemCount: feed.items.length + (feed.hasMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: HomeTokens.space8),
                itemBuilder: (context, index) {
                  if (index >= feed.items.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(HomeTokens.space12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final item = feed.items[index];
                  return HomeSurfaceCard(
                    semanticLabel: item.title,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_iconFor(item.kind)),
                      title: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
