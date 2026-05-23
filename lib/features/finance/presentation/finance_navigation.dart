import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'finance_providers.dart';

abstract final class FinanceNavigation {
  FinanceNavigation._();

  static Future<void> refreshExpenseList(WidgetRef ref) async {
    await ref.read(financeExpenseListProvider.notifier).refresh();
  }

  static Future<void> refreshIncomeList(WidgetRef ref) async {
    await ref.read(financeIncomeListProvider.notifier).refresh();
  }

  static Future<void> refreshExpenseDetail(WidgetRef ref, String id) async {
    ref.invalidate(financeExpenseRecordProvider(id));
    await ref.read(financeExpenseRecordProvider(id).future);
  }

  static Future<void> refreshIncomeDetail(WidgetRef ref, String id) async {
    ref.invalidate(financeIncomeRecordProvider(id));
    await ref.read(financeIncomeRecordProvider(id).future);
  }

  static void afterExpenseSave(WidgetRef ref, {String? recordId}) {
    _invalidateAll(ref);
    if (recordId != null) {
      ref.invalidate(financeExpenseRecordProvider(recordId));
    }
  }

  static void afterIncomeSave(WidgetRef ref, {String? recordId}) {
    _invalidateAll(ref);
    if (recordId != null) ref.invalidate(financeIncomeRecordProvider(recordId));
  }

  static void afterDelete(WidgetRef ref) => _invalidateAll(ref);

  static void _invalidateAll(WidgetRef ref) {
    ref.invalidate(financeExpenseListProvider);
    ref.invalidate(financeIncomeListProvider);
    ref.invalidate(financeLedgerProvider);
    ref.invalidate(financeProfitSummaryProvider);
    ref.invalidate(financeProfitProvider);
    ref.invalidate(financeChartsProvider);
    ref.invalidate(financeReportsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
