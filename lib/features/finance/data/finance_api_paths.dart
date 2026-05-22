abstract final class FinanceApiPaths {
  FinanceApiPaths._();

  static const expenses = '/api/mobile/finance/expenses';
  static const income = '/api/mobile/finance/income';
  static const profit = '/api/mobile/finance/profit';
  static const charts = '/api/mobile/finance/charts';
  static const reports = '/api/mobile/finance/reports';

  static String expense(String id) => '/api/mobile/finance/expenses/$id';
  static String incomeRecord(String id) => '/api/mobile/finance/income/$id';
}
