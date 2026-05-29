import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A thin [Scaffold] wrapper that handles:
///
/// * **Keyboard inset** — when [keyboardPadding] is `true` (default), the body
///   gains bottom padding equal to `viewInsets.bottom` so the last focusable
///   field is never hidden behind the soft keyboard, regardless of whether
///   `resizeToAvoidBottomInset` is set.
///
/// * **Safe area** — [useSafeArea] wraps the body in [SafeArea] (default:
///   `true`) for devices with notches / home indicators.
///
/// * **Scrollability** — [scrollable] wraps the body in a
///   [SingleChildScrollView] with physics that feel natural on all devices.
///
/// Use this instead of raw [Scaffold] in feature form pages.
///
/// ```dart
/// AppScaffold(
///   appBar: AppBar(title: Text(l10n.title)),
///   body: FormContent(),
///   scrollable: true,
/// )
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.scrollable = false,
    this.keyboardPadding = true,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;

  /// Wraps body in [SingleChildScrollView] with clamp physics.
  final bool scrollable;

  /// Adds bottom padding equal to the software keyboard height.
  final bool keyboardPadding;

  /// Wraps body in [SafeArea].
  final bool useSafeArea;

  /// Padding applied around the body content (inside SafeArea if enabled).
  final EdgeInsetsGeometry? padding;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: keyboardPadding
              ? MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl
              : AppSpacing.xxl,
        ),
        child: content,
      );
    } else if (keyboardPadding) {
      content = Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: content,
      );
    }

    if (useSafeArea) {
      content = SafeArea(
        // Only bottom: top is handled by the AppBar's own MediaQuery padding.
        top: appBar == null,
        child: content,
      );
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: !scrollable,
      body: content,
    );
  }
}
