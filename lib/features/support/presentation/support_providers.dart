import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/local_cache_contract.dart';
import '../../offline/offline_providers.dart';
import '../data/support_dto.dart';
import '../data/support_repository.dart';

class SupportTicketListState {
  const SupportTicketListState({
    this.tickets = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<SupportTicketSummary> tickets;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  SupportTicketListState copyWith({
    List<SupportTicketSummary>? tickets,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return SupportTicketListState(
      tickets: tickets ?? this.tickets,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class SupportSummary {
  const SupportSummary({
    this.open = 0,
    this.pending = 0,
    this.resolved = 0,
    this.closed = 0,
    this.total = 0,
  });

  final int open;
  final int pending;
  final int resolved;
  final int closed;
  final int total;

  static SupportSummary fromTickets(List<SupportTicketSummary> tickets) {
    var open = 0;
    var pending = 0;
    var resolved = 0;
    var closed = 0;
    for (final t in tickets) {
      switch (t.status) {
        case SupportTicketStatus.open:
          open++;
        case SupportTicketStatus.inProgress:
        case SupportTicketStatus.waitingCustomer:
          pending++;
        case SupportTicketStatus.resolved:
          resolved++;
        case SupportTicketStatus.closed:
          closed++;
      }
    }
    return SupportSummary(
      open: open,
      pending: pending,
      resolved: resolved,
      closed: closed,
      total: tickets.length,
    );
  }
}

class SupportCreateDraft {
  const SupportCreateDraft({
    this.category = SupportTicketCategory.other,
    this.priority = SupportTicketPriority.medium,
    this.subject = '',
    this.description = '',
  });

  final SupportTicketCategory category;
  final SupportTicketPriority priority;
  final String subject;
  final String description;

  SupportCreateDraft copyWith({
    SupportTicketCategory? category,
    SupportTicketPriority? priority,
    String? subject,
    String? description,
  }) {
    return SupportCreateDraft(
      category: category ?? this.category,
      priority: priority ?? this.priority,
      subject: subject ?? this.subject,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category.apiValue,
    'priority': priority.apiValue,
    'subject': subject,
    'description': description,
  };

  factory SupportCreateDraft.fromJson(Map<String, dynamic> json) {
    return SupportCreateDraft(
      category: SupportTicketCategoryApi.fromApi(
        json['category'] as String? ?? 'OTHER',
      ),
      priority: SupportTicketPriorityApi.fromApi(
        json['priority'] as String? ?? 'MEDIUM',
      ),
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  bool get isEmpty => subject.trim().isEmpty && description.trim().isEmpty;
}

final supportSearchProvider = StateProvider<String>((ref) => '');
final supportStatusFilterProvider = StateProvider<SupportTicketStatus?>(
  (ref) => null,
);
final supportCategoryFilterProvider = StateProvider<SupportTicketCategory?>(
  (ref) => null,
);
final supportFaqSearchProvider = StateProvider<String>((ref) => '');

final supportTicketListProvider =
    AsyncNotifierProvider<SupportTicketListNotifier, SupportTicketListState>(
      SupportTicketListNotifier.new,
    );

class SupportTicketListNotifier extends AsyncNotifier<SupportTicketListState> {
  bool _loadInFlight = false;

  @override
  Future<SupportTicketListState> build() async {
    ref.watch(supportSearchProvider);
    ref.watch(supportStatusFilterProvider);
    ref.watch(supportCategoryFilterProvider);

    final cached = await ref
        .read(supportRepositoryProvider)
        .readCachedTickets();
    if (cached != null && cached.tickets.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, page: cached.page);
    }
    return _load(page: 1);
  }

  SupportTicketListState _fromPage(
    SupportTicketPageResult pageResult, {
    required int page,
  }) {
    return SupportTicketListState(
      tickets: pageResult.tickets,
      total: pageResult.total,
      page: pageResult.page,
      hasMore: pageResult.hasMore,
      fromCache: pageResult.fromCache,
    );
  }

  Future<SupportTicketListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(supportRepositoryProvider)
        .listTickets(
          page: page,
          search: ref.read(supportSearchProvider),
          status: ref.read(supportStatusFilterProvider),
          category: ref.read(supportCategoryFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => SupportTicketListState(
        tickets: page == 1
            ? pageResult.tickets
            : <SupportTicketSummary>[
                ...state.value?.tickets ?? [],
                ...pageResult.tickets,
              ],
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

  Future<void> refresh({bool silent = false}) async {
    if (_loadInFlight) return;
    final previous = state.value ?? const SupportTicketListState();
    if (!silent) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (!silent) state = AsyncData(previous);
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
    } catch (_) {
      // keep current list on pagination failure
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> applyQuery() => reload(forceRefresh: true);
}

final supportSummaryProvider = Provider<AsyncValue<SupportSummary>>((ref) {
  return ref
      .watch(supportTicketListProvider)
      .whenData((state) => SupportSummary.fromTickets(state.tickets));
});

class SupportTicketNotifier
    extends FamilyAsyncNotifier<SupportTicketDetail, String> {
  @override
  Future<SupportTicketDetail> build(String id) async {
    final cached = await ref
        .read(supportRepositoryProvider)
        .readCachedTicketDetail(id);
    if (cached != null) {
      unawaited(_refreshSilent(id));
      return cached;
    }
    return _load(id);
  }

  Future<void> _refreshSilent(String id) async {
    try {
      state = AsyncData(await _load(id, forceRefresh: true));
    } catch (_) {}
  }

  Future<SupportTicketDetail> _load(
    String id, {
    bool forceRefresh = false,
  }) async {
    final result = await ref.read(supportRepositoryProvider).getTicket(id);
    return result.when(success: (t) => t, failure: (e) => throw e);
  }
}

final supportTicketProvider =
    AsyncNotifierProvider.family<
      SupportTicketNotifier,
      SupportTicketDetail,
      String
    >(SupportTicketNotifier.new);

class SupportHelpNotifier extends AsyncNotifier<SupportHelpData> {
  @override
  Future<SupportHelpData> build() async {
    final cached = await ref.read(supportRepositoryProvider).readCachedHelp();
    if (cached != null) {
      unawaited(_refreshSilent());
      return cached;
    }
    return _load();
  }

  Future<void> _refreshSilent() async {
    try {
      state = AsyncData(await _load(forceRefresh: true));
    } catch (_) {}
  }

  Future<SupportHelpData> _load({bool forceRefresh = false}) async {
    final result = await ref
        .read(supportRepositoryProvider)
        .getHelp(forceRefresh: forceRefresh);
    return result.when(success: (h) => h, failure: (e) => throw e);
  }
}

final supportHelpProvider =
    AsyncNotifierProvider<SupportHelpNotifier, SupportHelpData>(
      SupportHelpNotifier.new,
    );

enum SupportSubmissionState { idle, submitting, success, error }

final supportSubmissionProvider = StateProvider<SupportSubmissionState>(
  (ref) => SupportSubmissionState.idle,
);

class SupportCreateDraftNotifier extends AsyncNotifier<SupportCreateDraft?> {
  @override
  Future<SupportCreateDraft?> build() async {
    final cache = ref.read(localCacheServiceProvider);
    final raw = await cache.read(LocalCacheContract.supportCreateDraftKey);
    if (raw == null) return null;
    return SupportCreateDraft.fromJson(raw);
  }

  Future<void> save(SupportCreateDraft draft) async {
    if (draft.isEmpty) {
      await clear();
      return;
    }
    await ref
        .read(localCacheServiceProvider)
        .write(
          LocalCacheContract.supportCreateDraftKey,
          draft.toJson(),
          LocalCacheContract.profileTtl,
        );
    state = AsyncData(draft);
  }

  Future<void> clear() async {
    await ref
        .read(localCacheServiceProvider)
        .delete(LocalCacheContract.supportCreateDraftKey);
    state = const AsyncData(null);
  }
}

final supportCreateDraftProvider =
    AsyncNotifierProvider<SupportCreateDraftNotifier, SupportCreateDraft?>(
      SupportCreateDraftNotifier.new,
    );
