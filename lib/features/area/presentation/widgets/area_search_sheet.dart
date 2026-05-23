import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/area/area_dto.dart';
import '../area_providers.dart';

/// Opens a searchable list for picking an area node at any hierarchy level.
Future<AreaNodeDto?> showAreaNodeSearchSheet({
  required BuildContext context,
  required String title,
  required List<AreaNodeDto> nodes,
  String? selectedId,
}) {
  return showModalBottomSheet<AreaNodeDto>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AreaNodeSearchSheet(
      title: title,
      nodes: nodes,
      selectedId: selectedId,
    ),
  );
}

class _AreaNodeSearchSheet extends StatefulWidget {
  const _AreaNodeSearchSheet({
    required this.title,
    required this.nodes,
    this.selectedId,
  });

  final String title;
  final List<AreaNodeDto> nodes;
  final String? selectedId;

  @override
  State<_AreaNodeSearchSheet> createState() => _AreaNodeSearchSheetState();
}

class _AreaNodeSearchSheetState extends State<_AreaNodeSearchSheet> {
  String _filter = '';

  List<AreaNodeDto> get _filtered {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return widget.nodes;
    return widget.nodes
        .where(
          (node) =>
              node.label.toLowerCase().contains(q) ||
              node.nameBn.toLowerCase().contains(q) ||
              node.nameEn.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.areaSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.areaSearchNoResults))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final node = filtered[index];
                      return ListTile(
                        title: Text(node.label),
                        selected: node.id == widget.selectedId,
                        onTap: () => Navigator.of(context).pop(node),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for API village search results.
Future<AreaSearchHitDto?> showAreaVillageSearchSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AreaSearchParams params,
}) {
  return showModalBottomSheet<AreaSearchHitDto>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AreaVillageSearchSheet(params: params),
  );
}

class _AreaVillageSearchSheet extends ConsumerStatefulWidget {
  const _AreaVillageSearchSheet({required this.params});

  final AreaSearchParams params;

  @override
  ConsumerState<_AreaVillageSearchSheet> createState() =>
      _AreaVillageSearchSheetState();
}

class _AreaVillageSearchSheetState
    extends ConsumerState<_AreaVillageSearchSheet> {
  late AreaSearchParams _params;

  @override
  void initState() {
    super.initState();
    _params = widget.params;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(areaSearchProvider(_params));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.areaSearchVillagesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.areaSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(
              () => _params = AreaSearchParams(
                query: value,
                unionId: widget.params.unionId,
                upazilaId: widget.params.upazilaId,
                districtId: widget.params.districtId,
                divisionId: widget.params.divisionId,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(error.toString()),
              data: (page) {
                if (page.data.isEmpty) {
                  return Center(child: Text(l10n.areaSearchNoResults));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: page.data.length,
                  itemBuilder: (context, index) {
                    final hit = page.data[index];
                    return ListTile(
                      title: Text(hit.label),
                      subtitle: hit.breadcrumb != null
                          ? Text(hit.breadcrumb!)
                          : null,
                      onTap: () => Navigator.of(context).pop(hit),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
