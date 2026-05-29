import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Standard empty state: icon + message + optional primary action.
///
/// Replaces the duplicated `empty(...)` builders in per-feature
/// `*_feedback.dart` helpers.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            Gap.h16,
            Text(message, textAlign: TextAlign.center),
            if (onAction != null && actionLabel != null) ...[
              Gap.h16,
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
