import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/inventory_dto.dart';
import '../data/inventory_repository.dart';
import 'inventory_navigation.dart';

class InventoryMedicineCreatePage extends ConsumerStatefulWidget {
  const InventoryMedicineCreatePage({super.key});

  @override
  ConsumerState<InventoryMedicineCreatePage> createState() =>
      _InventoryMedicineCreatePageState();
}

class _InventoryMedicineCreatePageState
    extends ConsumerState<InventoryMedicineCreatePage> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _thresholdController = TextEditingController();
  MedicineUnit _unit = MedicineUnit.ml;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.tr;
    final farmId = ref.read(activeFarmIdProvider).valueOrNull;
    if (farmId == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.t('inventoryNameRequired'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(inventoryRepositoryProvider).addStock(
      InventoryAddInput(
        farmRef: farmId,
        inventoryType: InventoryType.medicine,
        operation: 'CREATE_ITEM',
        displayName: name,
        medicineUnit: _unit,
        quantity: double.tryParse(_qtyController.text.trim()),
        lowStockThreshold: double.tryParse(_thresholdController.text.trim()),
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('inventoryAddMedicine'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.t(
              'Store what you have on hand. Treatment plans come from your vet or PraniDoctor — not from this screen.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.treatmentMedicineNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MedicineUnit>(
            value: _unit,
            decoration: InputDecoration(
              labelText: l10n.feedUnitLabel,
              border: const OutlineInputBorder(),
            ),
            items: MedicineUnit.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                .toList(),
            onChanged: (v) => setState(() => _unit = v ?? _unit),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.t('Quantity on hand'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.t('Low stock alert (optional)'),
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
                : Text(l10n.feedSaveChanges),
          ),
        ],
      ),
    );
  }
}
