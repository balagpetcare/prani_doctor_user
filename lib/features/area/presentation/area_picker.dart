import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/area/area_dto.dart';
import '../../../core/area/area_entities.dart';
import '../../../core/area/area_repository_contract.dart';
import 'area_providers.dart';
import 'widgets/area_feedback.dart';
import 'widgets/area_search_sheet.dart';
import 'widgets/village_input_field.dart';

/// Cascading division → village picker backed by `/api/mobile/locations/*`.
class AreaPicker extends ConsumerStatefulWidget {
  const AreaPicker({
    super.key,
    required this.divisionLabel,
    required this.districtLabel,
    required this.upazilaLabel,
    required this.unionLabel,
    required this.villageLabel,
    this.initialDivisionId,
    this.initialDistrictId,
    this.initialUpazilaId,
    this.initialUnionId,
    this.initialVillageId,
    this.initialVillageName,
    this.villageRequired = false,
    required this.onChanged,
  });

  final String divisionLabel;
  final String districtLabel;
  final String upazilaLabel;
  final String unionLabel;
  final String villageLabel;
  final String? initialDivisionId;
  final String? initialDistrictId;
  final String? initialUpazilaId;
  final String? initialUnionId;
  final String? initialVillageId;
  final String? initialVillageName;
  final bool villageRequired;
  final void Function({
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
    String? villageId,
    String? villageName,
    String? selectedLabel,
  })
  onChanged;

  @override
  ConsumerState<AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends ConsumerState<AreaPicker> {
  String? _divisionId;
  String? _districtId;
  String? _upazilaId;
  String? _unionId;
  String? _villageId;
  String? _villageName;
  String? _selectedLabel;
  String? _unionLabel;

  @override
  void initState() {
    super.initState();
    _applyInitialValues();
  }

  void _applyInitialValues() {
    _divisionId = widget.initialDivisionId;
    _districtId = widget.initialDistrictId;
    _upazilaId = widget.initialUpazilaId;
    _unionId = widget.initialUnionId;
    _villageId = widget.initialVillageId;
    _villageName = widget.initialVillageName;
  }

  @override
  void didUpdateWidget(AreaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDivisionId != widget.initialDivisionId ||
        oldWidget.initialDistrictId != widget.initialDistrictId ||
        oldWidget.initialUpazilaId != widget.initialUpazilaId ||
        oldWidget.initialUnionId != widget.initialUnionId ||
        oldWidget.initialVillageId != widget.initialVillageId ||
        oldWidget.initialVillageName != widget.initialVillageName) {
      setState(_applyInitialValues);
    }
  }

  String? _labelFor(List<AreaNodeDto> items, String? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item.label;
    }
    return null;
  }

  void _emit({String? selectedLabel}) {
    if (selectedLabel != null) _selectedLabel = selectedLabel;
    widget.onChanged(
      divisionId: _divisionId,
      districtId: _districtId,
      upazilaId: _upazilaId,
      unionId: _unionId,
      villageId: _villageId,
      villageName: _villageName,
      selectedLabel: selectedLabel ?? _selectedLabel ?? _composeLocationLabel(),
    );
  }

  String? _composeLocationLabel() {
    if (_villageName != null && _villageName!.trim().isNotEmpty) {
      return _villageName!.trim();
    }
    if (_selectedLabel != null && _selectedLabel!.isNotEmpty) {
      return _selectedLabel;
    }
    return _unionLabel;
  }

  Future<void> _refreshHierarchy() async {
    invalidateAreaHierarchy(
      ref,
      divisionId: _divisionId,
      districtId: _districtId,
      upazilaId: _upazilaId,
      unionId: _unionId,
    );
  }

  Future<void> _searchVillages() async {
    final hit = await showAreaVillageSearchSheet(
      context: context,
      ref: ref,
      params: AreaSearchParams(
        query: '',
        unionId: _unionId,
        upazilaId: _upazilaId,
        districtId: _districtId,
        divisionId: _divisionId,
      ),
    );
    if (hit == null || !mounted) return;

    setState(() {
      if (hit.parentId != null && hit.parentId!.isNotEmpty) {
        _unionId = hit.parentId;
      }
      _villageId = hit.id;
      _selectedLabel = hit.breadcrumb ?? hit.label;
    });
    _emit(selectedLabel: _selectedLabel);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showOfflineHint = ref.watch(areaOfflineHintProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.areaSelectLevel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: l10n.areaRefresh,
              onPressed: _refreshHierarchy,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (showOfflineHint) AreaFeedback.offlineHint(context),
        _LevelSelector(
          label: widget.divisionLabel,
          value: _divisionId,
          async: ref.watch(divisionProvider),
          enabled: true,
          emptyMessage: l10n.areaEmptyDivisions,
          onRetry: () => ref.invalidate(divisionProvider),
          onChanged: (value, nodes) {
            setState(() {
              _divisionId = value;
              _districtId = null;
              _upazilaId = null;
              _unionId = null;
              _villageId = null;
              _villageName = null;
              _selectedLabel = null;
              _unionLabel = null;
            });
            _emit();
          },
        ),
        _LevelSelector(
          label: widget.districtLabel,
          value: _districtId,
          async: _divisionId == null
              ? const AsyncData(AreaLevelResult.empty)
              : ref.watch(districtProvider(_divisionId!)),
          enabled: _divisionId != null,
          emptyMessage: l10n.areaEmptyDistricts,
          onRetry: _divisionId == null
              ? () {}
              : () => ref.invalidate(districtProvider(_divisionId!)),
          onChanged: (value, nodes) {
            setState(() {
              _districtId = value;
              _upazilaId = null;
              _unionId = null;
              _villageId = null;
              _villageName = null;
              _selectedLabel = null;
              _unionLabel = null;
            });
            _emit();
          },
        ),
        _LevelSelector(
          label: widget.upazilaLabel,
          value: _upazilaId,
          async: _districtId == null
              ? const AsyncData(AreaLevelResult.empty)
              : ref.watch(upazilaProvider(_districtId!)),
          enabled: _districtId != null,
          emptyMessage: l10n.areaEmptyUpazilas,
          onRetry: _districtId == null
              ? () {}
              : () => ref.invalidate(upazilaProvider(_districtId!)),
          onChanged: (value, nodes) {
            setState(() {
              _upazilaId = value;
              _unionId = null;
              _villageId = null;
              _villageName = null;
              _selectedLabel = null;
              _unionLabel = null;
            });
            _emit();
          },
        ),
        _LevelSelector(
          label: widget.unionLabel,
          value: _unionId,
          async: _districtId == null || _upazilaId == null
              ? const AsyncData(AreaLevelResult.empty)
              : ref.watch(
                  unionProvider(
                    AreaUnionQuery(
                      districtId: _districtId!,
                      upazilaId: _upazilaId!,
                    ),
                  ),
                ),
          enabled: _districtId != null && _upazilaId != null,
          emptyMessage: l10n.areaEmptyUnions,
          onRetry: _districtId == null || _upazilaId == null
              ? () {}
              : () => ref.invalidate(
                  unionProvider(
                    AreaUnionQuery(
                      districtId: _districtId!,
                      upazilaId: _upazilaId!,
                    ),
                  ),
                ),
          onChanged: (value, nodes) {
            setState(() {
              _unionId = value;
              _unionLabel = _labelFor(nodes, value);
              _villageId = null;
              _villageName = null;
              _selectedLabel = null;
            });
            _emit(selectedLabel: _unionLabel);
          },
        ),
        VillageInputField(
          label: widget.villageLabel,
          unionId: _unionId,
          initialVillageId: _villageId,
          initialVillageName: _villageName,
          onChanged: ({villageId, villageName, label}) {
            setState(() {
              _villageId = villageId;
              _villageName = villageName;
              if (label != null) _selectedLabel = label;
            });
            _emit(selectedLabel: label);
          },
        ),
        if (_unionId != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _searchVillages,
              icon: const Icon(Icons.search, size: 18),
              label: Text(l10n.areaSearchVillagesTitle),
            ),
          ),
        ],
        if ((_villageId != null || (_villageName?.isNotEmpty ?? false)) &&
            (_selectedLabel?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(l10n.areaSelectedLocation),
              subtitle: Text(_selectedLabel!),
            ),
          ),
        ],
      ],
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.label,
    required this.value,
    required this.async,
    required this.enabled,
    required this.emptyMessage,
    required this.onRetry,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final AsyncValue<AreaLevelResult> async;
  final bool enabled;
  final String emptyMessage;
  final VoidCallback onRetry;
  final void Function(String? value, List<AreaNodeDto> nodes) onChanged;

  Future<void> _openSearch(
    BuildContext context,
    List<AreaNodeDto> nodes,
  ) async {
    final selected = await showAreaNodeSearchSheet(
      context: context,
      title: label,
      nodes: nodes,
      selectedId: value,
    );
    if (selected != null) {
      onChanged(selected.id, nodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: async.when(
          loading: AreaFeedback.loading,
          error: (error, _) => AreaFeedback.error(
            context,
            message: error.toString(),
            onRetry: onRetry,
          ),
          data: (result) {
            if (result.isEmpty) {
              return AreaFeedback.empty(context, message: emptyMessage);
            }

            final selectedLabel = value == null
                ? null
                : result.nodes
                      .where((e) => e.id == value)
                      .map((e) => e.label)
                      .firstOrNull;

            return InkWell(
              onTap: enabled ? () => _openSearch(context, result.nodes) : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel ?? label,
                      style: selectedLabel == null
                          ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            )
                          : null,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
