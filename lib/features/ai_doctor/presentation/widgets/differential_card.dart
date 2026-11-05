import 'package:flutter/material.dart';

import '../../data/ai_doctor_dto.dart';
import 'citation_chip.dart';
import 'confidence_badge.dart';

class DifferentialCard extends StatelessWidget {
  const DifferentialCard({
    super.key,
    required this.differential,
    this.onCitationTap,
  });

  final GroundedDifferentialModel differential;
  final VoidCallback? onCitationTap;

  @override
  Widget build(BuildContext context) {
    final score =
        (differential.confidenceScore * 100).clamp(0, 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text('${differential.rank}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    differential.titleBn.isNotEmpty
                        ? differential.titleBn
                        : differential.titleEn,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text('$score%'),
              ],
            ),
            if (differential.evidenceLevel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'প্রমাণ: ${differential.evidenceLevel}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            if (differential.citations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final citation in differential.citations.take(4))
                    CitationChip(
                      label: citation,
                      onTap: onCitationTap,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DifferentialList extends StatelessWidget {
  const DifferentialList({
    super.key,
    required this.differentials,
    this.chunks = const [],
  });

  final List<GroundedDifferentialModel> differentials;
  final List<RetrievedChunkModel> chunks;

  @override
  Widget build(BuildContext context) {
    if (differentials.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'সম্ভাব্য কারণ',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final diff in differentials)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DifferentialCard(
              differential: diff,
              onCitationTap: () => showCitationBottomSheet(
                context,
                chunks: chunks,
                inlineCitations: diff.citations,
              ),
            ),
          ),
      ],
    );
  }
}

class AnalysisSummaryCard extends StatelessWidget {
  const AnalysisSummaryCard({
    super.key,
    required this.analysis,
  });

  final AnalyzeCaseResultModel analysis;

  @override
  Widget build(BuildContext context) {
    final chunks = analysis.pack?.chunks ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConfidenceBadge(confidence: analysis.confidence),
        const SizedBox(height: 12),
        DifferentialList(
          differentials: analysis.differentials,
          chunks: chunks,
        ),
        if (chunks.isNotEmpty ||
            analysis.differentials.any((d) => d.citations.isNotEmpty)) ...[
          const SizedBox(height: 8),
          CitationRow(
            chunks: chunks,
            inlineCitations: analysis.differentials
                .expand((d) => d.citations)
                .toList(),
          ),
        ],
      ],
    );
  }
}
