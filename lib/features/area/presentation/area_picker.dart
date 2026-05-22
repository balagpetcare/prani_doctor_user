import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/area/area_dto.dart';
import '../../../core/area/area_entities.dart';
import 'area_providers.dart';
import 'widgets/area_feedback.dart';

/// Cascading division → village dropdowns backed by `/api/area/*`.
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
  final void Function({
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
    String? villageId,
    String? selectedLabel,
  }) onChanged;

  @override
  ConsumerState<AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends ConsumerState<AreaPicker> {
  String? _divisionId;
  String? _districtId;
  String? _upazilaId;
  String? _unionId;
  String? _villageId;

  @override
  void initState() {
    super.initState();
    _divisionId = widget.initialDivisionId;
    _districtId = widget.initialDistrictId;
    _upazilaId = widget.initialUpazilaId;
    _unionId = widget.initialUnionId;
    _villageId = widget.initialVillageId;
  }

  String? _labelFor(List<AreaNodeDto> items, String? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item.label;
    }
    return null;
  }

  void _emit({String? selectedLabel}) {
    widget.onChanged(
      divisionId: _divisionId,
      districtId: _districtId,
      upazilaId: _upazilaId,
      unionId: _unionId,
      villageId: _villageId,
      selectedLabel: selectedLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LevelDropdown(
          label: widget.divisionLabel,
          value: _divisionId,
          async: ref.watch(divisionProvider),
          enabled: true,
          emptyMessage: l10n.areaEmptyDivisions,
          onRetry: () => ref.invalidate(divisionProvider),
          onChanged: (value, _) {
            setState(() {
              _divisionId = value;
              _districtId = null;
              _upazilaId = null;
              _unionId = null;
              _villageId = null;
            });
            _emit();
          },
        ),
        _LevelDropdown(
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
          onChanged: (value, _) {
            setState(() {
              _districtId = value;
              _upazilaId = null;
              _unionId = null;
              _villageId = null;
            });
            _emit();
          },
        ),
        _LevelDropdown(
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
          onChanged: (value, _) {
            setState(() {
              _upazilaId = value;
              _unionId = null;
              _villageId = null;
            });
            _emit();
          },
        ),
        _LevelDropdown(
          label: widget.unionLabel,
          value: _unionId,
          async: _upazilaId == null
              ? const AsyncData(AreaLevelResult.empty)
              : ref.watch(unionProvider(_upazilaId!)),
          enabled: _upazilaId != null,
          emptyMessage: l10n.areaEmptyUnions,
          onRetry: _upazilaId == null
              ? () {}
              : () => ref.invalidate(unionProvider(_upazilaId!)),
          onChanged: (value, _) {
            setState(() {
              _unionId = value;
              _villageId = null;
            });
            _emit();
          },
        ),
        _LevelDropdown(
          label: widget.villageLabel,
          value: _villageId,
          async: _unionId == null
              ? const AsyncData(AreaLevelResult.empty)
              : ref.watch(villageProvider(_unionId!)),
          enabled: _unionId != null,
          emptyMessage: l10n.areaEmptyVillages,
          onRetry: _unionId == null
              ? () {}
              : () => ref.invalidate(villageProvider(_unionId!)),
          onChanged: (value, nodes) {
            setState(() => _villageId = value);
            _emit(selectedLabel: _labelFor(nodes, value));
          },
        ),
      ],
    );
  }
}

class _LevelDropdown extends StatelessWidget {
  const _LevelDropdown({
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
          loading: () => AreaFeedback.loading(),
          error: (error, _) => AreaFeedback.error(
            context,
            message: error.toString(),
            onRetry: onRetry,
          ),
          data: (result) {
            if (result.isEmpty) {
              return AreaFeedback.empty(context, message: emptyMessage);
            }
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: result.nodes.any((e) => e.id == value) ? value : null,
                hint: Text(label),
                items: result.nodes
                    .map(
                      (node) => DropdownMenuItem<String>(
                        value: node.id,
                        child: Text(node.label),
                      ),
                    )
                    .toList(),
                onChanged: enabled
                    ? (selected) => onChanged(selected, result.nodes)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
