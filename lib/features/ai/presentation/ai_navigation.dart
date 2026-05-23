import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/presentation/notification_providers.dart';
import 'ai_providers.dart';

abstract final class AiNavigation {
  AiNavigation._();

  static void afterChatMutation(WidgetRef ref) {
    ref.invalidate(aiChatProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  static void afterSettingsSave(WidgetRef ref) {
    ref.invalidate(aiSettingsProvider);
  }

  static void invalidateAll(WidgetRef ref) {
    ref.invalidate(aiChatProvider);
    ref.invalidate(aiSettingsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }
}
