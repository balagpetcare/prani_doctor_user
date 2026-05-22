import '../../../core/error/api_result.dart';
import 'finance_dto.dart';

abstract class FinanceRepositoryContract {
  Future<FinancePageResult?> readCachedExpenses();

  Future<FinancePageResult?> readCachedIncome();

  Future<ApiResult<FinancePageResult>> listExpenses({
    DateTime? from,
    DateTime? to,
    ExpenseCategory? category,
    String search,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<FinancePageResult>> listIncome({
    DateTime? from,
    DateTime? to,
    IncomeSource? source,
    String search,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<FinanceRecord>> getExpense(String id);

  Future<ApiResult<FinanceRecord>> getIncome(String id);

  Future<ApiResult<FinanceRecord>> createExpense(ExpenseInput input);

  Future<ApiResult<FinanceRecord>> updateExpense(String id, ExpenseInput input);

  Future<ApiResult<void>> deleteExpense(String id);

  Future<ApiResult<FinanceRecord>> createIncome(IncomeInput input);

  Future<ApiResult<FinanceRecord>> updateIncome(String id, IncomeInput input);

  Future<ApiResult<void>> deleteIncome(String id);

  Future<ApiResult<FinanceProfitData>> getProfit({DateTime? from, DateTime? to});

  Future<ApiResult<FinanceChartsData>> getCharts({DateTime? from, DateTime? to});

  Future<ApiResult<FinanceReportsData>> getReports({DateTime? from, DateTime? to});

  Future<void> saveExpenseDraft(ExpenseInput input, {String? recordId});

  Future<ExpenseInput?> readExpenseDraft({String? recordId});

  Future<void> clearExpenseDraft({String? recordId});

  Future<void> saveIncomeDraft(IncomeInput input, {String? recordId});

  Future<IncomeInput?> readIncomeDraft({String? recordId});

  Future<void> clearIncomeDraft({String? recordId});
}
