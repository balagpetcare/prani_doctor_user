import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../farm/presentation/farm_providers.dart';
import '../../feed/data/feed_dto.dart';
import '../../feed_catalog/data/feed_catalog_dto.dart';
import '../../feed_catalog/presentation/feed_catalog_multi_select.dart';
import '../../feed_catalog/presentation/feed_catalog_providers.dart';
import '../../offline/offline_providers.dart';
import '../data/inventory_dto.dart';
import '../data/inventory_repository.dart';
import 'inventory_navigation.dart';

enum _FeedAddSource { catalog, custom }

class InventoryFeedCreatePage extends ConsumerStatefulWidget {
  const InventoryFeedCreatePage({super.key});

  @override
  ConsumerState<InventoryFeedCreatePage> createState() =>
      _InventoryFeedCreatePageState();
}

class _InventoryFeedCreatePageState extends ConsumerState<InventoryFeedCreatePage> {
  final _nameController = TextEditingController();
  final _sharedQtyController = TextEditingController();
  final _sharedThresholdController = TextEditingController();
  final _catalogSearchController = TextEditingController();
  final Map<String, TextEditingController> _perItemQty = {};
  final Map<String, TextEditingController> _perItemThreshold = {};

  _FeedAddSource _source = _FeedAddSource.catalog;
  Set<String> _selectedCatalogIds = {};
  FeedType _feedType = FeedType.concentrate;
  FeedUnit _unit = FeedUnit.kg;
  bool _addCurrentStock = false;
  bool _applyQuantityToAll = true;
  bool _loading = false;
  String? _error;
  String? _qtyError;
  String? _thresholdError;

  @override
  void initState() {
    super.initState();
    _catalogSearchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
  }

  void _onSearchChanged() {
    ref.read(feedCatalogSearchQueryProvider.notifier).state =
        _catalogSearchController.text;
  }

  TextEditingController _qtyControllerFor(String feedId) {
    return _perItemQty.putIfAbsent(feedId, TextEditingController.new);
  }

  TextEditingController _thresholdControllerFor(String feedId) {
    return _perItemThreshold.putIfAbsent(feedId, TextEditingController.new);
  }

  void _syncPerItemControllers() {
    for (final id in _selectedCatalogIds) {
      _qtyControllerFor(id);
      _thresholdControllerFor(id);
    }
    final stale = _perItemQty.keys
        .where((id) => !_selectedCatalogIds.contains(id))
        .toList();
    for (final id in stale) {
      _perItemQty.remove(id)?.dispose();
      _perItemThreshold.remove(id)?.dispose();
    }
  }

  Future<void> _loadDraft() async {
    final cache = ref.read(localCacheServiceProvider);
    final raw = await cache.read(LocalCacheContract.inventoryFeedCreateDraftKey);
    if (raw == null || !mounted) return;

    final source = raw['source'] as String?;
    final ids = _parseCatalogIds(raw);
    setState(() {
      _source = source == 'custom' ? _FeedAddSource.custom : _FeedAddSource.catalog;
      _selectedCatalogIds = ids.toSet();
      _nameController.text = raw['displayName'] as String? ?? '';
      _addCurrentStock = raw['addCurrentStock'] as bool? ?? false;
      _applyQuantityToAll = raw['applyQuantityToAll'] as bool? ?? true;
      _sharedQtyController.text = raw['quantity']?.toString() ?? '';
      _sharedThresholdController.text = raw['lowStockThreshold']?.toString() ?? '';
      if (raw['feedType'] != null) {
        _feedType = FeedTypeApi.fromApi(raw['feedType'] as String);
      }
      if (raw['feedUnit'] != null) {
        _unit = FeedUnitApi.fromApi(raw['feedUnit'] as String);
      }
    });
    _syncPerItemControllers();
  }

  List<String> _parseCatalogIds(Map<String, dynamic> raw) {
    final multi = raw['feedCatalogIds'];
    if (multi is List) {
      return multi.whereType<String>().toList();
    }
    final legacy = raw['feedCatalogId'] as String?;
    if (legacy != null && legacy.isNotEmpty) return [legacy];
    return [];
  }

  double? _parseOptionalPositive(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed);
    if (value == null || value < 0) return double.nan;
    return value;
  }

  String? _validate({required bool forSubmit}) {
    final l10n = context.tr;
    if (_source == _FeedAddSource.catalog && _selectedCatalogIds.isEmpty) {
      return l10n.t('inventorySelectFeedFromList');
    }
    if (_source == _FeedAddSource.custom && _nameController.text.trim().isEmpty) {
      return l10n.t('inventoryNameRequired');
    }
    if (!_addCurrentStock || _source != _FeedAddSource.catalog) {
      return null;
    }

    if (_applyQuantityToAll) {
      final qty = _parseOptionalPositive(_sharedQtyController.text);
      if (qty != null && qty.isNaN) {
        return l10n.t('inventoryInvalidQuantity');
      }
      final threshold = _parseOptionalPositive(_sharedThresholdController.text);
      if (threshold != null && threshold.isNaN) {
        return l10n.t('inventoryInvalidThreshold');
      }
      return null;
    }

    for (final id in _selectedCatalogIds) {
      final qty = _parseOptionalPositive(_qtyControllerFor(id).text);
      if (qty != null && qty.isNaN) {
        return l10n.t('inventoryInvalidQuantity');
      }
      final threshold = _parseOptionalPositive(_thresholdControllerFor(id).text);
      if (threshold != null && threshold.isNaN) {
        return l10n.t('inventoryInvalidThreshold');
      }
    }
    return null;
  }

  List<InventoryFeedCatalogBatchItem> _buildBatchItems() {
    if (!_addCurrentStock) {
      return _selectedCatalogIds
          .map(
            (id) => InventoryFeedCatalogBatchItem(
              feedId: id,
              openingQuantity: null,
              lowStockLevel: null,
            ),
          )
          .toList();
    }

    if (_applyQuantityToAll) {
      final qty = _parseOptionalPositive(_sharedQtyController.text);
      final threshold = _parseOptionalPositive(_sharedThresholdController.text);
      return _selectedCatalogIds
          .map(
            (id) => InventoryFeedCatalogBatchItem(
              feedId: id,
              openingQuantity: qty != null && !qty.isNaN ? qty : null,
              lowStockLevel:
                  threshold != null && !threshold.isNaN ? threshold : null,
            ),
          )
          .toList();
    }

    return _selectedCatalogIds.map((id) {
      final qty = _parseOptionalPositive(_qtyControllerFor(id).text);
      final threshold = _parseOptionalPositive(_thresholdControllerFor(id).text);
      return InventoryFeedCatalogBatchItem(
        feedId: id,
        openingQuantity: qty != null && !qty.isNaN ? qty : null,
        lowStockLevel: threshold != null && !threshold.isNaN ? threshold : null,
      );
    }).toList();
  }

  Future<void> _saveDraft() async {
    final l10n = context.tr;
    final cache = ref.read(localCacheServiceProvider);
    await cache.write(
      LocalCacheContract.inventoryFeedCreateDraftKey,
      {
        'source': _source == _FeedAddSource.custom ? 'custom' : 'catalog',
        'feedCatalogIds': _selectedCatalogIds.toList(),
        'displayName': _nameController.text.trim(),
        'addCurrentStock': _addCurrentStock,
        'applyQuantityToAll': _applyQuantityToAll,
        'quantity': double.tryParse(_sharedQtyController.text.trim()),
        'lowStockThreshold': double.tryParse(_sharedThresholdController.text.trim()),
        'feedType': _feedType.apiValue,
        'feedUnit': _unit.apiValue,
      },
      const Duration(days: 30),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('feedDraftSaved'))),
      );
    }
  }

  @override
  void dispose() {
    _catalogSearchController.removeListener(_onSearchChanged);
    _nameController.dispose();
    _sharedQtyController.dispose();
    _sharedThresholdController.dispose();
    _catalogSearchController.dispose();
    for (final c in _perItemQty.values) {
      c.dispose();
    }
    for (final c in _perItemThreshold.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final farmId = ref.read(activeFarmIdProvider).valueOrNull;
    if (farmId == null) return;

    final validationError = _validate(forSubmit: true);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _qtyError = null;
      _thresholdError = null;
    });

    final repo = ref.read(inventoryRepositoryProvider);

    if (_source == _FeedAddSource.catalog) {
      final result = await repo.addFeedCatalogBatch(
        InventoryAddBatchInput(
          farmRef: farmId,
          items: _buildBatchItems(),
        ),
      );

      if (!mounted) return;

      result.when(
        success: (_) async {
          await ref.read(localCacheServiceProvider).delete(
            LocalCacheContract.inventoryFeedCreateDraftKey,
          );
          setState(() => _loading = false);
          InventoryNavigation.afterStockChange(ref, farmId);
          context.pop();
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
      return;
    }

    final name = _nameController.text.trim();
    final qty = _addCurrentStock
        ? _parseOptionalPositive(_sharedQtyController.text)
        : null;
    final threshold = _addCurrentStock
        ? _parseOptionalPositive(_sharedThresholdController.text)
        : null;

    final result = await repo.addStock(
      InventoryAddInput(
        farmRef: farmId,
        inventoryType: InventoryType.feed,
        operation: 'CREATE_ITEM',
        displayName: name,
        feedType: _feedType,
        feedUnit: _unit,
        quantity: qty != null && !qty.isNaN ? qty : null,
        lowStockThreshold:
            threshold != null && !threshold.isNaN ? threshold : null,
      ),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) async {
        await ref.read(localCacheServiceProvider).delete(
          LocalCacheContract.inventoryFeedCreateDraftKey,
        );
        InventoryNavigation.afterStockChange(ref, farmId);
        context.pop();
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  Widget _buildStockSection(List<FeedCatalogItem> catalogItems) {
    final l10n = context.tr;
    final selectedItems = catalogItems
        .where((i) => _selectedCatalogIds.contains(i.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(l10n.t('inventoryAddCurrentStock')),
          subtitle: Text(l10n.t('inventoryAddCurrentStockHint')),
          value: _addCurrentStock,
          onChanged: (v) => setState(() => _addCurrentStock = v),
        ),
        if (_addCurrentStock) ...[
          SwitchListTile(
            title: Text(l10n.t('inventorySameQuantityForAll')),
            value: _applyQuantityToAll,
            onChanged: (v) => setState(() => _applyQuantityToAll = v),
          ),
          if (_applyQuantityToAll) ...[
            TextField(
              controller: _sharedQtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.t('inventoryOpeningQuantityOptional'),
                errorText: _qtyError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                _qtyError = null;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sharedThresholdController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.t('inventoryLowStockAlertOptional'),
                errorText: _thresholdError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                _thresholdError = null;
                _error = null;
              }),
            ),
          ] else
            ...selectedItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.nameBn,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qtyControllerFor(item.id),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.t('inventoryOpeningQuantityOptional'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _thresholdControllerFor(item.id),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.t('inventoryLowStockAlertOptional'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final catalogAsync = ref.watch(feedCatalogFilteredProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('inventoryAddFeedToStock')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: l10n.t('feedSaveDraft'),
            onPressed: _loading ? null : _saveDraft,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_FeedAddSource>(
            segments: [
              ButtonSegment(
                value: _FeedAddSource.catalog,
                label: Text(l10n.t('inventoryFromList')),
              ),
              ButtonSegment(
                value: _FeedAddSource.custom,
                label: Text(l10n.t('inventoryCustomFeed')),
              ),
            ],
            selected: {_source},
            onSelectionChanged: (s) {
              setState(() {
                _source = s.first;
                if (_source == _FeedAddSource.custom) {
                  _selectedCatalogIds = {};
                } else {
                  _nameController.clear();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (_source == _FeedAddSource.catalog)
            catalogAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => FeedCatalogMultiSelect(
                items: const [],
                selectedIds: _selectedCatalogIds,
                onSelectionChanged: (ids) {
                  setState(() => _selectedCatalogIds = ids);
                  _syncPerItemControllers();
                },
                searchController: _catalogSearchController,
                errorText: '${l10n.t('inventoryListLoadFailed')}: $e',
              ),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeedCatalogMultiSelect(
                    items: items,
                    selectedIds: _selectedCatalogIds,
                    onSelectionChanged: (ids) {
                      setState(() => _selectedCatalogIds = ids);
                      _syncPerItemControllers();
                    },
                    searchController: _catalogSearchController,
                  ),
                  const SizedBox(height: 12),
                  _buildStockSection(items),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.t('Feed name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FeedType>(
              initialValue: _feedType,
              decoration: InputDecoration(
                labelText: l10n.feedTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: FeedType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _feedType = v ?? _feedType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FeedUnit>(
              initialValue: _unit,
              decoration: InputDecoration(
                labelText: l10n.feedUnitLabel,
                border: const OutlineInputBorder(),
              ),
              items: FeedUnit.values
                  .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                  .toList(),
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(l10n.t('inventoryAddCurrentStock')),
              subtitle: Text(l10n.t('inventoryAddCurrentStockHint')),
              value: _addCurrentStock,
              onChanged: (v) => setState(() => _addCurrentStock = v),
            ),
            if (_addCurrentStock) ...[
              TextField(
                controller: _sharedQtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.t('inventoryOpeningQuantityOptional'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sharedThresholdController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.t('inventoryLowStockAlertOptional'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading
                ? null
                : () {
                    final err = _validate(forSubmit: true);
                    if (err != null) {
                      setState(() => _error = err);
                      return;
                    }
                    _submit();
                  },
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _source == _FeedAddSource.catalog &&
                            _selectedCatalogIds.length > 1
                        ? l10n.t(
                            'Save {count} items',
                            {'count': _selectedCatalogIds.length},
                          )
                        : l10n.t('feedSaveChanges'),
                  ),
          ),
        ],
      ),
    );
  }
}
