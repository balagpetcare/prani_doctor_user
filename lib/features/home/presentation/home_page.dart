import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/presentation/auth_logout.dart';
import '../data/dashboard_context_dto.dart';
import 'controllers/home_page_controller.dart';
import 'home_analytics.dart';
import 'home_providers.dart';
import 'home_state.dart';
import 'theme/home_tokens.dart';
import 'widgets/ai_section.dart';
import 'widgets/animal_carousel.dart';
import 'widgets/app_header.dart';
import 'widgets/community_section.dart';
import 'widgets/doctor_section.dart';
import 'widgets/health_task_list.dart';
import 'widgets/home_care_action_bar.dart';
import 'widgets/home_layout.dart';
import 'widgets/home_page_skeleton.dart';
import 'widgets/home_support_entry.dart';
import 'widgets/home_user_hero.dart';
import 'widgets/insight_section.dart';
import 'widgets/marketplace_section.dart';
import 'widgets/notifications_section.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/reports_section.dart';
import 'widgets/summary_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.refreshOnOpen = false});

  final bool refreshOnOpen;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final HomePageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomePageController(ref);
    HomeAnalytics.homeOpened();
    if (widget.refreshOnOpen) {
      Future.microtask(() => _controller.handleDeepLinkEntry(refresh: true));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.syncLazyTier();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() => _controller.refresh();

  @override
  Widget build(BuildContext context) {
    ref.watch(dashboardPollProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final homeState = ref.watch(homeStateProvider);
    final cachedContext = dashboardAsync.valueOrNull;

    if (dashboardAsync.isLoading && cachedContext != null) {
      return _HomeDashboardBody(
        controller: _controller,
        contextData: cachedContext,
        onRefresh: _onRefresh,
      );
    }

    return dashboardAsync.when(
      loading: () => const HomePageSkeleton(),
      error: (error, _) => _HomeErrorView(
        message: _errorText(AppLocalizations.of(context)!, error),
        unauthorized: isDashboardUnauthorized(error),
        offline: isDashboardOffline(error) || homeState == HomeState.offline,
        onRetry: () =>
            ref.read(dashboardProvider.notifier).reload(forceRefresh: true),
        onSignOut: () => performAuthLogout(ref),
      ),
      data: (contextData) {
        if (contextData == null) {
          return _HomeErrorView(
            message: AppLocalizations.of(context)!.dashboardLoadError,
            unauthorized: false,
            offline: false,
            onRetry: () => ref
                .read(dashboardProvider.notifier)
                .reload(forceRefresh: true),
            onSignOut: () => performAuthLogout(ref),
          );
        }

        return _HomeDashboardBody(
          controller: _controller,
          contextData: contextData,
          onRefresh: _onRefresh,
        );
      },
    );
  }

  String _errorText(AppLocalizations l10n, Object error) {
    if (error is AppException) {
      if (isDashboardUnauthorized(error)) return l10n.dashboardUnauthorized;
      if (isDashboardOffline(error)) return l10n.dashboardOfflineError;
      return error.message;
    }
    return l10n.dashboardLoadError;
  }
}

class _HomeDashboardBody extends ConsumerWidget {
  const _HomeDashboardBody({
    required this.controller,
    required this.contextData,
    required this.onRefresh,
  });

  final HomePageController controller;
  final DashboardContext contextData;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeState = ref.watch(homeStateProvider);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final showOfflineHint =
        homeState.showsCachedContent ||
        contextData.fromCache ||
        metricsAsync.maybeWhen(data: (m) => m.fromCache, orElse: () => false);
    final isCustomer = isCustomerDashboard(contextData);
    final isTechnician =
        contextData.dashboardType == DashboardType.aiTechnician;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListenableBuilder(
        listenable: controller.lazyTier,
        builder: (context, _) {
          return CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            cacheExtent: HomeTokens.scrollCacheExtent,
            slivers: [
              HomeAppHeader(contextData: contextData),
              if (showOfflineHint)
                SliverToBoxAdapter(
                  child: HomeOfflineBanner(message: l10n.dashboardOfflineHint),
                ),
              HomeUserHero(contextData: contextData),
              const HomeCareActionBar(),
              if (isTechnician)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      HomeTokens.space16,
                      HomeTokens.space16,
                      HomeTokens.space16,
                      0,
                    ),
                    child: HomeAiTechnicianSection(contextData: contextData),
                  ),
                ),
              if (contextData.isEmpty && isCustomer)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: HomeTokens.pageHorizontal(
                      context,
                    ).resolve(Directionality.of(context)),
                    child: Text(l10n.dashboardEmptyHint),
                  ),
                ),
              const HomeSummaryCard(),
              HomeQuickActionGrid(dashboardType: contextData.dashboardType),
              if (isCustomer) ...[
                HomeLazySliver(
                  enabled: controller.shouldMountSection(0),
                  placeholderHeight: 200,
                  sliver: const HomeAnimalCarousel(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(1),
                  placeholderHeight: 180,
                  sliver: const HomeHealthTaskList(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(2),
                  placeholderHeight: 180,
                  sliver: const HomeDoctorSection(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(3),
                  placeholderHeight: 160,
                  sliver: const HomeNotificationsSection(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(4),
                  placeholderHeight: 140,
                  sliver: const HomeAiSection(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(5),
                  placeholderHeight: 140,
                  sliver: const HomeInsightSection(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(6),
                  placeholderHeight: 140,
                  sliver: const HomeReportsSection(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(7),
                  placeholderHeight: 180,
                  sliver: const HomeMarketplaceSection(),
                ),
                HomeLazySliver(
                  enabled: controller.shouldMountSection(8),
                  placeholderHeight: 140,
                  sliver: const HomeCommunitySection(),
                ),
              ],
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: HomeTokens.bottomScrollPadding(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({
    required this.message,
    required this.unauthorized,
    required this.offline,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final bool unauthorized;
  final bool offline;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(HomeTokens.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                offline ? Icons.cloud_off_outlined : Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: HomeTokens.space16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: HomeTokens.space16),
              if (unauthorized)
                FilledButton(onPressed: onSignOut, child: Text(l10n.signOut))
              else
                FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.dashboardRetry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
