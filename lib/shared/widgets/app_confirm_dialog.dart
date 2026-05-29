import 'package:flutter/material.dart';

/// Shows a standardised confirm / delete dialog and returns `true` when the
/// user taps the confirm button.
///
/// Uses the app-wide [DialogTheme] so corner radii and title style are
/// consistent across features.
///
/// ```dart
/// final confirmed = await AppConfirmDialog.show(
///   context,
///   title: l10n.deleteTitle,
///   message: l10n.deleteMessage,
///   confirmLabel: l10n.delete,
///   destructive: true,
/// );
/// if (confirmed == true) { ... }
/// ```
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,

  /// When `true`, the confirm button uses `scheme.error` styling (for delete).
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
}

/// Internal widget used by [showAppConfirmDialog].
///
/// Can also be used directly when more customisation is needed.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confirmColor = destructive ? scheme.error : scheme.primary;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: confirmColor),
          child: Text(
            confirmLabel ?? MaterialLocalizations.of(context).okButtonLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
