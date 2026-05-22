import 'package:flutter/material.dart';

import 'notification_list_page.dart';

/// Inbox tab wrapper — preserves existing import path.
class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) => const NotificationListPage();
}
