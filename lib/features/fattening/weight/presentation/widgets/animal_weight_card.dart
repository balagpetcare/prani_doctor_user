import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/weight_dto.dart';

class AnimalWeightCard extends StatelessWidget {
  const AnimalWeightCard({
    super.key,
    required this.progress,
    this.onRecord,
    this.compact = false,
  });

  final AnimalWeightProgress progress;
  final VoidCallback? onRecord;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gain = _gain(progress.gainKg);
    final current = _kg(progress.currentWeightKg);

    if (compact) {
      return ListTile(
        leading: CircleAvatar(
          child: Text(
            progress.animalName.isNotEmpty
                ? progress.animalName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(progress.animalName),
        subtitle: Text('$current · $gain'),
        trailing: onRecord != null
            ? IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onRecord,
                tooltip: l10n.fatteningRecordWeight,
              )
            : null,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.animalName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (onRecord != null)
                  TextButton(
                    onPressed: onRecord,
                    child: Text(l10n.fatteningRecordWeight),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: l10n.fatteningInitialWeight,
                    value: _kg(progress.initialWeightKg),
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: l10n.fatteningCurrentWeight,
                    value: current,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: l10n.fatteningGain,
                    value: gain,
                    highlight: true,
                  ),
                ),
              ],
            ),
            if (progress.recordCount > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _growthFraction(progress),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.fatteningWeightRecordCount(progress.recordCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double? _growthFraction(AnimalWeightProgress p) {
    final initial = double.tryParse(p.initialWeightKg ?? '');
    final current = double.tryParse(p.currentWeightKg ?? '');
    if (initial == null || current == null || initial <= 0) return null;
    return ((current - initial) / initial).clamp(0.0, 1.0);
  }

  String _kg(String? v) => v != null && v.isNotEmpty ? '$v kg' : '—';

  String _gain(String? v) {
    if (v == null || v.isEmpty) return '—';
    final n = double.tryParse(v);
    if (n == null) return '$v kg';
    final sign = n > 0 ? '+' : '';
    return '$sign$v kg';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: highlight ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
