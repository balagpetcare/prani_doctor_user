import 'package:flutter/material.dart';

class StockQuantityChip extends StatelessWidget {
  const StockQuantityChip({
    super.key,
    required this.quantity,
    required this.unit,
    this.isLowStock = false,
  });

  final double quantity;
  final String unit;
  final bool isLowStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isLowStock ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer;
    final onColor = isLowStock ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_formatQty(quantity)} $unit',
        style: theme.textTheme.labelLarge?.copyWith(color: onColor),
      ),
    );
  }

  String _formatQty(double q) {
    if (q == q.roundToDouble()) return q.toStringAsFixed(0);
    return q.toStringAsFixed(1);
  }
}
