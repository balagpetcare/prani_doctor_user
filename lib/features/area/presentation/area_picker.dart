import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/area/area_dto.dart';
import '../data/area_repository.dart';

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

  List<AreaNodeDto> _divisions = [];
  List<AreaNodeDto> _districts = [];
  List<AreaNodeDto> _upazilas = [];
  List<AreaNodeDto> _unions = [];
  List<AreaNodeDto> _villages = [];

  bool _loadingDivisions = true;
  bool _loadingDistricts = false;
  bool _loadingUpazilas = false;
  bool _loadingUnions = false;
  bool _loadingVillages = false;

  @override
  void initState() {
    super.initState();
    _divisionId = widget.initialDivisionId;
    _districtId = widget.initialDistrictId;
    _upazilaId = widget.initialUpazilaId;
    _unionId = widget.initialUnionId;
    _villageId = widget.initialVillageId;
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await _loadDivisions();
    if (_divisionId != null) await _loadDistricts(_divisionId!);
    if (_districtId != null) await _loadUpazilas(_districtId!);
    if (_upazilaId != null) await _loadUnions(_upazilaId!);
    if (_unionId != null) await _loadVillages(_unionId!);
  }

  Future<void> _loadDivisions() async {
    setState(() => _loadingDivisions = true);
    final page = await ref.read(areaRepositoryProvider).getDivisions(pageSize: 100);
    if (mounted) {
      setState(() {
        _divisions = page.data;
        _loadingDivisions = false;
      });
    }
  }

  Future<void> _loadDistricts(String divisionId) async {
    setState(() => _loadingDistricts = true);
    final page =
        await ref.read(areaRepositoryProvider).getDistricts(divisionId, pageSize: 100);
    if (mounted) {
      setState(() {
        _districts = page.data;
        _loadingDistricts = false;
      });
    }
  }

  Future<void> _loadUpazilas(String districtId) async {
    setState(() => _loadingUpazilas = true);
    final page =
        await ref.read(areaRepositoryProvider).getUpazilas(districtId, pageSize: 100);
    if (mounted) {
      setState(() {
        _upazilas = page.data;
        _loadingUpazilas = false;
      });
    }
  }

  Future<void> _loadUnions(String upazilaId) async {
    setState(() => _loadingUnions = true);
    final page = await ref.read(areaRepositoryProvider).getUnions(upazilaId, pageSize: 100);
    if (mounted) {
      setState(() {
        _unions = page.data;
        _loadingUnions = false;
      });
    }
  }

  Future<void> _loadVillages(String unionId) async {
    setState(() => _loadingVillages = true);
    final page = await ref.read(areaRepositoryProvider).getVillages(unionId, pageSize: 100);
    if (mounted) {
      setState(() {
        _villages = page.data;
        _loadingVillages = false;
      });
    }
  }

  void _emit() {
    String? label;
    if (_villageId != null) {
      label = _labelFor(_villages, _villageId);
    } else if (_unionId != null) {
      label = _labelFor(_unions, _unionId);
    } else if (_upazilaId != null) {
      label = _labelFor(_upazilas, _upazilaId);
    } else if (_districtId != null) {
      label = _labelFor(_districts, _districtId);
    } else if (_divisionId != null) {
      label = _labelFor(_divisions, _divisionId);
    }

    widget.onChanged(
      divisionId: _divisionId,
      districtId: _districtId,
      upazilaId: _upazilaId,
      unionId: _unionId,
      villageId: _villageId,
      selectedLabel: label,
    );
  }

  String? _labelFor(List<AreaNodeDto> items, String? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          label: widget.divisionLabel,
          value: _divisionId,
          items: _divisions,
          loading: _loadingDivisions,
          onChanged: (value) async {
            setState(() {
              _divisionId = value;
              _districtId = null;
              _upazilaId = null;
              _unionId = null;
              _villageId = null;
              _districts = [];
              _upazilas = [];
              _unions = [];
              _villages = [];
            });
            _emit();
            if (value != null) await _loadDistricts(value);
          },
        ),
        _dropdown(
          label: widget.districtLabel,
          value: _districtId,
          items: _districts,
          loading: _loadingDistricts,
          enabled: _divisionId != null,
          onChanged: (value) async {
            setState(() {
              _districtId = value;
              _upazilaId = null;
              _unionId = null;
              _villageId = null;
              _upazilas = [];
              _unions = [];
              _villages = [];
            });
            _emit();
            if (value != null) await _loadUpazilas(value);
          },
        ),
        _dropdown(
          label: widget.upazilaLabel,
          value: _upazilaId,
          items: _upazilas,
          loading: _loadingUpazilas,
          enabled: _districtId != null,
          onChanged: (value) async {
            setState(() {
              _upazilaId = value;
              _unionId = null;
              _villageId = null;
              _unions = [];
              _villages = [];
            });
            _emit();
            if (value != null) await _loadUnions(value);
          },
        ),
        _dropdown(
          label: widget.unionLabel,
          value: _unionId,
          items: _unions,
          loading: _loadingUnions,
          enabled: _upazilaId != null,
          onChanged: (value) async {
            setState(() {
              _unionId = value;
              _villageId = null;
              _villages = [];
            });
            _emit();
            if (value != null) await _loadVillages(value);
          },
        ),
        _dropdown(
          label: widget.villageLabel,
          value: _villageId,
          items: _villages,
          loading: _loadingVillages,
          enabled: _unionId != null,
          onChanged: (value) {
            setState(() => _villageId = value);
            _emit();
          },
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<AreaNodeDto> items,
    required bool loading,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: loading
            ? const LinearProgressIndicator()
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: items.any((e) => e.id == value) ? value : null,
                  hint: Text(label),
                  items: items
                      .map(
                        (node) => DropdownMenuItem<String>(
                          value: node.id,
                          child: Text(node.label),
                        ),
                      )
                      .toList(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
      ),
    );
  }
}
