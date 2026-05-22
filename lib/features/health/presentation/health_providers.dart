import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health_dto.dart';
import '../data/health_repository.dart';

class HealthListData {
  const HealthListData({
    required this.records,
    required this.total,
    required this.page,
    required this.hasMore,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<HealthEvent> records;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  HealthListData copyWith({
    List<HealthEvent>? records,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return HealthListData(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

sealed class HealthViewState {
  const HealthViewState();
}

final class HealthLoading extends HealthViewState {
  const HealthLoading();
}

final class HealthLoaded extends HealthViewState {
  const HealthLoaded(this.data);
  final HealthListData data;
}

final class HealthEmpty extends HealthViewState {
  const HealthEmpty({this.fromCache = false, this.isRefreshing = false});
  final bool fromCache;
  final bool isRefreshing;
}

final class HealthError extends HealthViewState {
  const HealthError(this.error);
  final Object error;
}

class HealthTimelineData {
  const HealthTimelineData({
    required this.groups,
    required this.total,
    required this.page,
    required this.hasMore,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<HealthTimelineGroup> groups;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  HealthTimelineData copyWith({
    List<HealthTimelineGroup>? groups,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return HealthTimelineData(
      groups: groups ?? this.groups,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

sealed class HealthTimelineViewState {
  const HealthTimelineViewState();
}

final class HealthTimelineLoading extends HealthTimelineViewState {
  const HealthTimelineLoading();
}

final class HealthTimelineLoaded extends HealthTimelineViewState {
  const HealthTimelineLoaded(this.data);
  final HealthTimelineData data;
}

final class HealthTimelineEmpty extends HealthTimelineViewState {
  const HealthTimelineEmpty({this.fromCache = false, this.isRefreshing = false});
  final bool fromCache;
  final bool isRefreshing;
}

final class HealthTimelineError extends HealthTimelineViewState {
  const HealthTimelineError(this.error);
  final Object error;
}

final healthSearchProvider = StateProvider<String>((ref) => '');
final healthEventTypeFilterProvider = StateProvider<HealthEventType?>((ref) => null);

final healthProvider = NotifierProvider<HealthNotifier, HealthViewState>(HealthNotifier.new);

class HealthNotifier extends Notifier<HealthViewState> {
  bool _loadInFlight = false;
  HealthListData? _lastData;

  @override
  HealthViewState build() {
    Future.microtask(() => reload());
    return const HealthLoading();
  }

  HealthViewState _mapPageResult(HealthPageResult page, {required int pageNum, bool isRefreshing = false}) {
    final data = HealthListData(
      records: pageNum == 1 ? page.records : [...?_lastData?.records, ...page.records],
      total: page.total,
      page: page.page,
      hasMore: page.hasMore,
      fromCache: page.fromCache,
      isRefreshing: isRefreshing,
    );
    _lastData = data;
    if (data.records.isEmpty) {
      return HealthEmpty(fromCache: data.fromCache, isRefreshing: isRefreshing);
    }
    return HealthLoaded(data);
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const HealthLoading();
    try {
      final result = await ref.read(healthRepositoryProvider).listRecords(
            page: 1,
            search: ref.read(healthSearchProvider),
            eventType: ref.read(healthEventTypeFilterProvider),
            forceRefresh: forceRefresh,
          );
      result.when(
        success: (page) => state = _mapPageResult(page, pageNum: 1),
        failure: (e) => state = HealthError(e),
      );
    } catch (e) {
      state = HealthError(e);
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> refresh() async {
    if (_loadInFlight) return;
    final previous = _lastData;
    if (previous != null) {
      state = previous.records.isEmpty
          ? HealthEmpty(fromCache: previous.fromCache, isRefreshing: true)
          : HealthLoaded(previous.copyWith(isRefreshing: true));
    }
    try {
      final result = await ref.read(healthRepositoryProvider).listRecords(
            page: 1,
            search: ref.read(healthSearchProvider),
            eventType: ref.read(healthEventTypeFilterProvider),
            forceRefresh: true,
          );
      result.when(
        success: (page) => state = _mapPageResult(page, pageNum: 1),
        failure: (_) {
          if (previous != null) {
            state = previous.records.isEmpty
                ? HealthEmpty(fromCache: previous.fromCache)
                : HealthLoaded(previous);
          }
        },
      );
    } catch (_) {
      if (previous != null) {
        state = previous.records.isEmpty
            ? HealthEmpty(fromCache: previous.fromCache)
            : HealthLoaded(previous);
      }
    }
  }

  Future<void> loadMore() async {
    final current = _lastData;
    if (current == null || !current.hasMore || _loadInFlight) return;
    _loadInFlight = true;
    try {
      final result = await ref.read(healthRepositoryProvider).listRecords(
            page: current.page + 1,
            search: ref.read(healthSearchProvider),
            eventType: ref.read(healthEventTypeFilterProvider),
          );
      result.when(
        success: (page) => state = _mapPageResult(page, pageNum: current.page + 1),
        failure: (e) => state = HealthError(e),
      );
    } finally {
      _loadInFlight = false;
    }
  }

  void applyQuery() => reload(forceRefresh: true);
}

final healthTimelineProvider =
    NotifierProvider<HealthTimelineNotifier, HealthTimelineViewState>(HealthTimelineNotifier.new);

class HealthTimelineNotifier extends Notifier<HealthTimelineViewState> {
  bool _loadInFlight = false;
  HealthTimelineData? _lastData;

  @override
  HealthTimelineViewState build() {
    Future.microtask(() => reload());
    return const HealthTimelineLoading();
  }

  HealthTimelineViewState _mapTimeline(HealthTimelineResult timeline, {required int pageNum, bool isRefreshing = false}) {
    final data = HealthTimelineData(
      groups: pageNum == 1 ? timeline.groups : [...?_lastData?.groups, ...timeline.groups],
      total: timeline.total,
      page: timeline.page,
      hasMore: timeline.hasMore,
      fromCache: timeline.fromCache,
      isRefreshing: isRefreshing,
    );
    _lastData = data;
    if (data.groups.isEmpty) {
      return HealthTimelineEmpty(fromCache: data.fromCache, isRefreshing: isRefreshing);
    }
    return HealthTimelineLoaded(data);
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const HealthTimelineLoading();
    try {
      final result = await ref.read(healthRepositoryProvider).getTimeline(
            page: 1,
            search: ref.read(healthSearchProvider),
            eventType: ref.read(healthEventTypeFilterProvider),
            forceRefresh: forceRefresh,
          );
      result.when(
        success: (timeline) => state = _mapTimeline(timeline, pageNum: 1),
        failure: (e) => state = HealthTimelineError(e),
      );
    } catch (e) {
      state = HealthTimelineError(e);
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> refresh() async {
    if (_loadInFlight) return;
    final previous = _lastData;
    if (previous != null) {
      state = previous.groups.isEmpty
          ? HealthTimelineEmpty(fromCache: previous.fromCache, isRefreshing: true)
          : HealthTimelineLoaded(previous.copyWith(isRefreshing: true));
    }
    try {
      final result = await ref.read(healthRepositoryProvider).getTimeline(
            page: 1,
            search: ref.read(healthSearchProvider),
            eventType: ref.read(healthEventTypeFilterProvider),
            forceRefresh: true,
          );
      result.when(
        success: (timeline) => state = _mapTimeline(timeline, pageNum: 1),
        failure: (_) {
          if (previous != null) {
            state = previous.groups.isEmpty
                ? HealthTimelineEmpty(fromCache: previous.fromCache)
                : HealthTimelineLoaded(previous);
          }
        },
      );
    } catch (_) {
      if (previous != null) {
        state = previous.groups.isEmpty
            ? HealthTimelineEmpty(fromCache: previous.fromCache)
            : HealthTimelineLoaded(previous);
      }
    }
  }

  Future<void> loadMore() async {
    final current = _lastData;
    if (current == null || !current.hasMore || _loadInFlight) return;
    _loadInFlight = true;
    try {
      final result = await ref.read(healthRepositoryProvider).getTimeline(
            page: current.page + 1,
            search: ref.read(healthSearchProvider),
            eventType: ref.read(healthEventTypeFilterProvider),
          );
      result.when(
        success: (timeline) => state = _mapTimeline(timeline, pageNum: current.page + 1),
        failure: (e) => state = HealthTimelineError(e),
      );
    } finally {
      _loadInFlight = false;
    }
  }
}

final healthRecordProvider =
    FutureProvider.autoDispose.family<HealthEvent, String>((ref, id) async {
  final result = await ref.read(healthRepositoryProvider).getRecord(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});
