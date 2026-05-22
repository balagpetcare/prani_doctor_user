import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/finance_dto.dart';
import '../data/finance_repository.dart';

class FinanceListState {
  const FinanceListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<FinanceRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  FinanceListState copyWith({
    List<FinanceRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return FinanceListState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final financeExpenseSearchProvider = StateProvider<String>((ref) => '');
final financeExpenseCategoryFilterProvider = StateProvider<ExpenseCategory?>((ref) => null);
final financeIncomeSearchProvider = StateProvider<String>((ref) => '');
final financeIncomeSourceFilterProvider = StateProvider<IncomeSource?>((ref) => null);

final financeExpenseListProvider =
    AsyncNotifierProvider<FinanceExpenseListNotifier, FinanceListState>(FinanceExpenseListNotifier.new);

final financeIncomeListProvider =
    AsyncNotifierProvider<FinanceIncomeListNotifier, FinanceListState>(FinanceIncomeListNotifier.new);

class FinanceExpenseListNotifier extends AsyncNotifier<FinanceListState> {
  bool _loadInFlight = false;

  @override
  Future<FinanceListState> build() async => _load(page: 1);

  Future<FinanceListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(financeRepositoryProvider).listExpenses(
          page: page,
          search: ref.read(financeExpenseSearchProvider),
          category: ref.read(financeExpenseCategoryFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => FinanceListState(
        records: page == 1
            ? pageResult.records
            : [...state.value?.records ?? [], ...pageResult.records],
        total: pageResult.total,
        page: pageResult.page,
        hasMore: pageResult.hasMore,
        fromCache: pageResult.fromCache,
      ),
      failure: (e) => throw e,
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: forceRefresh));
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> refresh() async {
    if (_loadInFlight) return;
    final previous = state.value ?? const FinanceListState();
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadInFlight) return;
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: current.page + 1));
    } finally {
      _loadInFlight = false;
    }
  }

  void applyQuery() => reload(forceRefresh: true);
}

class FinanceIncomeListNotifier extends AsyncNotifier<FinanceListState> {
  bool _loadInFlight = false;

  @override
  Future<FinanceListState> build() async => _load(page: 1);

  Future<FinanceListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(financeRepositoryProvider).listIncome(
          page: page,
          search: ref.read(financeIncomeSearchProvider),
          source: ref.read(financeIncomeSourceFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => FinanceListState(
        records: page == 1
            ? pageResult.records
            : [...state.value?.records ?? [], ...pageResult.records],
        total: pageResult.total,
        page: pageResult.page,
        hasMore: pageResult.hasMore,
        fromCache: pageResult.fromCache,
      ),
      failure: (e) => throw e,
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: forceRefresh));
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> refresh() async {
    if (_loadInFlight) return;
    final previous = state.value ?? const FinanceListState();
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadInFlight) return;
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: current.page + 1));
    } finally {
      _loadInFlight = false;
    }
  }

  void applyQuery() => reload(forceRefresh: true);
}

final financeExpenseRecordProvider =
    FutureProvider.autoDispose.family<FinanceRecord, String>((ref, id) async {
  final result = await ref.read(financeRepositoryProvider).getExpense(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

final financeIncomeRecordProvider =
    FutureProvider.autoDispose.family<FinanceRecord, String>((ref, id) async {
  final result = await ref.read(financeRepositoryProvider).getIncome(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

final financeProfitProvider = FutureProvider.autoDispose<FinanceProfitData>((ref) async {
  final result = await ref.read(financeRepositoryProvider).getProfit();
  return result.when(success: (p) => p, failure: (e) => throw e);
});

final financeChartsProvider = FutureProvider.autoDispose<FinanceChartsData>((ref) async {
  final result = await ref.read(financeRepositoryProvider).getCharts();
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final financeReportsProvider = FutureProvider.autoDispose<FinanceReportsData>((ref) async {
  final result = await ref.read(financeRepositoryProvider).getReports();
  return result.when(success: (r) => r, failure: (e) => throw e);
});
