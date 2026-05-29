import 'package:flutter/material.dart';

/// Standard centered loading indicator used across feature screens.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    const child = Center(child: CircularProgressIndicator());
    if (padding == null) return child;
    return Padding(padding: padding!, child: child);
  }
}
