import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_diagnostics.dart';
import '../../../core/error/app_exception.dart';
import '../../../shared/widgets/app_error_boundary.dart';
import '../../auth/presentation/auth_logout.dart';
import '../data/dashboard_context_dto.dart';
import 'controllers/home_page_controller.dart';
import 'home_analytics.dart';
import 'home_performance_diagnostics.dart';
import 'home_providers.dart';
import '../../../core/startup/startup_trace.dart';
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
import 'widgets/home_load_failure_view.dart';
import 'widgets/home_skeleton_timeout_guard.dart';
import 'widgets/home_support_entry.dart';
import '../../app_config/presentation/closed_beta_banner.dart';
import 'widgets/home_user_hero.dart';
import 'widgets/insight_section.dart';
import 'widgets/marketplace_section.dart';
import 'widgets/notifications_section.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/reports_section.dart';
import 'widgets/summary_card.dart';
import '../../../routing/app_routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.refreshOnOpen = false});

  final bool refreshOnOpen;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final HomePageController _controller;
  int _buildGeneration = 0;
  bool _homeRenderedLogged = false;

  @override
  void initState() {
    super.initState();
    _controller = HomePageController(ref);
    HomePerformanceDiagnostics.homeInit(detail: 'refreshOnOpen=${widget.refreshOnOpen}');
    StartupTrace.homeLoadStart(detail: 'refreshOnOpen=${widget.refreshOnOpen}');
    HomeAnalytics.homeOpened();
    NavigationDiagnostics.routeEnter(AppRoutes.home, source: 'init');
    if (widget.refreshOnOpen) {
      Future.microtask(() => _controller.handleDeepLinkEntry(refresh: true));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.syncLazyTier();
    });
  }

  @override
  void dispose() {
    NavigationDiagnostics.routeExit(AppRoutes.home);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() => _controller.refresh();

  void _retryDashboard() {
    ref.read(dashboardProvider.notifier).reload(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    _buildGeneration++;
    HomePerformanceDiagnostics.homeBuild(detail: 'gen=$_buildGeneration');
    HomePerformanceDiagnostics.homeRebuild(detail: 'gen=$_buildGeneration');
    NavigationDiagnostics.homeRebuild(
      phase: 'build',
      detail: 'gen=$_buildGeneration',
    );

    ref.watch(dashboardPollProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final homeState = ref.watch(homeStateProvider);
    final cachedContext = dashboardAsync.valueOrNull;

    Widget content;

    if (dashboardAsync.isLoading && cachedContext != null) {
      _logHomeRenderedOnce(stale: true);
      content = _HomeDashboardBody(
        controller: _controller,
        contextData: cachedContext,
        onRefresh: _onRefresh,
      );
    } else {
      content = dashboardAsync.when(
        loading: () => HomeSkeletonTimeoutGuard(onRetry: _retryDashboard),
        error: (error, _) => _HomeErrorView(
          message: _errorText(AppLocalizations.of(context)!, error),
          unauthorized: isDashboardUnauthorized(error),
          offline: isDashboardOffline(error) || homeState == HomeState.offline,
          onRetry: _retryDashboard,
          onSignOut: () => performAuthLogout(ref),
        ),
        data: (contextData) {
          if (contextData == null) {
            return HomeLoadFailureView(onRetry: _retryDashboard);
          }

          _logHomeRenderedOnce();
          return _HomeDashboardBody(
            controller: _controller,
            contextData: contextData,
            onRefresh: _onRefresh,
          );
        },
      );
    }

    return AppErrorBoundary(
      onError: (_) {
        HomePerformanceDiagnostics.homeRebuild(detail: 'error-boundary');
        NavigationDiagnostics.homeRebuild(phase: 'error-boundary');
      },
      fallback: (_) => HomeLoadFailureView(
        message: HomeLoadFailureView.defaultMessageBn,
        onRetry: _retryDashboard,
      ),
      child: content,
    );
  }

  void _logHomeRenderedOnce({bool stale = false}) {
    if (_homeRenderedLogged) return;
    _homeRenderedLogged = true;
    StartupTrace.homeRendered(detail: stale ? 'stale-while-revalidate' : 'fresh');
    HomePerformanceDiagnostics.homeRebuild(detail: 'rendered stale=$stale');
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

  void _retrySections(WidgetRef ref) {
    ref.read(dashboardProvider.notifier).reload(forceRefresh: true);
  }

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

    return AppErrorBoundary(
      fallback: (_) => HomeLoadFailureView(
        message: HomeLoadFailureView.defaultMessageBn,
        onRetry: () => _retrySections(ref),
      ),
      child: RefreshIndicator(
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
              const SliverToBoxAdapter(child: ClosedBetaBanner()),
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
