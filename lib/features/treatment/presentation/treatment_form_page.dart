import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../farm/presentation/farm_providers.dart';
import '../../inventory/presentation/inventory_medicine_sync.dart';
import '../../offline/data/connectivity_service.dart';
import '../../offline/offline_providers.dart';
import '../data/treatment_dto.dart';
import '../data/treatment_repository.dart';
import '../data/treatment_validation.dart';
import 'treatment_navigation.dart';
import 'treatment_providers.dart';

class TreatmentFormPage extends ConsumerStatefulWidget {
  const TreatmentFormPage({super.key, this.recordId});

  final String? recordId;

  @override
  ConsumerState<TreatmentFormPage> createState() => _TreatmentFormPageState();
}

class _TreatmentFormPageState extends ConsumerState<TreatmentFormPage> {
  final _titleController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _medicineNameController = TextEditingController();
  final _medicineDosageController = TextEditingController();
  final _medicineFrequencyController = TextEditingController();
  final _medicineDurationController = TextEditingController();

  String? _farmRef;
  String? _animalId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TreatmentStatus _status = TreatmentStatus.active;
  final List<MedicineItem> _medicines = [];
  bool _deductMedicineStock = false;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    _medicineNameController.dispose();
    _medicineDosageController.dispose();
    _medicineFrequencyController.dispose();
    _medicineDurationController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(treatmentRepositoryProvider);
    final draft = await repo.readDraft(recordId: widget.recordId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.recordId != null) {
      final record = await ref.read(
        treatmentRecordProvider(widget.recordId!).future,
      );
      _applyInput(
        TreatmentInput(
          farmRef: record.farmRef,
          animalId: record.animalId,
          title: record.title,
          diagnosis: record.diagnosis,
          prescription: record.prescription,
          medicines: record.medicines,
          startDate: record.startDate,
          endDate: record.endDate,
          status: record.status,
          notes: record.notes,
        ),
      );
      if (mounted) setState(() {});
      return;
    }
    final farms = await ref.read(farmListProvider.future);
    if (farms.farms.isNotEmpty && mounted) {
      setState(() => _farmRef = farms.farms.first.id);
    }
  }

  void _applyInput(TreatmentInput input) {
    _farmRef = input.farmRef;
    _animalId = input.animalId;
    _startDate = input.startDate;
    _endDate = input.endDate;
    _status = input.status;
    _titleController.text = input.title;
    _diagnosisController.text = input.diagnosis ?? '';
    _prescriptionController.text = input.prescription ?? '';
    _notesController.text = input.notes ?? '';
    _medicines
      ..clear()
      ..addAll(input.medicines);
  }

  TreatmentInput _currentInput() {
    return TreatmentInput(
      farmRef: _farmRef,
      animalId: _animalId,
      title: _titleController.text.trim(),
      diagnosis: _diagnosisController.text.trim(),
      prescription: _prescriptionController.text.trim(),
      medicines: List.unmodifiable(_medicines),
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      notes: _notesController.text.trim(),
    );
  }

  void _addMedicine() {
    final l10n = AppLocalizations.of(context)!;
    final item = MedicineItem(
      name: _medicineNameController.text.trim(),
      dosage: _medicineDosageController.text.trim(),
      frequency: _medicineFrequencyController.text.trim().isEmpty
          ? null
          : _medicineFrequencyController.text.trim(),
      durationDays: int.tryParse(_medicineDurationController.text.trim()),
    );
    final error = TreatmentValidation.validateMedicine(
      item,
      message: l10n.treatmentMedicineRequired,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _medicines.add(item);
      _medicineNameController.clear();
      _medicineDosageController.clear();
      _medicineFrequencyController.clear();
      _medicineDurationController.clear();
      _error = null;
    });
  }

  Future<void> _saveDraft() async {
    await ref
        .read(treatmentRepositoryProvider)
        .saveDraft(_currentInput(), recordId: widget.recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.treatmentDraftSaved),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final titleError = TreatmentValidation.validateTitle(
      _titleController.text,
      message: l10n.treatmentTitleRequired,
    );
    final animalError = TreatmentValidation.validateAnimal(
      _animalId,
      message: l10n.treatmentAnimalRequired,
    );
    final dateError = TreatmentValidation.validateStartDate(
      _startDate,
      message: l10n.treatmentDateInvalid,
    );
    final error = titleError ?? animalError ?? dateError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (_deductMedicineStock && widget.recordId == null) {
      final online = isOnlineMode(
        ref.read(connectivityServiceProvider).currentMode,
      );
      if (!online) {
        setState(() => _error = 'Medicine stock update requires internet.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _submitting = true;
      _error = null;
    });

    final repo = ref.read(treatmentRepositoryProvider);
    final input = _currentInput();
    final result = widget.recordId == null
        ? await repo.createRecord(input)
        : await repo.updateRecord(widget.recordId!, input);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _submitting = false;
    });

    result.when(
      success: (record) async {
        if (_deductMedicineStock &&
            _farmRef != null &&
            _medicines.isNotEmpty &&
            widget.recordId == null) {
          await syncMedicineStockFromTreatment(
            ref: ref,
            farmRef: _farmRef!,
            treatmentId: record.id,
            medicines: _medicines,
          );
        }
        TreatmentNavigation.afterSave(ref, recordId: widget.recordId ?? record.id);
        if (context.mounted) context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          TreatmentNavigation.afterSave(ref, recordId: widget.recordId);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.treatmentOfflineSaved)));
          return;
        }
        setState(() => _error = e.message);
      },
    );
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final id = widget.recordId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.treatmentDeleteTitle),
        content: Text(l10n.treatmentDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.treatmentDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final result = await ref.read(treatmentRepositoryProvider).deleteRecord(id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        TreatmentNavigation.afterDelete(ref);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          TreatmentNavigation.afterDelete(ref);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.treatmentOfflineSaved)));
          return;
        }
        setState(() => _error = e.message);
      },
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final animalsAsync = ref.watch(animalListProvider);
    final farmsAsync = ref.watch(farmListProvider);
    final isEdit = widget.recordId != null;
    final livestock =
        animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.treatmentEditTitle : l10n.treatmentAddTitle),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: _loading ? null : _saveDraft,
            child: Text(l10n.treatmentSaveDraft),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          farmsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.treatmentFarmLoadError),
            data: (farms) {
              if (farms.farms.isEmpty) return Text(l10n.treatmentNoFarm);
              return DropdownButtonFormField<String>(
                initialValue: _farmRef ?? farms.farms.first.id,
                decoration: InputDecoration(labelText: l10n.treatmentFarmLabel),
                items: farms.farms
                    .map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _farmRef = v),
              );
            },
          ),
          const SizedBox(height: 12),
          animalsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.treatmentAnimalLoadError),
            data: (_) {
              if (livestock.isEmpty) return Text(l10n.treatmentNoAnimals);
              return DropdownButtonFormField<String>(
                initialValue: _animalId,
                decoration: InputDecoration(
                  labelText: l10n.treatmentAnimalLabel,
                ),
                items: livestock
                    .map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _animalId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.treatmentTitleLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _diagnosisController,
            decoration: InputDecoration(
              labelText: l10n.treatmentDiagnosisLabel,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _prescriptionController,
            decoration: InputDecoration(
              labelText: l10n.treatmentPrescriptionLabel,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.treatmentMedicinesTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _medicineNameController,
            decoration: InputDecoration(
              labelText: l10n.treatmentMedicineNameLabel,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _medicineDosageController,
            decoration: InputDecoration(labelText: l10n.treatmentDosageLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _medicineFrequencyController,
            decoration: InputDecoration(
              labelText: l10n.treatmentFrequencyLabel,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _medicineDurationController,
            decoration: InputDecoration(labelText: l10n.treatmentDurationLabel),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _addMedicine,
            child: Text(l10n.treatmentAddMedicine),
          ),
          if (_medicines.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._medicines.map(
              (m) => ListTile(
                title: Text(m.name),
                subtitle: Text(m.dosage),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _medicines.remove(m)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.treatmentStartDateLabel),
            subtitle: Text(_startDate.toLocal().toString().split(' ').first),
            trailing: IconButton(
              onPressed: () => _pickDate(start: true),
              icon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.treatmentEndDateLabel),
            subtitle: Text(
              _endDate?.toLocal().toString().split(' ').first ??
                  l10n.treatmentNoEndDate,
            ),
            trailing: IconButton(
              onPressed: () => _pickDate(start: false),
              icon: const Icon(Icons.event_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.treatmentNotesLabel),
            maxLines: 3,
          ),
          if (widget.recordId == null && _medicines.isNotEmpty) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Update medicine stock'),
              subtitle: const Text(
                'Matches medicine names in your inventory and reduces quantity (online only).',
              ),
              value: _deductMedicineStock,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _deductMedicineStock = v),
            ),
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
                : Text(
                    isEdit
                        ? l10n.treatmentSaveChanges
                        : l10n.treatmentCreateAction,
                  ),
          ),
        ],
      ),
    );
  }
}
