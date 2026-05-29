import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable status chip with a semantic [StatusTone].
///
/// Automatically adapts background and label opacity to the current
/// [Brightness] so the chip is legible in both light and dark mode.
/// Replaces per-feature chips that hardcode `Colors.green` / `Colors.grey`.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = AppStatusColors.forTone(tone, brightness);
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
    );
  }
}
