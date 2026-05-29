import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/inventory_dto.dart';
import 'stock_quantity_chip.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.item,
    this.daysRemaining,
    this.onTap,
  });

  final InventoryItem item;
  final int? daysRemaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final brightness = theme.brightness;
    final accentTone = item.inventoryType == InventoryType.feed
        ? StatusTone.positive
        : StatusTone.info;
    final accent = AppStatusColors.forTone(accentTone, brightness);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.12),
          child: Icon(
            item.inventoryType == InventoryType.feed
                ? Icons.grass_outlined
                : Icons.medication_outlined,
            color: accent,
          ),
        ),
        title: Text(item.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            StockQuantityChip(
              quantity: item.quantityAvailable,
              unit: item.unitLabel,
              isLowStock: item.isLowStock,
            ),
            if (daysRemaining != null) ...[
              const SizedBox(height: 6),
              Text(
                daysRemaining! > 0
                    ? l10n.translate(
                        TranslationKeys.inventoryDaysRemaining,
                        {'days': daysRemaining},
                      )
                    : l10n.translate(TranslationKeys.inventoryOutOfStock),
                style: theme.textTheme.bodySmall,
              ),
            ] else if (item.inventoryType == InventoryType.feed) ...[
              const SizedBox(height: 6),
              Text(
                l10n.translate(TranslationKeys.inventoryFeedLogHint),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (item.isLowStock) ...[
              const SizedBox(height: 4),
              Text(
                l10n.translate(TranslationKeys.inventoryLowStock),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        trailing: item.pendingSync
            ? const Icon(Icons.sync, size: 20)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
