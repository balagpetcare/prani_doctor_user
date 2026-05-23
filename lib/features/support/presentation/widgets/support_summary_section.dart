import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../support_providers.dart';

class SupportSummarySection extends StatelessWidget {
  const SupportSummarySection({super.key, required this.summary});

  final SupportSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip(
            label: l10n.supportSummaryOpen,
            value: summary.open,
            color: Colors.blue,
          ),
          _Chip(
            label: l10n.supportSummaryPending,
            value: summary.pending,
            color: Colors.orange,
          ),
          _Chip(
            label: l10n.supportSummaryResolved,
            value: summary.resolved,
            color: Colors.green,
          ),
          _Chip(
            label: l10n.supportSummaryClosed,
            value: summary.closed,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          '$value',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      label: Text(label),
    );
  }
}
