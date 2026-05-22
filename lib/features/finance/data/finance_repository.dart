import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'finance_api_paths.dart';
import 'finance_dto.dart';
import 'finance_repository_contract.dart';

class FinanceRepository implements FinanceRepositoryContract {
  FinanceRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<FinancePageResult>>? _expensesInFlight;
  Future<ApiResult<FinancePageResult>>? _incomeInFlight;

  String _dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  FinancePageResult _parseListPage(Map<String, dynamic> data) {
    final records = (data['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FinanceRecord.fromJson)
        .toList();
    return FinancePageResult(
      records: records,
      total: data['total'] as int? ?? records.length,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  Future<void> _writeExpensesCache(FinancePageResult page) async {
    await _cache.write(
      LocalCacheContract.financeExpensesListKey,
      {
        'records': page.records.map((r) => r.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'limit': page.limit,
        'hasMore': page.hasMore,
      },
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _writeIncomeCache(FinancePageResult page) async {
    await _cache.write(
      LocalCacheContract.financeIncomeListKey,
      {
        'records': page.records.map((r) => r.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'limit': page.limit,
        'hasMore': page.hasMore,
      },
      LocalCacheContract.profileTtl,
    );
  }

  FinancePageResult? _pageFromCache(Map<String, dynamic>? cached) {
    if (cached == null) return null;
    final records = (cached['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => FinanceRecord.fromJson(j, fromCache: true))
        .toList();
    return FinancePageResult(
      records: records,
      total: cached['total'] as int? ?? records.length,
      page: cached['page'] as int? ?? 1,
      limit: cached['limit'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
    );
  }

  @override
  Future<FinancePageResult?> readCachedExpenses() async {
    return _pageFromCache(await _cache.read(LocalCacheContract.financeExpensesListKey));
  }

  @override
  Future<FinancePageResult?> readCachedIncome() async {
    return _pageFromCache(await _cache.read(LocalCacheContract.financeIncomeListKey));
  }

  Future<void> _enqueue(OutboxKind kind, Map<String, dynamic> payload, String keySuffix) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: '${kind.apiValue}-$keySuffix-$sequence',
        kind: kind,
        payload: payload,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> _optimisticUpsertExpense(FinanceRecord record) async {
    final cached = await readCachedExpenses();
    final existing = cached?.records ?? [];
    final updated = [record, ...existing.where((r) => r.id != record.id)];
    await _writeExpensesCache(
      FinancePageResult(
        records: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(
      LocalCacheContract.financeExpenseDetailKey(record.id),
      {'record': record.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _optimisticUpsertIncome(FinanceRecord record) async {
    final cached = await readCachedIncome();
    final existing = cached?.records ?? [];
    final updated = [record, ...existing.where((r) => r.id != record.id)];
    await _writeIncomeCache(
      FinancePageResult(
        records: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(
      LocalCacheContract.financeIncomeDetailKey(record.id),
      {'record': record.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _optimisticRemoveExpense(String id) async {
    final cached = await readCachedExpenses();
    if (cached == null) return;
    final updated = cached.records.where((r) => r.id != id).toList();
    await _writeExpensesCache(
      FinancePageResult(
        records: updated,
        total: updated.length,
        page: cached.page,
        limit: cached.limit,
        hasMore: cached.hasMore,
      ),
    );
  }

  Future<void> _optimisticRemoveIncome(String id) async {
    final cached = await readCachedIncome();
    if (cached == null) return;
    final updated = cached.records.where((r) => r.id != id).toList();
    await _writeIncomeCache(
      FinancePageResult(
        records: updated,
        total: updated.length,
        page: cached.page,
        limit: cached.limit,
        hasMore: cached.hasMore,
      ),
    );
  }

  @override
  Future<ApiResult<FinancePageResult>> listExpenses({
    DateTime? from,
    DateTime? to,
    ExpenseCategory? category,
    String search = '',
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _expensesInFlight != null) return _expensesInFlight!;
    final future = _loadExpenses(
      from: from,
      to: to,
      category: category,
      search: search,
      page: page,
      limit: limit,
    );
    _expensesInFlight = future;
    try {
      return await future;
    } finally {
      _expensesInFlight = null;
    }
  }

  Future<ApiResult<FinancePageResult>> _loadExpenses({
    DateTime? from,
    DateTime? to,
    ExpenseCategory? category,
    required String search,
    required int page,
    required int limit,
  }) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
        if (category != null) 'category': category.apiValue,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      };
      final data = await getJson(_dio, FinanceApiPaths.expenses, queryParameters: query);
      final pageResult = _parseListPage(data);
      if (page == 1) await _writeExpensesCache(pageResult);
      return ApiResult.success(pageResult);
    } on AppException catch (e) {
      if (page == 1) {
        final cached = await readCachedExpenses();
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinancePageResult>> listIncome({
    DateTime? from,
    DateTime? to,
    IncomeSource? source,
    String search = '',
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _incomeInFlight != null) return _incomeInFlight!;
    final future = _loadIncome(
      from: from,
      to: to,
      source: source,
      search: search,
      page: page,
      limit: limit,
    );
    _incomeInFlight = future;
    try {
      return await future;
    } finally {
      _incomeInFlight = null;
    }
  }

  Future<ApiResult<FinancePageResult>> _loadIncome({
    DateTime? from,
    DateTime? to,
    IncomeSource? source,
    required String search,
    required int page,
    required int limit,
  }) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
        if (source != null) 'source': source.apiValue,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      };
      final data = await getJson(_dio, FinanceApiPaths.income, queryParameters: query);
      final pageResult = _parseListPage(data);
      if (page == 1) await _writeIncomeCache(pageResult);
      return ApiResult.success(pageResult);
    } on AppException catch (e) {
      if (page == 1) {
        final cached = await readCachedIncome();
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceRecord>> getExpense(String id) async {
    try {
      final data = await getJson(_dio, FinanceApiPaths.expense(id));
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Expense not found'));
      }
      final record = FinanceRecord.fromJson(raw);
      await _cache.write(
        LocalCacheContract.financeExpenseDetailKey(id),
        {'record': record.toJson()},
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(record);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.financeExpenseDetailKey(id));
      if (cached != null) {
        return ApiResult.success(
          FinanceRecord.fromJson(cached['record'] as Map<String, dynamic>, fromCache: true),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceRecord>> getIncome(String id) async {
    try {
      final data = await getJson(_dio, FinanceApiPaths.incomeRecord(id));
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Income not found'));
      }
      final record = FinanceRecord.fromJson(raw);
      await _cache.write(
        LocalCacheContract.financeIncomeDetailKey(id),
        {'record': record.toJson()},
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(record);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.financeIncomeDetailKey(id));
      if (cached != null) {
        return ApiResult.success(
          FinanceRecord.fromJson(cached['record'] as Map<String, dynamic>, fromCache: true),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceRecord>> createExpense(ExpenseInput input) async {
    final body = input.toCreateJson();
    final tempId = 'local-expense-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = FinanceRecord(
      id: tempId,
      customerId: '',
      type: 'EXPENSE',
      amountBdt: input.amountBdt,
      category: input.category,
      recordedDate: input.recordedDate,
      farmRef: input.farmRef,
      notes: input.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _optimisticUpsertExpense(optimistic);

    try {
      final data = await postJson(_dio, FinanceApiPaths.expenses, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid create response'));
      }
      final record = FinanceRecord.fromJson(raw);
      await _optimisticUpsertExpense(record);
      await clearExpenseDraft();
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.financeExpenseCreate, body, tempId);
        return ApiResult.failure(
          const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceRecord>> updateExpense(String id, ExpenseInput input) async {
    final body = input.toPatchJson();
    final existingResult = await getExpense(id);
    if (existingResult case ApiSuccess(data: final existing)) {
      await _optimisticUpsertExpense(
        existing.copyWith(
          amountBdt: input.amountBdt,
          category: input.category,
          farmRef: input.farmRef,
          recordedDate: input.recordedDate,
          notes: input.notes,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      final data = await patchJson(_dio, FinanceApiPaths.expense(id), body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid update response'));
      }
      final record = FinanceRecord.fromJson(raw);
      await _optimisticUpsertExpense(record);
      await clearExpenseDraft(recordId: id);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.financeExpensePatch, {...body, 'id': id}, id);
        return ApiResult.failure(
          const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<void>> deleteExpense(String id) async {
    await _optimisticRemoveExpense(id);
    try {
      await deleteJson(_dio, FinanceApiPaths.expense(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.financeExpenseDelete, {'id': id}, id);
        return ApiResult.failure(
          const AppException(message: 'Queued delete — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceRecord>> createIncome(IncomeInput input) async {
    final body = input.toCreateJson();
    final tempId = 'local-income-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = FinanceRecord(
      id: tempId,
      customerId: '',
      type: 'INCOME',
      amountBdt: input.amountBdt,
      source: input.source,
      recordedDate: input.recordedDate,
      farmRef: input.farmRef,
      notes: input.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _optimisticUpsertIncome(optimistic);

    try {
      final data = await postJson(_dio, FinanceApiPaths.income, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid create response'));
      }
      final record = FinanceRecord.fromJson(raw);
      await _optimisticUpsertIncome(record);
      await clearIncomeDraft();
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.financeIncomeCreate, body, tempId);
        return ApiResult.failure(
          const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceRecord>> updateIncome(String id, IncomeInput input) async {
    final body = input.toPatchJson();
    final existingResult = await getIncome(id);
    if (existingResult case ApiSuccess(data: final existing)) {
      await _optimisticUpsertIncome(
        existing.copyWith(
          amountBdt: input.amountBdt,
          source: input.source,
          farmRef: input.farmRef,
          recordedDate: input.recordedDate,
          notes: input.notes,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      final data = await patchJson(_dio, FinanceApiPaths.incomeRecord(id), body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid update response'));
      }
      final record = FinanceRecord.fromJson(raw);
      await _optimisticUpsertIncome(record);
      await clearIncomeDraft(recordId: id);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.financeIncomePatch, {...body, 'id': id}, id);
        return ApiResult.failure(
          const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<void>> deleteIncome(String id) async {
    await _optimisticRemoveIncome(id);
    try {
      await deleteJson(_dio, FinanceApiPaths.incomeRecord(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.financeIncomeDelete, {'id': id}, id);
        return ApiResult.failure(
          const AppException(message: 'Queued delete — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceProfitData>> getProfit({DateTime? from, DateTime? to}) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
      };
      final data = await getJson(_dio, FinanceApiPaths.profit, queryParameters: query);
      final raw = data['profit'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid profit response'));
      }
      final profit = FinanceProfitData.fromJson(raw);
      await _cache.write(LocalCacheContract.financeProfitKey, raw, LocalCacheContract.profileTtl);
      return ApiResult.success(profit);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.financeProfitKey);
      if (cached != null) {
        return ApiResult.success(FinanceProfitData.fromJson(cached, fromCache: true));
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceChartsData>> getCharts({DateTime? from, DateTime? to}) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
      };
      final data = await getJson(_dio, FinanceApiPaths.charts, queryParameters: query);
      final raw = data['charts'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid charts response'));
      }
      final charts = FinanceChartsData.fromJson(raw);
      await _cache.write(LocalCacheContract.financeChartsKey, raw, LocalCacheContract.profileTtl);
      return ApiResult.success(charts);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.financeChartsKey);
      if (cached != null) {
        return ApiResult.success(FinanceChartsData.fromJson(cached, fromCache: true));
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FinanceReportsData>> getReports({DateTime? from, DateTime? to}) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
      };
      final data = await getJson(_dio, FinanceApiPaths.reports, queryParameters: query);
      final raw = data['reports'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid reports response'));
      }
      final reports = FinanceReportsData.fromJson(raw);
      await _cache.write(LocalCacheContract.financeReportsKey, raw, LocalCacheContract.profileTtl);
      return ApiResult.success(reports);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.financeReportsKey);
      if (cached != null) {
        return ApiResult.success(FinanceReportsData.fromJson(cached, fromCache: true));
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<void> saveExpenseDraft(ExpenseInput input, {String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.financeExpenseDraftKey
          : LocalCacheContract.financeExpenseEditDraftKey(recordId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<ExpenseInput?> readExpenseDraft({String? recordId}) async {
    final raw = await _cache.read(
      recordId == null
          ? LocalCacheContract.financeExpenseDraftKey
          : LocalCacheContract.financeExpenseEditDraftKey(recordId),
    );
    if (raw == null || raw.isEmpty) return null;
    return ExpenseInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearExpenseDraft({String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.financeExpenseDraftKey
          : LocalCacheContract.financeExpenseEditDraftKey(recordId),
      {},
      Duration.zero,
    );
  }

  @override
  Future<void> saveIncomeDraft(IncomeInput input, {String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.financeIncomeDraftKey
          : LocalCacheContract.financeIncomeEditDraftKey(recordId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<IncomeInput?> readIncomeDraft({String? recordId}) async {
    final raw = await _cache.read(
      recordId == null
          ? LocalCacheContract.financeIncomeDraftKey
          : LocalCacheContract.financeIncomeEditDraftKey(recordId),
    );
    if (raw == null || raw.isEmpty) return null;
    return IncomeInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearIncomeDraft({String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.financeIncomeDraftKey
          : LocalCacheContract.financeIncomeEditDraftKey(recordId),
      {},
      Duration.zero,
    );
  }
}

final financeRepositoryProvider = Provider<FinanceRepositoryContract>((ref) {
  return FinanceRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
