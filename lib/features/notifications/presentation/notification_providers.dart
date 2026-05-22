import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_dto.dart';
import '../data/notification_grouping.dart';
import '../data/notification_repository.dart';
import '../notification_analytics.dart';

class NotificationListState {
  const NotificationListState({
    this.items = const [],
    this.total = 0,
    this.offset = 0,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<MobileNotificationDto> items;
  final int total;
  final int offset;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  List<NotificationGroupedSection> get grouped => NotificationGrouping.groupByDate(items);

  NotificationListState copyWith({
    List<MobileNotificationDto>? items,
    int? total,
    int? offset,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

enum NotificationViewState { loading, loaded, empty, error }

class NotificationListNotifier extends AsyncNotifier<NotificationListState> {
  static const _pageSize = 20;
  bool _loadInFlight = false;

  @override
  Future<NotificationListState> build() async {
    NotificationAnalytics.listOpened();
    return _load(offset: 0);
  }

  Future<NotificationListState> _load({required int offset, bool forceRefresh = false}) async {
    final result = await ref.read(notificationRepositoryProvider).listNotifications(
          limit: _pageSize,
          offset: offset,
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (page) {
        final merged = offset == 0
            ? page.items
            : [...state.value?.items ?? [], ...page.items];
        return NotificationListState(
          items: merged,
          total: page.total,
          offset: offset + page.items.length,
          hasMore: merged.length < page.total,
          fromCache: page.fromCache,
        );
      },
      failure: (e) => throw e,
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(offset: 0, forceRefresh: forceRefresh));
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> refresh() async {
    if (_loadInFlight) return;
    NotificationAnalytics.listRefreshed();
    final previous = state.value ?? const NotificationListState();
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _load(offset: 0, forceRefresh: true));
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadInFlight) return;
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(offset: current.offset));
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> markRead(String id) async {
    NotificationAnalytics.markRead(id);
    final result = await ref.read(notificationRepositoryProvider).markRead(id);
    result.when(
      success: (_) {
        final current = state.value;
        if (current == null) return;
        state = AsyncData(
          current.copyWith(
            items: current.items
                .map((n) => n.id == id ? n.copyWith(readAt: DateTime.now().toIso8601String()) : n)
                .toList(),
          ),
        );
        ref.invalidate(unreadNotificationCountProvider);
      },
      failure: (_) {},
    );
  }

  Future<void> markAllRead() async {
    NotificationAnalytics.markAllRead();
    final result = await ref.read(notificationRepositoryProvider).markAllRead();
    result.when(
      success: (_) {
        ref.invalidate(unreadNotificationCountProvider);
        reload(forceRefresh: true);
      },
      failure: (_) {},
    );
  }

  Future<bool> delete(String id) async {
    NotificationAnalytics.deleted(id);
    final result = await ref.read(notificationRepositoryProvider).deleteNotification(id);
    return result.when(
      success: (_) {
        final current = state.value;
        if (current != null) {
          final updated = current.items.where((n) => n.id != id).toList();
          state = AsyncData(
            current.copyWith(items: updated, total: updated.length),
          );
        }
        ref.invalidate(unreadNotificationCountProvider);
        return true;
      },
      failure: (_) => false,
    );
  }
}

final notificationListProvider =
    AsyncNotifierProvider<NotificationListNotifier, NotificationListState>(NotificationListNotifier.new);

final notificationSettingsProvider = FutureProvider<NotificationSettingsDto>((ref) async {
  final result = await ref.read(notificationRepositoryProvider).getSettings();
  return result.when(success: (s) => s, failure: (e) => throw e);
});
