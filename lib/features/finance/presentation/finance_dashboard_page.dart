import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'finance_providers.dart';
import 'widgets/finance_feedback.dart';
import 'widgets/finance_record_card.dart';
import 'widgets/finance_summary_section.dart';

class FinanceDashboardPage extends ConsumerWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profitAsync = ref.watch(financeProfitSummaryProvider);
    final ledgerAsync = ref.watch(financeLedgerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financeDashboardTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.financeProfit),
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.financeProfitTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.financeReports),
            icon: const Icon(Icons.summarize_outlined),
            tooltip: l10n.financeReportsTitle,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financeProfitSummaryProvider);
          ref.invalidate(financeLedgerProvider);
          ref.invalidate(financeExpenseListProvider);
          ref.invalidate(financeIncomeListProvider);
          await ref.read(financeProfitSummaryProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            profitAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: FinanceFeedback.error(
                  context,
                  message: l10n.financeLoadError,
                  onRetry: () => ref.invalidate(financeProfitSummaryProvider),
                ),
              ),
              data: (profit) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profit.fromCache)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FinanceFeedback.offlineHint(context),
                      ),
                    FinanceSummarySection(
                      incomeBdt: profit.totalIncomeBdt,
                      expenseBdt: profit.totalExpenseBdt,
                      profitBdt: profit.profitBdt,
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.financeExpenseCreate),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.financeExpenseAddTitle),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.financeIncomeCreate),
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(l10n.financeIncomeAddTitle),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.financeExpenses),
                    child: Text(l10n.financeExpenseTitle),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.financeIncome),
                    child: Text(l10n.financeIncomeTitle),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.financeLedgerTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ledgerAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.financeLoadError),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.financeLedgerEmpty),
                  );
                }
                return Column(
                  children: records.map((record) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: FinanceRecordCard(
                        record: record,
                        isExpense: record.isExpense,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
