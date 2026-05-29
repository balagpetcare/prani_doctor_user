import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class LivestockHealthStatusChip extends StatelessWidget {
  const LivestockHealthStatusChip({super.key, required this.status});

  final String status;

  Color _color(Brightness brightness) {
    switch (status) {
      case 'HEALTHY':
        return AppStatusColors.forTone(StatusTone.positive, brightness);
      case 'SICK':
      case 'CRITICAL':
        return AppStatusColors.forTone(StatusTone.danger, brightness);
      case 'RECOVERING':
        return AppStatusColors.forTone(StatusTone.warning, brightness);
      default:
        return AppStatusColors.forTone(StatusTone.neutral, brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(Theme.of(context).brightness);
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
