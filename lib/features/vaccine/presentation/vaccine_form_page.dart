import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/vaccine_dto.dart';
import '../data/vaccine_repository.dart';
import '../data/vaccine_validation.dart';
import 'vaccine_providers.dart';

class VaccineFormPage extends ConsumerStatefulWidget {
  const VaccineFormPage({super.key, this.recordId});

  final String? recordId;

  @override
  ConsumerState<VaccineFormPage> createState() => _VaccineFormPageState();
}

class _VaccineFormPageState extends ConsumerState<VaccineFormPage> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();

  String? _farmRef;
  String? _animalId;
  DateTime _scheduledDate = DateTime.now();
  DateTime? _administeredDate;
  DateTime? _nextDueDate;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(vaccineRepositoryProvider);
    final draft = await repo.readDraft(recordId: widget.recordId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.recordId != null) {
      final record = await ref.read(vaccineRecordProvider(widget.recordId!).future);
      _applyInput(
        VaccineInput(
          farmRef: record.farmRef,
          animalId: record.animalId,
          vaccineName: record.vaccineName,
          vaccineType: record.vaccineType,
          scheduledDate: record.scheduledDate,
          administeredDate: record.administeredDate,
          nextDueDate: record.nextDueDate,
          batchNumber: record.batchNumber,
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

  void _applyInput(VaccineInput input) {
    _farmRef = input.farmRef;
    _animalId = input.animalId;
    _scheduledDate = input.scheduledDate;
    _administeredDate = input.administeredDate;
    _nextDueDate = input.nextDueDate;
    _nameController.text = input.vaccineName;
    _typeController.text = input.vaccineType ?? '';
    _batchController.text = input.batchNumber ?? '';
    _notesController.text = input.notes ?? '';
  }

  VaccineInput _currentInput() {
    return VaccineInput(
      farmRef: _farmRef,
      animalId: _animalId,
      vaccineName: _nameController.text.trim(),
      vaccineType: _typeController.text.trim(),
      scheduledDate: _scheduledDate,
      administeredDate: _administeredDate,
      nextDueDate: _nextDueDate,
      batchNumber: _batchController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _saveDraft() async {
    await ref.read(vaccineRepositoryProvider).saveDraft(_currentInput(), recordId: widget.recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.vaccineDraftSaved)),
      );
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final nameError = VaccineValidation.validateName(_nameController.text, message: l10n.vaccineNameRequired);
    final animalError = VaccineValidation.validateAnimal(_animalId, message: l10n.vaccineAnimalRequired);
    final dateError = VaccineValidation.validateScheduledDate(_scheduledDate, message: l10n.vaccineDateInvalid);
    final error = nameError ?? animalError ?? dateError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(vaccineRepositoryProvider);
    final input = _currentInput();
    final result = widget.recordId == null
        ? await repo.createRecord(input)
        : await repo.updateRecord(widget.recordId!, input);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ref.invalidate(vaccineProvider);
        ref.invalidate(vaccineReminderProvider);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          ref.invalidate(vaccineProvider);
          ref.invalidate(vaccineReminderProvider);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.vaccineOfflineSaved)));
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
        title: Text(l10n.vaccineDeleteTitle),
        content: Text(l10n.vaccineDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.vaccineDeleteAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final result = await ref.read(vaccineRepositoryProvider).deleteRecord(id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        ref.invalidate(vaccineProvider);
        ref.invalidate(vaccineReminderProvider);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          ref.invalidate(vaccineProvider);
          ref.invalidate(vaccineReminderProvider);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.vaccineOfflineSaved)));
          return;
        }
        setState(() => _error = e.message);
      },
    );
  }

  Future<void> _pickDate({required bool scheduled}) async {
    final initial = scheduled ? _scheduledDate : (_administeredDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (scheduled) {
        _scheduledDate = picked;
      } else {
        _administeredDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final animalsAsync = ref.watch(animalListProvider);
    final farmsAsync = ref.watch(farmListProvider);
    final isEdit = widget.recordId != null;
    final livestock = animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.vaccineEditTitle : l10n.vaccineAddTitle),
        actions: [
          if (isEdit)
            IconButton(onPressed: _loading ? null : _delete, icon: const Icon(Icons.delete_outline)),
          TextButton(onPressed: _loading ? null : _saveDraft, child: Text(l10n.vaccineSaveDraft)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          farmsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(l10n.vaccineFarmLoadError),
            data: (farms) {
              if (farms.farms.isEmpty) return Text(l10n.vaccineNoFarm);
              return DropdownButtonFormField<String>(
                value: _farmRef ?? farms.farms.first.id,
                decoration: InputDecoration(labelText: l10n.vaccineFarmLabel),
                items: farms.farms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                onChanged: _loading ? null : (v) => setState(() => _farmRef = v),
              );
            },
          ),
          const SizedBox(height: 12),
          animalsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(l10n.vaccineAnimalLoadError),
            data: (_) {
              if (livestock.isEmpty) return Text(l10n.vaccineNoAnimals);
              return DropdownButtonFormField<String>(
                value: _animalId,
                decoration: InputDecoration(labelText: l10n.vaccineAnimalLabel),
                items: livestock.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                onChanged: _loading ? null : (v) => setState(() => _animalId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.vaccineNameLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _typeController,
            decoration: InputDecoration(labelText: l10n.vaccineTypeLabel),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.vaccineScheduledDateLabel),
            subtitle: Text(_scheduledDate.toLocal().toString().split(' ').first),
            trailing: IconButton(
              onPressed: () => _pickDate(scheduled: true),
              icon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.vaccineAdministeredDateLabel),
            subtitle: Text(_administeredDate?.toLocal().toString().split(' ').first ?? l10n.vaccineNotAdministered),
            trailing: IconButton(
              onPressed: () => _pickDate(scheduled: false),
              icon: const Icon(Icons.event_available_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _batchController,
            decoration: InputDecoration(labelText: l10n.vaccineBatchLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.vaccineNotesLabel),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? l10n.vaccineSaveChanges : l10n.vaccineCreateAction),
          ),
        ],
      ),
    );
  }
}
