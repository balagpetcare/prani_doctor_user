import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auto_refresh_guard.dart';
import '../../../core/providers/provider_stability.dart';
import '../../../core/session/session_providers.dart';
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

  List<NotificationGroupedSection> groupedBy(String searchQuery) {
    final filtered = _filterItems(items, searchQuery);
    return NotificationGrouping.groupByDate(filtered);
  }

  static List<MobileNotificationDto> _filterItems(
    List<MobileNotificationDto> items,
    String searchQuery,
  ) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q),
        )
        .toList();
  }

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

final notificationUnreadOnlyProvider = StateProvider<bool>((ref) => false);
final notificationSearchProvider = StateProvider.autoDispose<String>((ref) => '');

class NotificationListNotifier extends AsyncNotifier<NotificationListState>
    with AsyncRefreshGuard<NotificationListState> {
  static const _pageSize = 20;

  @override
  Future<NotificationListState> build() async {
    ref.persistProvider('notificationList');
    if (!ref.watch(protectedApisEnabledProvider)) {
      return const NotificationListState();
    }
    NotificationAnalytics.listOpened();
    ref.watch(notificationUnreadOnlyProvider);
    final cached = await ref
        .read(notificationRepositoryProvider)
        .readCachedList();
    if (cached != null &&
        cached.items.isNotEmpty &&
        !ref.read(notificationUnreadOnlyProvider)) {
      ref.scheduleSilentRefresh(() => refresh(silent: true));
      return _fromPage(cached, offset: cached.items.length);
    }
    return _load(offset: 0);
  }

  NotificationListState _fromPage(
    NotificationListResultDto page, {
    required int offset,
  }) {
    return NotificationListState(
      items: page.items,
      total: page.total,
      offset: offset,
      hasMore: page.items.length < page.total,
      fromCache: page.fromCache,
    );
  }

  Future<NotificationListState> _load({
    required int offset,
    bool forceRefresh = false,
  }) async {
    final unreadOnly = ref.read(notificationUnreadOnlyProvider);
    final result = await ref
        .read(notificationRepositoryProvider)
        .listNotifications(
          limit: _pageSize,
          offset: offset,
          unreadOnly: unreadOnly,
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (page) {
        final merged = offset == 0
            ? page.items
            : <MobileNotificationDto>[
                ...state.value?.items ?? [],
                ...page.items,
              ];
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
    if (!guardReload()) return;
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(offset: 0, forceRefresh: forceRefresh));
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      endReload();
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (!guardRefresh(silent: silent)) return;
    NotificationAnalytics.listRefreshed();
    final previous = state.value ?? const NotificationListState();
    if (!silent) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    try {
      state = AsyncData(await _load(offset: 0, forceRefresh: true));
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      if (!silent) state = AsyncData(previous);
    } finally {
      endRefresh();
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || anyRefreshInFlight) return;
    refreshInFlight = true;
    try {
      state = AsyncData(await _load(offset: current.offset));
    } finally {
      refreshInFlight = false;
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
                .map(
                  (n) => n.id == id
                      ? n.copyWith(readAt: DateTime.now().toIso8601String())
                      : n,
                )
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
    final result = await ref
        .read(notificationRepositoryProvider)
        .deleteNotification(id);
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
    AsyncNotifierProvider<NotificationListNotifier, NotificationListState>(
      NotificationListNotifier.new,
    );

class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettingsDto>
    with AsyncRefreshGuard<NotificationSettingsDto> {
  @override
  Future<NotificationSettingsDto> build() async {
    ref.persistProvider('notificationSettings');
    final cached = await ref
        .read(notificationRepositoryProvider)
        .readCachedSettings();
    if (cached != null) {
      ProviderLog.cache('notification settings');
      ref.scheduleSilentRefresh(_refreshSilent);
      return cached;
    }
    return _load();
  }

  Future<void> _refreshSilent() async {
    if (!guardRefresh(silent: true)) return;
    try {
      state = AsyncData(await _load(forceRefresh: true));
    } catch (_) {
    } finally {
      endRefresh();
    }
  }

  Future<NotificationSettingsDto> _load({bool forceRefresh = false}) async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .getSettings(forceRefresh: forceRefresh);
    return result.when(success: (s) => s, failure: (e) => throw e);
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<
      NotificationSettingsNotifier,
      NotificationSettingsDto
    >(NotificationSettingsNotifier.new);

class UnreadNotificationCountNotifier extends AsyncNotifier<int>
    with AsyncRefreshGuard<int> {
  @override
  Future<int> build() async {
    ref.persistProvider('unreadNotificationCount');
    final cached = await ref
        .read(notificationRepositoryProvider)
        .readCachedUnreadCount();
    if (cached != null) {
      ProviderLog.cache('unread count');
      ref.scheduleSilentRefresh(_refreshSilent);
      return cached;
    }
    return _load();
  }

  Future<void> _refreshSilent() async {
    if (!guardRefresh(silent: true)) return;
    try {
      state = AsyncData(await _load(forceRefresh: true));
    } catch (_) {
    } finally {
      endRefresh();
    }
  }

  Future<int> _load({bool forceRefresh = false}) async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .getUnreadCount(forceRefresh: forceRefresh);
    return result.when(success: (c) => c, failure: (e) => throw e);
  }
}

final unreadNotificationCountProvider =
    AsyncNotifierProvider<UnreadNotificationCountNotifier, int>(
      UnreadNotificationCountNotifier.new,
    );

final notificationDetailProvider = FutureProvider.autoDispose
    .family<MobileNotificationDto?, String>((ref, id) async {
      ref.persistProvider('notificationDetail:$id');
      final fromList = ref
          .read(notificationListProvider)
          .valueOrNull
          ?.items
          .where((n) => n.id == id)
          .firstOrNull;
      if (fromList != null) return fromList;

      final cached = await ref
          .read(notificationRepositoryProvider)
          .readCachedList();
      final fromCache = cached?.items.where((n) => n.id == id).firstOrNull;
      if (fromCache != null) {
        scheduleCacheRevalidate(
          ref,
          label: 'notificationDetail:$id',
          revalidate: () async {
            try {
              await ref
                  .read(notificationListProvider.notifier)
                  .refresh(silent: true);
              return true;
            } catch (_) {
              return false;
            }
          },
        );
        return fromCache;
      }

      if (ref.read(notificationListProvider.notifier).anyRefreshInFlight) {
        return null;
      }
      await ref.read(notificationListProvider.notifier).refresh(silent: true);
      return ref
          .read(notificationListProvider)
          .valueOrNull
          ?.items
          .where((n) => n.id == id)
          .firstOrNull;
    });
