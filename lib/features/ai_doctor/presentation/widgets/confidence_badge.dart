import 'package:flutter/material.dart';

import '../../data/ai_doctor_dto.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.compact = false,
  });

  final CaseConfidenceModel confidence;
  final bool compact;

  Color _color(BuildContext context) {
    switch (confidence.tier) {
      case ConfidenceTier.strong:
        return Colors.green.shade700;
      case ConfidenceTier.moderate:
        return Colors.blue.shade700;
      case ConfidenceTier.limited:
        return Colors.orange.shade800;
      case ConfidenceTier.insufficient:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final label = confidence.tier.labelBn();
    final score = (confidence.caseScore * 100).clamp(0, 100).toStringAsFixed(0);

    if (compact) {
      return Chip(
        avatar: Icon(Icons.verified_outlined, size: 16, color: color),
        label: Text('$label ($score%)'),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      );
    }

    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'আস্থার স্তর: $label',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'কেস স্কোর: $score%'
                    '${confidence.failClosed ? ' · সীমিত নির্ভরযোগ্যতা' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
