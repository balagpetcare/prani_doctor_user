import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Shows a standardised modal bottom sheet that inherits the global
/// [BottomSheetTheme] (drag handle, rounded corners, surface colour).
///
/// Automatically wraps content in [SafeArea] and scrollable padding so the
/// sheet works correctly on devices with a home indicator.
///
/// ```dart
/// showAppBottomSheet(
///   context,
///   title: l10n.selectArea,
///   builder: (ctx) => AreaSearchContent(),
/// );
/// ```
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  String? title,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool showDragHandle = true,
  double? maxHeightFraction,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    showDragHandle: showDragHandle,
    constraints: maxHeightFraction != null
        ? BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
          )
        : null,
    builder: (ctx) => _AppBottomSheetContent(
      title: title,
      child: builder(ctx),
    ),
  );
}

/// Internal content wrapper for [showAppBottomSheet].
class _AppBottomSheetContent extends StatelessWidget {
  const _AppBottomSheetContent({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.sm,
                ),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// A bottom sheet body widget that handles the common pattern of a title bar
/// with a close button, followed by scrollable content.
///
/// Useful when `showAppBottomSheet` needs a close button in addition to the
/// drag handle.
class AppBottomSheetBody extends StatelessWidget {
  const AppBottomSheetBody({
    super.key,
    this.title,
    required this.child,
    this.padding,
  });

  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding:
                  padding ??
                  const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
