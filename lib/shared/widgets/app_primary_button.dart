import 'package:flutter/material.dart';

/// A [FilledButton] that shows a loading spinner when [isLoading] is `true`.
///
/// Replaces the ~10+ duplicated `_loading ? CircularProgressIndicator : Text`
/// patterns spread across feature form pages. The spinner uses `onPrimary`
/// so it remains high-contrast on the button surface.
///
/// ```dart
/// AppPrimaryButton(
///   label: l10n.save,
///   isLoading: _submitting,
///   onPressed: _submit,
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.expand = true,
  });

  final String label;

  /// Called when the button is tapped. Set to `null` to disable.
  final VoidCallback? onPressed;

  /// Shows a small [CircularProgressIndicator] in place of the label.
  final bool isLoading;

  /// Optional icon shown before the label (ignored while [isLoading]).
  final IconData? leadingIcon;

  /// When `true` (default), the button stretches to fill horizontal space.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: scheme.onPrimary,
        ),
      );
    } else if (leadingIcon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(leadingIcon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      child = Text(label);
    }

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    if (!expand) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}

/// A [FilledButton.tonal] variant for secondary submit actions.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: scheme.onSecondaryContainer,
        ),
      );
    } else if (leadingIcon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(leadingIcon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      child = Text(label);
    }

    final button = FilledButton.tonal(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    if (!expand) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}

/// A destructive [OutlinedButton] styled for delete / cancel actions.
class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.error,
              ),
            )
          : Text(label),
    );

    if (!expand) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}
