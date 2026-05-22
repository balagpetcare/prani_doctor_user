import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../routing/app_routes.dart';
import 'data/dashboard_context_dto.dart';
import 'presentation/home_providers.dart';
import 'presentation/widgets/home_quick_actions.dart';
import 'presentation/widgets/home_skeleton.dart';
import 'presentation/widgets/home_summary_section.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardPollProvider.notifier).start());
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardProvider.notifier).refresh();
    ref.invalidate(dashboardSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return dashboardAsync.when(
      loading: () => const HomeSkeleton(),
      error: (error, _) => _HomeErrorView(
        message: _errorText(l10n, error),
        unauthorized: isDashboardUnauthorized(error),
        offline: isDashboardOffline(error),
        onRetry: () => ref.read(dashboardProvider.notifier).reload(forceRefresh: true),
        onSignOut: () => ref.read(sessionControllerProvider.notifier).signOut(),
      ),
      data: (contextData) {
        if (contextData == null) {
          return Center(child: Text(l10n.navHome));
        }
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: summaryAsync.when(
            loading: () => const HomeSkeleton(),
            error: (_, __) => _HomeContent(
              contextData: contextData,
              summary: DashboardSummary(
                context: contextData,
                totalFarms: contextData.farmSummary?.totalFarms ?? 0,
                totalAnimals: contextData.farmSummary?.animalCount ?? 0,
                activeAppointments: 0,
                unreadNotifications: 0,
                fromCache: contextData.fromCache,
              ),
            ),
            data: (summary) => _HomeContent(
              contextData: contextData,
              summary: summary,
            ),
          ),
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

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.contextData,
    required this.summary,
  });

  final DashboardContext contextData;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = contextData.user;
    final village = contextData.farmSummary?.primaryVillageLabelBn;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (summary.fromCache || contextData.fromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.dashboardOfflineHint,
              style: theme.textTheme.bodySmall,
            ),
          ),
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : l10n.navHome,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (user.phone.isNotEmpty)
                    Text(user.phone, style: theme.textTheme.bodyMedium),
                  if (village != null && village.isNotEmpty)
                    Text(village, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.go(AppRoutes.settingsProfile),
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editProfile,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (summary.context.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(l10n.dashboardEmptyHint, style: theme.textTheme.bodyMedium),
          ),
        HomeSummarySection(summary: summary),
        const SizedBox(height: 24),
        const HomeQuickActions(),
        const SizedBox(height: 16),
      ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              offline ? Icons.cloud_off_outlined : Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (unauthorized)
              FilledButton(onPressed: onSignOut, child: Text(l10n.signOut))
            else
              FilledButton(onPressed: onRetry, child: Text(l10n.dashboardRetry)),
          ],
        ),
      ),
    );
  }
}
