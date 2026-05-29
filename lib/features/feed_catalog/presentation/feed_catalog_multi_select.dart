import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../data/feed_catalog_dto.dart';

typedef FeedCatalogSelectionChanged = void Function(Set<String> selectedIds);

class FeedCatalogMultiSelect extends StatelessWidget {
  const FeedCatalogMultiSelect({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.searchController,
    this.isLoading = false,
    this.errorText,
  });

  final List<FeedCatalogItem> items;
  final Set<String> selectedIds;
  final FeedCatalogSelectionChanged onSelectionChanged;
  final TextEditingController searchController;
  final bool isLoading;
  final String? errorText;

  List<FeedCatalogItem> get _selectedItems =>
      items.where((item) => selectedIds.contains(item.id)).toList();

  void _toggle(FeedCatalogItem item) {
    final next = Set<String>.from(selectedIds);
    if (next.contains(item.id)) {
      next.remove(item.id);
    } else {
      next.add(item.id);
    }
    onSelectionChanged(next);
  }

  void _remove(String id) {
    onSelectionChanged(Set<String>.from(selectedIds)..remove(id));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorText != null) {
      return Text(errorText!);
    }

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: l10n.translate(TranslationKeys.feedCatalogSearchLabel),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (selectedIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.translate(
              TranslationKeys.feedCatalogSelectedCount,
              {'count': selectedIds.length},
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedItems
                .map(
                  (item) => InputChip(
                    label: Text(item.nameBn),
                    onDeleted: () => _remove(item.id),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => FilterChip(
                  label: Text(item.nameBn),
                  selected: selectedIds.contains(item.id),
                  onSelected: (_) => _toggle(item),
                  avatar: selectedIds.contains(item.id)
                      ? const Icon(Icons.check, size: 16)
                      : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
