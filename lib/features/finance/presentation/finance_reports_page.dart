import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../data/finance_dto.dart';
import 'finance_providers.dart';
import 'widgets/finance_feedback.dart';
import 'widgets/finance_labels.dart';

class FinanceReportsPage extends ConsumerWidget {
  const FinanceReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportsAsync = ref.watch(financeReportsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.financeReportsTitle)),
      body: reportsAsync.when(
        loading: FinanceFeedback.loading,
        error: (e, _) => FinanceFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(financeReportsProvider),
        ),
        data: (reports) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(financeReportsProvider);
              await ref.read(financeReportsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (reports.fromCache) FinanceFeedback.offlineHint(context),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${l10n.financePeriodRange}: ${reports.from} — ${reports.to}',
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.financeTotalIncome),
                          trailing: Text(
                            l10n.financeAmountValue(reports.totalIncomeBdt),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.financeTotalExpense),
                          trailing: Text(
                            l10n.financeAmountValue(reports.totalExpenseBdt),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.financeProfitSummary),
                          trailing: Text(
                            l10n.financeAmountValue(reports.profitBdt),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
          );
        },
      ),
    );
  }
}
