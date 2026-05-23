import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_auth.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import 'data/notification_repository.dart';
import 'notification_service.dart';
import 'presentation/notification_providers.dart';

const notificationPollInterval = Duration(seconds: 30);

class NotificationRealtimeNotifier extends Notifier<int?> {
  Timer? _timer;
  int? _lastUnread;
  final Set<String> _deliveredIds = {};

  @override
  int? build() {
    ref.onDispose(_stop);
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (SessionAuth.canCallProtectedApis(next)) {
        start();
      } else {
        _stop();
        _lastUnread = null;
        _deliveredIds.clear();
        state = null;
      }
    }, fireImmediately: true);
    return _lastUnread;
  }

  void start() {
    // Automatic notification polling disabled — offline-first.
    _timer?.cancel();
    _timer = null;
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (!SessionAuth.canCallProtectedApis(
      ref.read(sessionControllerProvider),
    )) {
      return;
    }

    final result = await ref
        .read(notificationRepositoryProvider)
        .getUnreadCount();
    await result.when(
      success: (count) async {
        final previous = _lastUnread;
        _lastUnread = count;
        state = count;
        ref.invalidate(unreadNotificationCountProvider);

        if (previous != null && count != previous) {
          ref.invalidate(notificationListProvider);
        }

        if (previous != null && count > previous) {
          await _showLatestUnread();
        }
      },
      failure: (_) async {},
    );
  }

  Future<void> _showLatestUnread() async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .listNotifications(unreadOnly: true, limit: 1);
    result.when(
      success: (data) {
        if (data.items.isEmpty) return;
        final item = data.items.first;
        if (_deliveredIds.contains(item.id)) return;
        _deliveredIds.add(item.id);
        if (_deliveredIds.length > 100) {
          _deliveredIds.remove(_deliveredIds.first);
        }
        ref
            .read(notificationServiceProvider)
            .showLocal(
              title: item.title,
              body: item.body,
              metadata: item.metadata,
            );
      },
      failure: (_) {},
    );
  }
}

final notificationRealtimeProvider =
    NotifierProvider<NotificationRealtimeNotifier, int?>(
      NotificationRealtimeNotifier.new,
    );
