import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/inventory_dto.dart';
import '../data/inventory_repository.dart';
import 'inventory_navigation.dart';
import 'inventory_providers.dart';

/// Add stock (receipt) for an existing catalog item.
class InventoryStockReceiptPage extends ConsumerStatefulWidget {
  const InventoryStockReceiptPage({
    super.key,
    required this.itemId,
    required this.inventoryType,
  });

  final String itemId;
  final InventoryType inventoryType;

  @override
  ConsumerState<InventoryStockReceiptPage> createState() =>
      _InventoryStockReceiptPageState();
}

class _InventoryStockReceiptPageState
    extends ConsumerState<InventoryStockReceiptPage> {
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.tr;
    final farmId = ref.read(activeFarmIdProvider).valueOrNull;
    if (farmId == null) return;
    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = l10n.feedAmountRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(inventoryRepositoryProvider).addStock(
      InventoryAddInput(
        farmRef: farmId,
        inventoryType: widget.inventoryType,
        operation: 'RECEIPT',
        inventoryItemId: widget.itemId,
        quantity: qty,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        InventoryNavigation.afterStockChange(ref, farmId);
        context.pop();
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final farmId = ref.watch(activeFarmIdProvider).valueOrNull ?? '';
    final listProvider = widget.inventoryType == InventoryType.feed
        ? inventoryFeedListProvider(farmId)
        : inventoryMedicineListProvider(farmId);
    final item = ref.watch(listProvider).maybeWhen(
      data: (s) => s.result.items.where((i) => i.id == widget.itemId).firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('inventoryAddStock'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (item != null)
            Text('${item.displayName}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.t('Quantity to add'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: l10n.t('Note (optional)'),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.t('inventoryRecordPurchase')),
          ),
        ],
      ),
    );
  }
}
