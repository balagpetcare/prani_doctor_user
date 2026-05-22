import 'package:flutter/material.dart';

class MilkSimpleBarChart extends StatelessWidget {
  const MilkSimpleBarChart({
    super.key,
    required this.labels,
    required this.values,
    this.barColor,
    this.maxValue,
  });

  final List<String> labels;
  final List<double> values;
  final Color? barColor;
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final max = maxValue ?? values.reduce((a, b) => a > b ? a : b);
    final color = barColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final fraction = max <= 0 ? 0.0 : values[index] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    values[index].toStringAsFixed(1),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: fraction.clamp(0.05, 1.0),
                        widthFactor: 0.7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MilkSessionSplitChart extends StatelessWidget {
  const MilkSessionSplitChart({
    super.key,
    required this.morningLiters,
    required this.eveningLiters,
    required this.morningLabel,
    required this.eveningLabel,
  });

  final double morningLiters;
  final double eveningLiters;
  final String morningLabel;
  final String eveningLabel;

  @override
  Widget build(BuildContext context) {
    final total = morningLiters + eveningLiters;
    if (total <= 0) {
      return Text(morningLabel, style: Theme.of(context).textTheme.bodySmall);
    }
    final morningFraction = morningLiters / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                Expanded(
                  flex: (morningFraction * 100).round().clamp(1, 100),
                  child: ColoredBox(color: Theme.of(context).colorScheme.primary),
                ),
                Expanded(
                  flex: ((1 - morningFraction) * 100).round().clamp(1, 100),
                  child: ColoredBox(color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$morningLabel: ${morningLiters.toStringAsFixed(1)} L'),
            Text('$eveningLabel: ${eveningLiters.toStringAsFixed(1)} L'),
          ],
        ),
      ],
    );
  }
}
