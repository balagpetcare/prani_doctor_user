import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/milk_dto.dart';
import '../data/milk_repository.dart';
import '../data/milk_validation.dart';
import 'milk_navigation.dart';
import 'milk_providers.dart';

class MilkEntryFormPage extends ConsumerStatefulWidget {
  const MilkEntryFormPage({super.key, this.recordId, this.initialSession});

  final String? recordId;
  final MilkSession? initialSession;

  @override
  ConsumerState<MilkEntryFormPage> createState() => _MilkEntryFormPageState();
}

class _MilkEntryFormPageState extends ConsumerState<MilkEntryFormPage> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  String? _animalId;
  String? _farmRef;
  DateTime _recordedDate = DateTime.now();
  MilkSession _session = MilkSession.morning;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialSession != null) _session = widget.initialSession!;
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(milkRepositoryProvider);
    final draft = await repo.readDraft(recordId: widget.recordId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.recordId != null) {
      final record = await ref.read(
        milkRecordProvider(widget.recordId!).future,
      );
      _applyInput(
        MilkInput(
          animalId: record.animalId,
          farmRef: record.farmRef,
          recordedDate: record.recordedDate,
          session: record.session,
          quantityLiters: record.quantityLiters,
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

  void _applyInput(MilkInput input) {
    _animalId = input.animalId;
    _farmRef = input.farmRef;
    _recordedDate = input.recordedDate;
    _session = input.session;
    _quantityController.text = input.quantityLiters.toString();
    _notesController.text = input.notes ?? '';
  }

  MilkInput _currentInput() {
    return MilkInput(
      animalId: _animalId ?? '',
      farmRef: _farmRef,
      recordedDate: _recordedDate,
      session: _session,
      quantityLiters: double.tryParse(_quantityController.text.trim()) ?? 0,
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _saveDraft() async {
    await ref
        .read(milkRepositoryProvider)
        .saveDraft(_currentInput(), recordId: widget.recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.milkDraftSaved)),
      );
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context)!;
    final animalError = MilkValidation.validateAnimal(
      _animalId,
      message: l10n.milkAnimalRequired,
    );
    final qtyError = MilkValidation.validateQuantity(
      _quantityController.text,
      message: l10n.milkQuantityRequired,
    );
    final dateError = MilkValidation.validateDate(
      _recordedDate,
      message: l10n.milkDateInvalid,
    );
    final error = animalError ?? qtyError ?? dateError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(milkRepositoryProvider);
    final input = _currentInput();
    final result = widget.recordId == null
        ? await repo.createRecord(input)
        : await repo.updateRecord(widget.recordId!, input);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (record) async {
        await MilkNavigation.afterSave(ref, recordId: record.id);
        if (context.mounted) context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          MilkNavigation.afterSave(ref, recordId: widget.recordId);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.milkOfflineSaved)));
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
        title: Text(l10n.milkDeleteTitle),
        content: Text(l10n.milkDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.milkDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final result = await ref.read(milkRepositoryProvider).deleteRecord(id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) async {
        await MilkNavigation.afterDelete(ref);
        if (context.mounted) context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          MilkNavigation.afterDelete(ref);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.milkOfflineSaved)));
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
    final cattle =
        animalsAsync.value?.animals
            .where(
              (a) =>
                  a.active &&
                  (a.animalType == 'CATTLE' || a.category == 'LIVESTOCK'),
            )
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.milkEditTitle : l10n.milkAddTitle),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: _loading ? null : _saveDraft,
            child: Text(l10n.milkSaveDraft),
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
            error: (_, _) => Text(l10n.milkFarmLoadError),
            data: (state) {
              if (state.farms.isEmpty) return Text(l10n.milkNoFarm);
              return DropdownButtonFormField<String>(
                initialValue: _farmRef ?? state.farms.first.id,
                decoration: InputDecoration(labelText: l10n.milkFarmLabel),
                items: state.farms
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
            error: (_, _) => Text(l10n.milkAnimalLoadError),
            data: (_) {
              if (cattle.isEmpty) return Text(l10n.milkNoCattle);
              return DropdownButtonFormField<String>(
                initialValue: _animalId ?? cattle.first.id,
                decoration: InputDecoration(labelText: l10n.milkAnimalLabel),
                items: cattle
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.milkDateLabel),
            subtitle: Text(_recordedDate.toLocal().toString().split(' ').first),
            trailing: IconButton(
              onPressed: _loading ? null : _pickDate,
              icon: const Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<MilkSession>(
            segments: [
              ButtonSegment(
                value: MilkSession.morning,
                label: Text(l10n.milkSessionMorning),
                icon: const Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment(
                value: MilkSession.evening,
                label: Text(l10n.milkSessionEvening),
                icon: const Icon(Icons.nights_stay_outlined),
              ),
            ],
            selected: {_session},
            onSelectionChanged: _loading
                ? null
                : (s) => setState(() => _session = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.milkQuantityLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.milkNotesLabel),
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
                : Text(isEdit ? l10n.milkSaveChanges : l10n.milkCreateAction),
          ),
        ],
      ),
    );
  }
}
