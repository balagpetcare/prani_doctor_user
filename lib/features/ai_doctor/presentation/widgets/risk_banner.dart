import 'package:flutter/material.dart';

import '../../data/ai_doctor_dto.dart';

class RiskBanner extends StatelessWidget {
  const RiskBanner({
    super.key,
    required this.risk,
    this.localeBn = true,
  });

  final CaseRiskAssessmentModel risk;
  final bool localeBn;

  Color _backgroundColor() {
    if (risk.emergency || risk.urgencyTier == UrgencyTier.critical) {
      return Colors.red.shade50;
    }
    if (risk.urgencyTier == UrgencyTier.high) {
      return Colors.orange.shade50;
    }
    if (risk.urgencyTier == UrgencyTier.medium) {
      return Colors.amber.shade50;
    }
    return Colors.green.shade50;
  }

  Color _foregroundColor() {
    if (risk.emergency || risk.urgencyTier == UrgencyTier.critical) {
      return Colors.red.shade900;
    }
    if (risk.urgencyTier == UrgencyTier.high) {
      return Colors.orange.shade900;
    }
    return Colors.black87;
  }

  IconData _icon() {
    if (risk.emergency) return Icons.emergency;
    if (risk.escalationRequired) return Icons.warning_amber_rounded;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = localeBn
        ? risk.recommendationBn
        : (risk.recommendationEn.isNotEmpty
            ? risk.recommendationEn
            : risk.recommendationBn);

    return Card(
      color: _backgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon(), color: _foregroundColor()),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        risk.emergency
                            ? 'জরুরি সতর্কতা'
                            : 'ঝুঁকি: ${risk.triageBucket}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _foregroundColor(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (recommendation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          recommendation,
                          style: TextStyle(color: _foregroundColor()),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (risk.redFlags.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final flag in risk.redFlags)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: _foregroundColor()),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          localeBn ? flag.labelBn : flag.labelEn,
                          style: TextStyle(color: _foregroundColor()),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
