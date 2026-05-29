import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import '../data/phase4_feed_dto.dart';
import '../data/phase4_feed_repository.dart';
import 'phase4_feed_providers.dart';
import 'widgets/phase4_feed_feedback.dart';

class Phase4FeedInventoryListPage extends ConsumerWidget {
  const Phase4FeedInventoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final inventoryAsync = ref.watch(phase4FeedInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(TranslationKeys.phase4FeedInventoryTitle)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => context.push(AppRoutes.phase4FeedPurchase),
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: Phase4FeedFeedback.loading,
        error: (e, _) => Phase4FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(phase4FeedInventoryProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return Center(
              child: Text(l10n.t(TranslationKeys.phase4FeedInventoryEmpty)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(phase4FeedInventoryProvider);
              await ref.read(phase4FeedInventoryProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: page.items.length + (page.fromCache ? 1 : 0),
              itemBuilder: (context, index) {
                if (page.fromCache && index == 0) {
                  return Phase4FeedFeedback.offlineHint(context);
                }
                final item = page.items[page.fromCache ? index - 1 : index];
                return ListTile(
                  title: Text(item.displayName),
                  subtitle: Text(item.unit),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.quantityOnHand.toStringAsFixed(1)}'),
                      if (item.isLowStock)
                        Text(
                          l10n.t(TranslationKeys.inventoryLowStock),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class Phase4FeedPurchasePage extends ConsumerStatefulWidget {
  const Phase4FeedPurchasePage({super.key});

  @override
  ConsumerState<Phase4FeedPurchasePage> createState() =>
      _Phase4FeedPurchasePageState();
}

class _Phase4FeedPurchasePageState extends ConsumerState<Phase4FeedPurchasePage> {
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _supplierController = TextEditingController();
  String? _inventoryId;
  String _unit = 'KG';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDraft);
  }

  Future<void> _loadDraft() async {
    final draft = await ref.read(phase4FeedRepositoryProvider).readPurchaseDraft();
    if (!mounted || draft == null) return;
    _inventoryId = draft.feedInventoryId;
    _quantityController.text = draft.quantity.toString();
    _costController.text = draft.totalCostBdt?.toString() ?? '';
    _supplierController.text = draft.supplierName ?? '';
    _unit = draft.unit;
    setState(() {});
  }

  Future<void> _submit() async {
    final l10n = context.tr;
    final farmRef = ref.read(activeFarmRefProvider);
    if (farmRef == null || _inventoryId == null) return;

    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) return;

    final input = Phase4FeedPurchaseInput(
      farmRef: farmRef,
      feedInventoryId: _inventoryId!,
      quantity: quantity,
      unit: _unit,
      purchasedAt: DateTime.now().toIso8601String().substring(0, 10),
      totalCostBdt: double.tryParse(_costController.text.trim()),
      supplierName: _supplierController.text.trim().isEmpty
          ? null
          : _supplierController.text.trim(),
    );

    setState(() => _loading = true);
    final result =
        await ref.read(phase4FeedRepositoryProvider).recordPurchase(input);
    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ref.invalidate(phase4FeedInventoryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t(TranslationKeys.phase4FeedPurchaseSaved))),
        );
        context.pop();
      },
      failure: (e) {
        final msg = e.code == offlineQueuedCode
            ? l10n.t(TranslationKeys.phase4FeedOfflineSaved)
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (e.code == offlineQueuedCode) context.pop();
      },
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final inventoryAsync = ref.watch(phase4FeedInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.phase4FeedPurchaseTitle))),
      body: inventoryAsync.when(
        loading: Phase4FeedFeedback.loading,
        error: (e, _) => Phase4FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(phase4FeedInventoryProvider),
        ),
        data: (page) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: _inventoryId,
                decoration: InputDecoration(
                  labelText: l10n.t(TranslationKeys.phase4FeedInventoryItemLabel),
                ),
                items: page.items
                    .map(
                      (i) => DropdownMenuItem(
                        value: i.id,
                        child: Text(i.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _inventoryId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.t(TranslationKeys.phase4FeedQuantityLabel),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.t(TranslationKeys.phase4FeedCostLabel),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: l10n.t(TranslationKeys.phase4FeedSupplierLabel),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading || _inventoryId == null ? null : _submit,
                child: Text(l10n.t(TranslationKeys.phase4FeedSavePurchase)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Phase4FeedConsumptionPage extends ConsumerStatefulWidget {
  const Phase4FeedConsumptionPage({super.key, this.livestockId});

  final String? livestockId;

  @override
  ConsumerState<Phase4FeedConsumptionPage> createState() =>
      _Phase4FeedConsumptionPageState();
}

class _Phase4FeedConsumptionPageState
    extends ConsumerState<Phase4FeedConsumptionPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _inventoryId;
  String _unit = 'KG';
  bool _deductStock = true;
  bool _loading = false;

  Future<void> _submit() async {
    final l10n = context.tr;
    final farmRef = ref.read(activeFarmRefProvider);
    if (farmRef == null) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final input = Phase4FeedConsumptionInput(
      farmRef: farmRef,
      amount: amount,
      unit: _unit,
      recordedDate: DateTime.now().toIso8601String().substring(0, 10),
      livestockId: widget.livestockId,
      feedInventoryId: _inventoryId,
      deductStock: _deductStock,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _loading = true);
    final result =
        await ref.read(phase4FeedRepositoryProvider).recordConsumption(input);
    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ref.invalidate(phase4FeedInventoryProvider);
        ref.invalidate(phase4FeedConsumptionProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t(TranslationKeys.phase4FeedConsumptionSaved)),
          ),
        );
        context.pop();
      },
      failure: (e) {
        final msg = e.code == offlineQueuedCode
            ? l10n.t(TranslationKeys.phase4FeedOfflineSaved)
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (e.code == offlineQueuedCode) context.pop();
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final inventoryAsync = ref.watch(phase4FeedInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(TranslationKeys.phase4FeedConsumptionTitle)),
      ),
      body: inventoryAsync.when(
        loading: Phase4FeedFeedback.loading,
        error: (e, _) => Phase4FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(phase4FeedInventoryProvider),
        ),
        data: (page) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: _inventoryId,
                decoration: InputDecoration(
                  labelText: l10n.t(TranslationKeys.phase4FeedInventoryItemLabel),
                ),
                items: page.items
                    .map(
                      (i) => DropdownMenuItem(
                        value: i.id,
                        child: Text(i.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _inventoryId = v;
                  final item = page.items.firstWhere((i) => i.id == v);
                  _unit = item.unit;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.t(TranslationKeys.phase4FeedAmountLabel),
                ),
              ),
              SwitchListTile(
                title: Text(l10n.t(TranslationKeys.phase4FeedDeductStock)),
                value: _deductStock,
                onChanged: (v) => setState(() => _deductStock = v),
              ),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.t(TranslationKeys.livestockNotesLabel),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(l10n.t(TranslationKeys.phase4FeedSaveConsumption)),
              ),
            ],
          );
        },
      ),
    );
  }
}
