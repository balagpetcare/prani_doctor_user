import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../milk/presentation/widgets/milk_simple_chart.dart';
import '../data/finance_dto.dart';
import 'finance_providers.dart';
import 'widgets/finance_feedback.dart';
import 'widgets/finance_labels.dart';

class FinanceProfitPage extends ConsumerWidget {
  const FinanceProfitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profitAsync = ref.watch(financeProfitProvider);
    final chartsAsync = ref.watch(financeChartsProvider);
    final reportsAsync = ref.watch(financeReportsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.financeProfitTitle)),
      body: profitAsync.when(
        loading: FinanceFeedback.loading,
        error: (e, _) => FinanceFeedback.error(
          context,
          message: e.toString(),
          onRetry: () {
            ref.invalidate(financeProfitProvider);
            ref.invalidate(financeChartsProvider);
            ref.invalidate(financeReportsProvider);
          },
        ),
        data: (profit) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(financeProfitProvider);
              ref.invalidate(financeChartsProvider);
              ref.invalidate(financeReportsProvider);
              await ref.read(financeProfitProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (profit.fromCache) FinanceFeedback.offlineHint(context),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.financeProfitSummary,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.financeAmountValue(profit.profitBdt),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: profit.profitBdt >= 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.financePeriodRange}: ${profit.from} — ${profit.to}',
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.financeTotalIncome),
                          trailing: Text(
                            l10n.financeAmountValue(profit.totalIncomeBdt),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.financeTotalExpense),
                          trailing: Text(
                            l10n.financeAmountValue(profit.totalExpenseBdt),
                          ),
                        ),
                        if (profit.profitChangePercent != null)
                          Text(
                            l10n.financeProfitChange(
                              profit.profitChangePercent!,
                            ),
                          ),
                        const Divider(),
                        Text(
                          l10n.financePreviousPeriod,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${profit.previousPeriod.from} — ${profit.previousPeriod.to}: '
                          '${l10n.financeAmountValue(profit.previousPeriod.profitBdt)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                chartsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(l10n.financeChartsError),
                  data: (charts) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.financeIncomeTrendTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (charts.incomeTrend.isEmpty)
                        Text(l10n.financeEmpty)
                      else
                        MilkSimpleBarChart(
                          labels: charts.incomeTrend
                              .map((p) => p.date.substring(5))
                              .toList(),
                          values: charts.incomeTrend
                              .map((p) => p.amountBdt)
                              .toList(),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.financeExpenseTrendTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (charts.expenseTrend.isEmpty)
                        Text(l10n.financeEmpty)
                      else
                        MilkSimpleBarChart(
                          labels: charts.expenseTrend
                              .map((p) => p.date.substring(5))
                              .toList(),
                          values: charts.expenseTrend
                              .map((p) => p.amountBdt)
                              .toList(),
                          barColor: Theme.of(context).colorScheme.error,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.financeProfitTrendTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (charts.profitTrend.isEmpty)
                        Text(l10n.financeEmpty)
                      else
                        MilkSimpleBarChart(
                          labels: charts.profitTrend
                              .map((p) => p.date.substring(5))
                              .toList(),
                          values: charts.profitTrend
                              .map((p) => p.amountBdt)
                              .toList(),
                          barColor: Theme.of(context).colorScheme.tertiary,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                reportsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(l10n.financeReportsError),
                  data: (reports) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.financeReportsTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.financeExpenseByCategory,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (reports.expenseByCategory.isEmpty)
                        Text(l10n.financeEmpty)
                      else
                        ...reports.expenseByCategory.map(
                          (b) => ListTile(
                            dense: true,
                            title: Text(
                              expenseCategoryLabel(
                                l10n,
                                ExpenseCategoryApi.fromApi(b.label),
                              ),
                            ),
                            trailing: Text(l10n.financeAmountValue(b.totalBdt)),
                            subtitle: Text(l10n.financeRecordCount(b.count)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.financeIncomeBySource,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (reports.incomeBySource.isEmpty)
                        Text(l10n.financeEmpty)
                      else
                        ...reports.incomeBySource.map(
                          (b) => ListTile(
                            dense: true,
                            title: Text(
                              incomeSourceLabel(
                                l10n,
                                IncomeSourceApi.fromApi(b.label),
                              ),
                            ),
                            trailing: Text(l10n.financeAmountValue(b.totalBdt)),
                            subtitle: Text(l10n.financeRecordCount(b.count)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.financeExportTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        reports.export.note,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: reports.export.csvPath),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.financeExportCopied)),
                          );
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: Text(l10n.financeExportCsv),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: reports.export.pdfPath),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.financeExportCopied)),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(l10n.financeExportPdf),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
