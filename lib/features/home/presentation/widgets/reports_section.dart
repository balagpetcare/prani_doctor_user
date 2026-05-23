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

class HomeReportsSection extends ConsumerWidget {
  const HomeReportsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportsAsync = ref.watch(homeReportsPreviewProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.financeReportsTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: HomeTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(
                title: l10n.financeReportsTitle,
                actionLabel: l10n.homeViewAll,
                onAction: () {
                  HomeAnalytics.navigate(AppRoutes.financeReports);
                  context.push(AppRoutes.financeReports);
                },
              ),
              reportsAsync.when(
                loading: () => Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: const HomeSectionShimmer(lines: 3),
                ),
                error: (_, _) => Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: HomeErrorRetry(
                    message: l10n.financeReportsError,
                    onRetry: () {
                      HomeAnalytics.sectionRetry('reports');
                      ref.invalidate(homeReportsPreviewProvider);
                    },
                  ),
                ),
                data: (reports) {
                  HomeAnalytics.sectionLoaded(
                    'reports',
                    fromCache: reports.fromCache,
                  );
                  return Padding(
                    padding: HomeTokens.pageHorizontal(context),
                    child: HomeSurfaceCard(
                      onTap: () {
                        HomeAnalytics.navigate(AppRoutes.financeReports);
                        context.push(AppRoutes.financeReports);
                      },
                      semanticLabel: l10n.financeReportsTitle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reports.from} – ${reports.to}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: HomeTokens.space8),
                          _ReportMetricRow(
                            label: l10n.financeIncomeTitle,
                            value:
                                '৳${reports.totalIncomeBdt.toStringAsFixed(0)}',
                          ),
                          _ReportMetricRow(
                            label: l10n.financeExpenseTitle,
                            value:
                                '৳${reports.totalExpenseBdt.toStringAsFixed(0)}',
                          ),
                          _ReportMetricRow(
                            label: l10n.financeProfitTitle,
                            value: '৳${reports.profitBdt.toStringAsFixed(0)}',
                          ),
                          if (reports.export.csvPath.isNotEmpty ||
                              reports.export.pdfPath.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: HomeTokens.space8,
                              ),
                              child: Text(
                                l10n.homeReportsExportHint,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
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

class _ReportMetricRow extends StatelessWidget {
  const _ReportMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
