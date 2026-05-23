import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/providers/provider_stability.dart';
import '../data/finance_dto.dart';
import '../data/finance_repository.dart';

class FinanceListState {
  const FinanceListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<FinanceRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  FinanceListState copyWith({
    List<FinanceRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return FinanceListState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final financeFromDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return _dateOnly(now.subtract(const Duration(days: 30)));
});

final financeToDateProvider = StateProvider<DateTime>(
  (ref) => _dateOnly(DateTime.now()),
);

final financeExpenseSearchProvider = StateProvider<String>((ref) => '');
final financeExpenseCategoryFilterProvider = StateProvider<ExpenseCategory?>(
  (ref) => null,
);
final financeIncomeSearchProvider = StateProvider<String>((ref) => '');
final financeIncomeSourceFilterProvider = StateProvider<IncomeSource?>(
  (ref) => null,
);

final financeExpenseListProvider =
    AsyncNotifierProvider<FinanceExpenseListNotifier, FinanceListState>(
      FinanceExpenseListNotifier.new,
    );

final financeIncomeListProvider =
    AsyncNotifierProvider<FinanceIncomeListNotifier, FinanceListState>(
      FinanceIncomeListNotifier.new,
    );

FinanceListState _fromPage(
  FinancePageResult pageResult, {
  required int page,
  FinanceListState? previous,
}) {
  return FinanceListState(
    records: page == 1
        ? pageResult.records
        : [...previous?.records ?? [], ...pageResult.records],
    total: pageResult.total,
    page: pageResult.page,
    hasMore: pageResult.hasMore,
    pendingSyncCount: pageResult.pendingSyncCount,
    fromCache: pageResult.fromCache,
  );
}

class FinanceExpenseListNotifier extends AsyncNotifier<FinanceListState> {
  bool _loadInFlight = false;

  @override
  Future<FinanceListState> build() async {
    final cached = await ref
        .read(financeRepositoryProvider)
        .readCachedExpenses();
    if (cached != null && cached.records.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(page: 1);
  }

  Future<FinanceListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(financeRepositoryProvider)
        .listExpenses(
          from: ref.read(financeFromDateProvider),
          to: ref.read(financeToDateProvider),
          page: page,
          search: ref.read(financeExpenseSearchProvider),
          category: ref.read(financeExpenseCategoryFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) =>
          _fromPage(pageResult, page: page, previous: state.value),
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

  Future<void> refresh({bool silent = false}) async {
    if (_loadInFlight) return;
    final previous = state.value ?? const FinanceListState();
    if (!silent) state = AsyncData(previous.copyWith(isRefreshing: true));
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (previous.records.isNotEmpty) state = AsyncData(previous);
    } finally {
      _loadInFlight = false;
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
  Future<FinanceListState> build() async {
    final cached = await ref.read(financeRepositoryProvider).readCachedIncome();
    if (cached != null && cached.records.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(page: 1);
  }

  Future<FinanceListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(financeRepositoryProvider)
        .listIncome(
          from: ref.read(financeFromDateProvider),
          to: ref.read(financeToDateProvider),
          page: page,
          search: ref.read(financeIncomeSearchProvider),
          source: ref.read(financeIncomeSourceFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) =>
          _fromPage(pageResult, page: page, previous: state.value),
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

  Future<void> refresh({bool silent = false}) async {
    if (_loadInFlight) return;
    final previous = state.value ?? const FinanceListState();
    if (!silent) state = AsyncData(previous.copyWith(isRefreshing: true));
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (previous.records.isNotEmpty) state = AsyncData(previous);
    } finally {
      _loadInFlight = false;
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

final financeLedgerProvider = FutureProvider.autoDispose<List<FinanceRecord>>((
  ref,
) async {
  final expenses = await ref
      .read(financeRepositoryProvider)
      .readCachedExpenses();
  final income = await ref.read(financeRepositoryProvider).readCachedIncome();
  final merged = <FinanceRecord>[...?expenses?.records, ...?income?.records];
  merged.sort((a, b) => b.recordedDate.compareTo(a.recordedDate));
  return merged.take(25).toList();
});

final financeExpenseRecordProvider = FutureProvider.autoDispose
    .family<FinanceRecord, String>((ref, id) async {
      final result = await ref.read(financeRepositoryProvider).getExpense(id);
      return result.when(success: (r) => r, failure: (e) => throw e);
    });

final financeIncomeRecordProvider = FutureProvider.autoDispose
    .family<FinanceRecord, String>((ref, id) async {
      final result = await ref.read(financeRepositoryProvider).getIncome(id);
      return result.when(success: (r) => r, failure: (e) => throw e);
    });

final financeProfitSummaryProvider =
    FutureProvider.autoDispose<FinanceProfitData>((ref) async {
      final repo = ref.read(financeRepositoryProvider);
      final cached = await repo.readCachedProfit();
      if (cached != null) {
        scheduleCacheRevalidate(
          ref,
          label: 'financeProfitSummary',
          revalidate: () async {
            final result = await repo.getProfit();
            return result is ApiSuccess;
          },
        );
        return cached;
      }
      final result = await repo.getProfit();
      return result.when(success: (p) => p, failure: (e) => throw e);
    });

final financeProfitProvider = FutureProvider.autoDispose<FinanceProfitData>((
  ref,
) async {
  final repo = ref.read(financeRepositoryProvider);
  final from = ref.watch(financeFromDateProvider);
  final to = ref.watch(financeToDateProvider);
  final cached = await repo.readCachedProfit();
  if (cached != null) {
    scheduleCacheRevalidate(
      ref,
      label: 'financeProfit',
      revalidate: () async {
        final result = await repo.getProfit(from: from, to: to);
        return result is ApiSuccess;
      },
    );
    return cached;
  }
  final result = await repo.getProfit(from: from, to: to);
  return result.when(success: (p) => p, failure: (e) => throw e);
});

final financeChartsProvider = FutureProvider.autoDispose<FinanceChartsData>((
  ref,
) async {
  final repo = ref.read(financeRepositoryProvider);
  final from = ref.watch(financeFromDateProvider);
  final to = ref.watch(financeToDateProvider);
  final cached = await repo.readCachedCharts();
  if (cached != null) {
    scheduleCacheRevalidate(
      ref,
      label: 'financeCharts',
      revalidate: () async {
        final result = await repo.getCharts(from: from, to: to);
        return result is ApiSuccess;
      },
    );
    return cached;
  }
  final result = await repo.getCharts(from: from, to: to);
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final financeReportsProvider = FutureProvider.autoDispose<FinanceReportsData>((
  ref,
) async {
  final repo = ref.read(financeRepositoryProvider);
  final from = ref.watch(financeFromDateProvider);
  final to = ref.watch(financeToDateProvider);
  final cached = await repo.readCachedReports();
  if (cached != null) {
    scheduleCacheRevalidate(
      ref,
      label: 'financeReports',
      revalidate: () async {
        final result = await repo.getReports(from: from, to: to);
        return result is ApiSuccess;
      },
    );
    return cached;
  }
  final result = await repo.getReports(from: from, to: to);
  return result.when(success: (r) => r, failure: (e) => throw e);
});
