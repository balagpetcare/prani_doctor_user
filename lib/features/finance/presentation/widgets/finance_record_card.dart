import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/finance_dto.dart';
import 'finance_labels.dart';

class FinanceRecordCard extends StatelessWidget {
  const FinanceRecordCard({
    super.key,
    required this.record,
    required this.isExpense,
  });

  final FinanceRecord record;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = isExpense
        ? expenseCategoryLabel(l10n, record.category ?? ExpenseCategory.other)
        : incomeSourceLabel(l10n, record.source ?? IncomeSource.other);

    return Card(
      child: ListTile(
        leading: Icon(isExpense ? Icons.receipt_long_outlined : Icons.payments_outlined),
        title: Text('$label · ${l10n.financeAmountValue(record.amountBdt)}'),
        subtitle: Text(
          [
            record.recordedDate.toLocal().toString().split(' ').first,
            if (record.notes != null && record.notes!.isNotEmpty) record.notes!,
            if (record.pendingSync) l10n.financePendingSync,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          isExpense ? AppRoutes.financeExpenseEdit(record.id) : AppRoutes.financeIncomeEdit(record.id),
        ),
      ),
    );
  }
}
