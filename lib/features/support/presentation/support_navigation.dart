import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/presentation/notification_providers.dart';
import 'support_providers.dart';

abstract final class SupportNavigation {
  SupportNavigation._();

  static void afterTicketMutation(WidgetRef ref, {String? ticketId}) {
    ref.invalidate(supportTicketListProvider);
    ref.invalidate(supportSummaryProvider);
    if (ticketId != null) ref.invalidate(supportTicketProvider(ticketId));
    ref.invalidate(unreadNotificationCountProvider);
  }

  static void afterHelpRefresh(WidgetRef ref) {
    ref.invalidate(supportHelpProvider);
  }

  static void invalidateAll(WidgetRef ref) {
    ref.invalidate(supportTicketListProvider);
    ref.invalidate(supportSummaryProvider);
    ref.invalidate(supportHelpProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }
}
