import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../core/offline/network_errors.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/health_dto.dart';
import '../data/health_repository.dart';
import '../data/health_validation.dart';
import 'health_navigation.dart';
import 'health_providers.dart';
import 'widgets/health_labels.dart';

class HealthFormPage extends ConsumerStatefulWidget {
  const HealthFormPage({super.key, this.recordId});

  final String? recordId;

  @override
  ConsumerState<HealthFormPage> createState() => _HealthFormPageState();
}

class _HealthFormPageState extends ConsumerState<HealthFormPage> {
  final _titleController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _diseaseController = TextEditingController();
  final _notesController = TextEditingController();

  String? _farmRef;
  String? _animalId;
  HealthEventType _eventType = HealthEventType.symptom;
  DateTime _recordedDate = DateTime.now();
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
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _diseaseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(healthRepositoryProvider);
    final draft = await repo.readDraft(recordId: widget.recordId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.recordId != null) {
      final record = await ref.read(
        healthRecordProvider(widget.recordId!).future,
      );
      _applyInput(
        HealthInput(
          farmRef: record.farmRef,
          animalId: record.animalId,
          eventType: record.eventType,
          title: record.title,
          symptoms: record.symptoms,
          diagnosis: record.diagnosis,
          diseaseName: record.diseaseName,
          treatmentRefId: record.treatmentRefId,
          vaccineRefId: record.vaccineRefId,
          notes: record.notes,
          recordedDate: record.recordedDate,
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

  void _applyInput(HealthInput input) {
    _farmRef = input.farmRef;
    _animalId = input.animalId;
    _eventType = input.eventType;
    _recordedDate = input.recordedDate;
    _titleController.text = input.title;
    _symptomsController.text = input.symptoms ?? '';
    _diagnosisController.text = input.diagnosis ?? '';
    _diseaseController.text = input.diseaseName ?? '';
    _notesController.text = input.notes ?? '';
  }

  HealthInput _currentInput() {
    return HealthInput(
      farmRef: _farmRef,
      animalId: _animalId,
      eventType: _eventType,
      title: _titleController.text.trim(),
      symptoms: _symptomsController.text.trim(),
      diagnosis: _diagnosisController.text.trim(),
      diseaseName: _diseaseController.text.trim(),
      notes: _notesController.text.trim(),
      recordedDate: _recordedDate,
    );
  }

  Future<void> _saveDraft() async {
    await ref
        .read(healthRepositoryProvider)
        .saveDraft(_currentInput(), recordId: widget.recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.healthDraftSaved)),
      );
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final titleError = HealthValidation.validateTitle(
      _titleController.text,
      message: l10n.healthTitleRequired,
    );
    final animalError = HealthValidation.validateAnimal(
      _animalId,
      message: l10n.healthAnimalRequired,
    );
    final dateError = HealthValidation.validateDate(
      _recordedDate,
      message: l10n.healthDateInvalid,
    );
    final error = titleError ?? animalError ?? dateError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _loading = true;
      _submitting = true;
      _error = null;
    });

    final repo = ref.read(healthRepositoryProvider);
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
      success: (_) {
        HealthNavigation.afterSave(ref, recordId: widget.recordId);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          HealthNavigation.afterSave(ref, recordId: widget.recordId);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.healthOfflineSaved)));
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
        title: Text(l10n.healthDeleteTitle),
        content: Text(l10n.healthDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.healthDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final result = await ref.read(healthRepositoryProvider).deleteRecord(id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        HealthNavigation.afterDelete(ref);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          HealthNavigation.afterDelete(ref);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.healthOfflineSaved)));
          return;
        }
        setState(() => _error = e.message);
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _recordedDate = picked);
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
      appBar: safeAppBar(
        context,
        title: Text(isEdit ? l10n.healthEditTitle : l10n.healthAddTitle),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: _loading ? null : _saveDraft,
            child: Text(l10n.healthSaveDraft),
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
            error: (_, _) => Text(l10n.healthFarmLoadError),
            data: (farms) {
              if (farms.farms.isEmpty) return Text(l10n.healthNoFarm);
              return DropdownButtonFormField<String>(
                initialValue: _farmRef ?? farms.farms.first.id,
                decoration: InputDecoration(labelText: l10n.healthFarmLabel),
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
            error: (_, _) => Text(l10n.healthAnimalLoadError),
            data: (_) {
              if (livestock.isEmpty) return Text(l10n.healthNoAnimals);
              return DropdownButtonFormField<String>(
                initialValue: _animalId,
                decoration: InputDecoration(labelText: l10n.healthAnimalLabel),
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
          DropdownButtonFormField<HealthEventType>(
            initialValue: _eventType,
            decoration: InputDecoration(labelText: l10n.healthTypeLabel),
            items: HealthEventType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(healthEventTypeLabel(l10n, t)),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (v) =>
                      setState(() => _eventType = v ?? HealthEventType.symptom),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.healthTitleLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _symptomsController,
            decoration: InputDecoration(labelText: l10n.healthSymptomsLabel),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _diagnosisController,
            decoration: InputDecoration(labelText: l10n.healthDiagnosisLabel),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _diseaseController,
            decoration: InputDecoration(labelText: l10n.healthDiseaseLabel),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.healthDateLabel),
            subtitle: Text(_recordedDate.toLocal().toString().split(' ').first),
            trailing: IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.healthNotesLabel),
            maxLines: 3,
          ),
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
                    isEdit ? l10n.healthSaveChanges : l10n.healthCreateAction,
                  ),
          ),
        ],
      ),
    );
  }
}
