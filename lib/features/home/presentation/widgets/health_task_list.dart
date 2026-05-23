import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../home_analytics.dart';
import '../models/home_section_models.dart';
import '../providers/home_section_providers.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';
import 'home_shimmer.dart';

class HomeHealthTaskList extends ConsumerWidget {
  const HomeHealthTaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(homeHealthTasksProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.homeHealthTasksTitle,
        child: tasksAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(title: l10n.homeHealthTasksTitle),
              Padding(
                padding: HomeTokens.pageHorizontal(context),
                child: const HomeSectionShimmer(lines: 3),
              ),
            ],
          ),
          error: (_, _) => Column(
            children: [
              HomeSectionHeader(title: l10n.homeHealthTasksTitle),
              Padding(
                padding: HomeTokens.pageHorizontal(context),
                child: HomeErrorRetry(
                  message: l10n.dashboardSectionError,
                  onRetry: () {
                    HomeAnalytics.sectionRetry('tasks');
                    ref.invalidate(homeHealthTasksProvider);
                  },
                ),
              ),
            ],
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return Column(
                children: [
                  HomeSectionHeader(title: l10n.homeHealthTasksTitle),
                  HomeEmptyState(
                    message: l10n.homeNoHealthTasks,
                    icon: Icons.check_circle_outline,
                    actionLabel: l10n.dashboardViewHealthAlerts,
                    onAction: () => context.go(AppRoutes.vaccineReminders),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeSectionHeader(
                  title: l10n.homeHealthTasksTitle,
                  actionLabel: l10n.homeViewAll,
                  onAction: () => context.go(AppRoutes.inbox),
                ),
                Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: Column(
                    children: [
                      for (var i = 0; i < tasks.length; i++) ...[
                        if (i > 0) const SizedBox(height: HomeTokens.space8),
                        _HealthTaskTile(task: tasks[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: HomeTokens.space8),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HealthTaskTile extends StatelessWidget {
  const _HealthTaskTile({required this.task});

  final HomeHealthTask task;

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (task.colorKind) {
      HomeHealthTaskColorKind.error => scheme.error,
      HomeHealthTaskColorKind.primary => scheme.primary,
      HomeHealthTaskColorKind.secondary => scheme.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return HomeSurfaceCard(
      onTap: task.route != null ? () => context.push(task.route!) : null,
      semanticLabel: task.title,
      padding: const EdgeInsets.symmetric(
        horizontal: HomeTokens.space12,
        vertical: HomeTokens.space8,
      ),
      child: Row(
        children: [
          Icon(task.icon, color: _color(context), size: 22),
          const SizedBox(width: HomeTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (task.subtitle.isNotEmpty)
                  Text(
                    task.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
