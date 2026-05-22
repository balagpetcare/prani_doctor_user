import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../batches/presentation/batch_providers.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/feed_dto.dart';
import '../data/feed_repository.dart';
import '../data/feed_validation.dart';
import 'feed_providers.dart';

class FeedEntryFormPage extends ConsumerStatefulWidget {
  const FeedEntryFormPage({super.key, this.recordId});

  final String? recordId;

  @override
  ConsumerState<FeedEntryFormPage> createState() => _FeedEntryFormPageState();
}

class _FeedEntryFormPageState extends ConsumerState<FeedEntryFormPage> {
  final _amountController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  String? _farmRef;
  String? _animalId;
  String? _batchId;
  FeedTarget _target = FeedTarget.animal;
  FeedType _feedType = FeedType.grass;
  FeedUnit _unit = FeedUnit.kg;
  DateTime _recordedDate = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(feedRepositoryProvider);
    final draft = await repo.readDraft(recordId: widget.recordId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.recordId != null) {
      final record = await ref.read(feedRecordProvider(widget.recordId!).future);
      _applyInput(
        FeedInput(
          farmRef: record.farmRef,
          animalId: record.animalId,
          batchId: record.batchId,
          batchName: record.batchName,
          feedType: record.feedType,
          amount: record.amount,
          unit: record.unit,
          costBdt: record.costBdt,
          recordedDate: record.recordedDate,
          notes: record.notes,
          target: record.batchId != null ? FeedTarget.group : FeedTarget.animal,
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

  void _applyInput(FeedInput input) {
    _farmRef = input.farmRef;
    _animalId = input.animalId;
    _batchId = input.batchId;
    _target = input.target;
    _feedType = input.feedType;
    _unit = input.unit;
    _recordedDate = input.recordedDate;
    _amountController.text = input.amount.toString();
    _costController.text = input.costBdt?.toString() ?? '';
    _notesController.text = input.notes ?? '';
  }

  FeedInput _currentInput({String? batchName}) {
    return FeedInput(
      farmRef: _farmRef,
      animalId: _target == FeedTarget.animal ? _animalId : null,
      batchId: _target == FeedTarget.group ? _batchId : null,
      batchName: batchName,
      feedType: _feedType,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      unit: _unit,
      costBdt: double.tryParse(_costController.text.trim()),
      recordedDate: _recordedDate,
      notes: _notesController.text.trim(),
      target: _target,
    );
  }

  Future<void> _saveDraft() async {
    await ref.read(feedRepositoryProvider).saveDraft(_currentInput(), recordId: widget.recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.feedDraftSaved)),
      );
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final targetError = FeedValidation.validateTarget(
      target: _target,
      animalId: _animalId,
      batchId: _batchId,
      message: l10n.feedTargetRequired,
    );
    final amountError = FeedValidation.validateAmount(_amountController.text, message: l10n.feedAmountRequired);
    final costError = FeedValidation.validateCost(_costController.text);
    final dateError = FeedValidation.validateDate(_recordedDate, message: l10n.feedDateInvalid);
    final error = targetError ?? amountError ?? costError ?? dateError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    String? batchName;
    if (_target == FeedTarget.group && _batchId != null) {
      final batches = await ref.read(batchOptionsProvider.future);
      for (final batch in batches) {
        if (batch.id == _batchId) {
          batchName = batch.name;
          break;
        }
      }
    }

    final repo = ref.read(feedRepositoryProvider);
    final input = _currentInput(batchName: batchName);
    final result = widget.recordId == null
        ? await repo.createRecord(input)
        : await repo.updateRecord(widget.recordId!, input);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ref.invalidate(feedListProvider);
        ref.invalidate(feedCostProvider);
        ref.invalidate(feedAnalyticsProvider);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          ref.invalidate(feedListProvider);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.feedOfflineSaved)));
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
        title: Text(l10n.feedDeleteTitle),
        content: Text(l10n.feedDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.feedDeleteAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final result = await ref.read(feedRepositoryProvider).deleteRecord(id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        ref.invalidate(feedListProvider);
        ref.invalidate(feedCostProvider);
        ref.invalidate(feedAnalyticsProvider);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          ref.invalidate(feedListProvider);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.feedOfflineSaved)));
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
    final batchesAsync = ref.watch(batchOptionsProvider);
    final farmsAsync = ref.watch(farmListProvider);
    final isEdit = widget.recordId != null;
    final livestock = animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.feedEditTitle : l10n.feedAddTitle),
        actions: [
          if (isEdit)
            IconButton(onPressed: _loading ? null : _delete, icon: const Icon(Icons.delete_outline)),
          TextButton(onPressed: _loading ? null : _saveDraft, child: Text(l10n.feedSaveDraft)),
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
            error: (_, __) => Text(l10n.feedFarmLoadError),
            data: (state) {
              if (state.farms.isEmpty) return Text(l10n.feedNoFarm);
              return DropdownButtonFormField<String>(
                initialValue: _farmRef ?? state.farms.first.id,
                decoration: InputDecoration(labelText: l10n.feedFarmLabel),
                items: state.farms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                onChanged: _loading ? null : (v) => setState(() => _farmRef = v),
              );
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<FeedTarget>(
            segments: [
              ButtonSegment(value: FeedTarget.animal, label: Text(l10n.feedTargetAnimal)),
              ButtonSegment(value: FeedTarget.group, label: Text(l10n.feedTargetGroup)),
            ],
            selected: {_target},
            onSelectionChanged: _loading ? null : (s) => setState(() => _target = s.first),
          ),
          const SizedBox(height: 12),
          if (_target == FeedTarget.animal)
            animalsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(l10n.feedAnimalLoadError),
              data: (_) {
                if (livestock.isEmpty) return Text(l10n.feedNoAnimals);
                return DropdownButtonFormField<String>(
                  initialValue: _animalId ?? livestock.first.id,
                  decoration: InputDecoration(labelText: l10n.feedAnimalLabel),
                  items: livestock.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: _loading ? null : (v) => setState(() => _animalId = v),
                );
              },
            )
          else
            batchesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(l10n.feedGroupLoadError),
              data: (batches) {
                if (batches.isEmpty) return Text(l10n.feedNoGroups);
                return DropdownButtonFormField<String>(
                  initialValue: _batchId ?? batches.first.id,
                  decoration: InputDecoration(labelText: l10n.feedGroupLabel),
                  items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                  onChanged: _loading ? null : (v) => setState(() => _batchId = v),
                );
              },
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FeedType>(
            initialValue: _feedType,
            decoration: InputDecoration(labelText: l10n.feedTypeLabel),
            items: FeedType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.apiValue))).toList(),
            onChanged: _loading ? null : (v) => setState(() => _feedType = v ?? FeedType.other),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.feedAmountLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<FeedUnit>(
                  initialValue: _unit,
                  decoration: InputDecoration(labelText: l10n.feedUnitLabel),
                  items: FeedUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.apiValue))).toList(),
                  onChanged: _loading ? null : (v) => setState(() => _unit = v ?? FeedUnit.kg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.feedCostLabel),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.feedDateLabel),
            subtitle: Text(_recordedDate.toLocal().toString().split(' ').first),
            trailing: IconButton(onPressed: _loading ? null : _pickDate, icon: const Icon(Icons.calendar_today)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.feedNotesLabel),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? l10n.feedSaveChanges : l10n.feedCreateAction),
          ),
        ],
      ),
    );
  }
}
