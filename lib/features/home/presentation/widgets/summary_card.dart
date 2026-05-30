import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../home_analytics.dart';
import '../providers/home_section_providers.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';
import 'home_shimmer.dart';

class HomeSummaryCard extends ConsumerWidget {
  const HomeSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(homeAnimalSummaryProvider);
    final columns = HomeTokens.gridCrossAxisCount(context, phone: 2, tablet: 4);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.dashboardSummaryTitle,
        header: HomeSectionHeader(title: l10n.dashboardSummaryTitle),
        child: summaryAsync.when(
          loading: () => Padding(
            padding: HomeTokens.pageHorizontal(context),
            child: SizedBox(
              height: columns == 2 ? 168 : 120,
              child: GridView.count(
                crossAxisCount: columns,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: HomeTokens.space12,
                crossAxisSpacing: HomeTokens.space12,
                children: List.generate(
                  columns * (columns == 2 ? 2 : 1),
                  (_) => const HomeShimmerBox(
                    height: 72,
                    borderRadius: HomeTokens.radiusLg,
                  ),
                ),
              ),
            ),
          ),
          error: (_, _) => Padding(
            padding: HomeTokens.pageHorizontal(context),
            child: HomeErrorRetry(
              message: l10n.dashboardSectionError,
              onRetry: () {
                HomeAnalytics.sectionRetry('summary');
                ref.invalidate(homeAnimalSummaryProvider);
              },
            ),
          ),
          data: (metrics) => Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              HomeTokens.space16,
              0,
              HomeTokens.space16,
              0,
            ),
            child: GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: HomeTokens.space12,
              crossAxisSpacing: HomeTokens.space12,
              childAspectRatio: columns > 2 ? 1.8 : 1.2,
              children: [
                HomeMetricCard(
                  icon: Icons.pets_outlined,
                  label: l10n.dashboardTotalAnimals,
                  value: '${metrics.totalAnimals}',
                  onTap: () => context.go(AppRoutes.animals),
                ),
                HomeMetricCard(
                  icon: Icons.vaccines_outlined,
                  label: l10n.homeVaccineDue,
                  value: '${metrics.vaccineDue}',
                  onTap: () => context.go(AppRoutes.vaccineReminders),
                ),
                HomeMetricCard(
                  icon: Icons.medical_services_outlined,
                  label: l10n.healthSummaryTreatment,
                  value: '${metrics.activeTreatments}',
                  onTap: () => context.go(AppRoutes.treatments),
                ),
                HomeMetricCard(
                  icon: Icons.task_alt_outlined,
                  label: l10n.homeTasksLabel,
                  value: '${metrics.tasks}',
                  onTap: () => context.go(AppRoutes.inbox),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeMetricCard extends StatelessWidget {
  const HomeMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HomeSurfaceCard(
      onTap: onTap,
      semanticLabel: '$label $value',
      padding: const EdgeInsets.all(HomeTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: HomeTokens.space8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: HomeTokens.space4),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
