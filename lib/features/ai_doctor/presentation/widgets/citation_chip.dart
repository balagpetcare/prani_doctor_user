import 'package:flutter/material.dart';

import '../../data/ai_doctor_dto.dart';

class CitationChip extends StatelessWidget {
  const CitationChip({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.menu_book_outlined, size: 16),
      label: Text(
        label.length > 48 ? '${label.substring(0, 48)}…' : label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      onPressed: onTap,
    );
  }
}

void showCitationBottomSheet(
  BuildContext context, {
  required List<RetrievedChunkModel> chunks,
  List<String> inlineCitations = const [],
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  'উৎস ও প্রমাণ',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (chunks.isEmpty && inlineCitations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('কোনো উৎস উপলব্ধ নেই'),
                  ),
                for (final chunk in chunks) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chunk.title,
                            style: Theme.of(ctx).textTheme.titleSmall,
                          ),
                          if (chunk.headingPath != null &&
                              chunk.headingPath!.isNotEmpty)
                            Text(
                              chunk.headingPath!,
                              style: Theme.of(ctx).textTheme.labelSmall,
                            ),
                          const SizedBox(height: 8),
                          Text(chunk.excerpt),
                          if (chunk.inlineCitation.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              chunk.inlineCitation,
                              style: Theme.of(ctx).textTheme.labelSmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final citation in inlineCitations) ...[
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(citation),
                    dense: true,
                  ),
                ],
              ],
            );
          },
        ),
      );
    },
  );
}

class CitationRow extends StatelessWidget {
  const CitationRow({
    super.key,
    required this.chunks,
    this.inlineCitations = const [],
  });

  final List<RetrievedChunkModel> chunks;
  final List<String> inlineCitations;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      ...chunks.map((c) => c.inlineCitation.isNotEmpty ? c.inlineCitation : c.title),
      ...inlineCitations,
    ].where((s) => s.trim().isNotEmpty).toSet().toList();

    if (labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in labels.take(6))
          CitationChip(
            label: label,
            onTap: () => showCitationBottomSheet(
              context,
              chunks: chunks,
              inlineCitations: inlineCitations,
            ),
          ),
        if (labels.length > 6)
          CitationChip(
            label: '+${labels.length - 6} আরও',
            onTap: () => showCitationBottomSheet(
              context,
              chunks: chunks,
              inlineCitations: inlineCitations,
            ),
          ),
      ],
    );
  }
}
