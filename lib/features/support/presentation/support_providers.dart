import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final supportSearchProvider = StateProvider<String>((ref) => '');
final supportStatusFilterProvider = StateProvider<SupportTicketStatus?>((ref) => null);
final supportCategoryFilterProvider = StateProvider<SupportTicketCategory?>((ref) => null);

final supportTicketListProvider =
    AsyncNotifierProvider<SupportTicketListNotifier, SupportTicketListState>(
  SupportTicketListNotifier.new,
);

class SupportTicketListNotifier extends AsyncNotifier<SupportTicketListState> {
  bool _loadInFlight = false;

  @override
  Future<SupportTicketListState> build() async => _load(page: 1);

  Future<SupportTicketListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(supportRepositoryProvider).listTickets(
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
            : [...state.value?.tickets ?? [], ...pageResult.tickets],
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
    state = AsyncData((state.value ?? const SupportTicketListState()).copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (e, st) {
      state = AsyncError(e, st);
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

final supportTicketProvider =
    FutureProvider.family<SupportTicketDetail, String>((ref, id) async {
  final result = await ref.read(supportRepositoryProvider).getTicket(id);
  return result.when(
    success: (ticket) => ticket,
    failure: (e) => throw e,
  );
});

final supportHelpProvider = FutureProvider<SupportHelpData>((ref) async {
  final result = await ref.read(supportRepositoryProvider).getHelp();
  return result.when(
    success: (help) => help,
    failure: (e) => throw e,
  );
});

enum SupportSubmissionState { idle, submitting, success, error }

final supportSubmissionProvider = StateProvider<SupportSubmissionState>(
  (ref) => SupportSubmissionState.idle,
);
