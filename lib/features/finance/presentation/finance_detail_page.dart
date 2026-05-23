import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/finance_dto.dart';
import '../data/finance_repository.dart';
import 'finance_navigation.dart';
import 'finance_providers.dart';
import 'widgets/finance_feedback.dart';
import 'widgets/finance_labels.dart';

class FinanceDetailPage extends ConsumerWidget {
  const FinanceDetailPage({
    super.key,
    required this.recordId,
    required this.isExpense,
  });

  final String recordId;
  final bool isExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recordAsync = isExpense
        ? ref.watch(financeExpenseRecordProvider(recordId))
        : ref.watch(financeIncomeRecordProvider(recordId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isExpense
              ? l10n.financeExpenseDetailTitle
              : l10n.financeIncomeDetailTitle,
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(
              isExpense
                  ? AppRoutes.financeExpenseEdit(recordId)
                  : AppRoutes.financeIncomeEdit(recordId),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: FinanceFeedback.loading,
        error: (e, _) => FinanceFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => isExpense
              ? FinanceNavigation.refreshExpenseDetail(ref, recordId)
              : FinanceNavigation.refreshIncomeDetail(ref, recordId),
        ),
        data: (record) => RefreshIndicator(
          onRefresh: () => isExpense
              ? FinanceNavigation.refreshExpenseDetail(ref, recordId)
              : FinanceNavigation.refreshIncomeDetail(ref, recordId),
          child: _FinanceDetailBody(record: record, isExpense: isExpense),
        ),
      ),
    );
  }
}

class _FinanceDetailBody extends ConsumerWidget {
  const _FinanceDetailBody({required this.record, required this.isExpense});

  final FinanceRecord record;
  final bool isExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final label = isExpense
        ? expenseCategoryLabel(l10n, record.category ?? ExpenseCategory.other)
        : incomeSourceLabel(l10n, record.source ?? IncomeSource.other);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (record.fromCache) FinanceFeedback.offlineHint(context),
        if (record.pendingSync)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.sync_problem),
              title: Text(l10n.financePendingSync),
            ),
          ),
        Text(label, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l10n.financeAmountValue(record.amountBdt),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${l10n.financeDateLabel}: ${record.recordedDate.toLocal().toString().split(' ').first}',
        ),
        if (record.farmRef != null && record.farmRef!.isNotEmpty)
          Text('${l10n.financeFarmLabel}: ${record.farmRef}'),
        if (record.notes != null && record.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(record.notes!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(
            isExpense
                ? AppRoutes.financeExpenseEdit(record.id)
                : AppRoutes.financeIncomeEdit(record.id),
          ),
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            isExpense
                ? l10n.financeExpenseEditTitle
                : l10n.financeIncomeEditTitle,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.financeDeleteTitle),
                content: Text(
                  isExpense
                      ? l10n.financeExpenseDeleteConfirm
                      : l10n.financeIncomeDeleteConfirm,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.financeDeleteAction),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            final repo = ref.read(financeRepositoryProvider);
            final result = isExpense
                ? await repo.deleteExpense(record.id)
                : await repo.deleteIncome(record.id);
            if (!context.mounted) return;
            result.when(
              success: (_) {
                FinanceNavigation.afterDelete(ref);
                context.go(
                  isExpense
                      ? AppRoutes.financeExpenses
                      : AppRoutes.financeIncome,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.financeDeleteSuccess)),
                );
              },
              failure: (e) {
                final msg = e.code == offlineQueuedCode
                    ? l10n.financeOfflineSaved
                    : e.message;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
                if (e.code == offlineQueuedCode) {
                  FinanceNavigation.afterDelete(ref);
                  context.go(
                    isExpense
                        ? AppRoutes.financeExpenses
                        : AppRoutes.financeIncome,
                  );
                }
              },
            );
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.financeDeleteAction),
        ),
      ],
    );
  }
}
