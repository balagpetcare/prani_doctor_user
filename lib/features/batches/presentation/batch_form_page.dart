import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../data/batch_dto.dart';
import '../data/batch_repository.dart';
import '../data/batch_validation.dart';
import 'batch_providers.dart';

class BatchFormPage extends ConsumerStatefulWidget {
  const BatchFormPage({super.key, this.batchId});

  final String? batchId;

  @override
  ConsumerState<BatchFormPage> createState() => _BatchFormPageState();
}

class _BatchFormPageState extends ConsumerState<BatchFormPage> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  String _animalType = 'GOAT';
  final Set<String> _selectedAnimalIds = {};
  bool _loading = false;
  String? _error;

  static const _types = ['CATTLE', 'GOAT', 'POULTRY', 'DOG', 'CAT', 'OTHER'];

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(batchRepositoryProvider);
    final draft = await repo.readDraft(batchId: widget.batchId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.batchId != null) {
      final detail = await ref.read(batchDetailProvider(widget.batchId!).future);
      _applyInput(
        BatchInput(
          name: detail.batch.name,
          notes: detail.batch.notes,
          animalType: detail.batch.animalType,
          location: detail.batch.location,
          animalIds: detail.batch.animalIds,
        ),
      );
      _selectedAnimalIds.addAll(detail.batch.animalIds);
      if (mounted) setState(() {});
    }
  }

  void _applyInput(BatchInput input) {
    _nameController.text = input.name;
    _notesController.text = input.notes ?? '';
    _locationController.text = input.location ?? '';
    _animalType = input.animalType ?? 'OTHER';
    _selectedAnimalIds
      ..clear()
      ..addAll(input.animalIds);
  }

  BatchInput _currentInput() {
    return BatchInput(
      name: _nameController.text.trim(),
      notes: _notesController.text.trim(),
      animalType: _animalType,
      location: _locationController.text.trim(),
      animalIds: _selectedAnimalIds.toList(),
    );
  }

  Future<void> _saveDraft() async {
    await ref.read(batchRepositoryProvider).saveDraft(_currentInput(), batchId: widget.batchId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.batchDraftSaved)),
      );
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final nameError = BatchValidation.validateName(_nameController.text, message: l10n.batchNameRequired);
    if (nameError != null) {
      setState(() => _error = nameError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(batchRepositoryProvider);
    final input = _currentInput();
    final result = widget.batchId == null
        ? await repo.createBatch(input)
        : await repo.updateBatch(widget.batchId!, input);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (batch) {
        ref.invalidate(batchListProvider);
        context.go(AppRoutes.batchDetail(batch.id));
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          ref.invalidate(batchListProvider);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.batchOfflineSaved)));
          return;
        }
        setState(() => _error = e.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final animalsAsync = ref.watch(animalListProvider);
    final isEdit = widget.batchId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.batchEditTitle : l10n.batchAddTitle),
        actions: [
          TextButton(onPressed: _loading ? null : _saveDraft, child: Text(l10n.batchSaveDraft)),
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
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.batchNameLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _animalType,
            decoration: InputDecoration(labelText: l10n.batchTypeLabel),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: _loading ? null : (v) => setState(() => _animalType = v ?? 'OTHER'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: l10n.batchLocationLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.batchNotesLabel),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text(l10n.batchSelectAnimals, style: Theme.of(context).textTheme.titleMedium),
          animalsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(l10n.batchAnimalsLoadError),
            data: (state) {
              if (state.animals.isEmpty) return Text(l10n.batchNoAnimals);
              return Column(
                children: state.animals.map((animal) {
                  return CheckboxListTile(
                    value: _selectedAnimalIds.contains(animal.id),
                    onChanged: _loading
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedAnimalIds.add(animal.id);
                              } else {
                                _selectedAnimalIds.remove(animal.id);
                              }
                            });
                          },
                    title: Text(animal.name),
                    subtitle: Text(animal.animalType ?? animal.species),
                  );
                }).toList(),
              );
            },
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
                : Text(isEdit ? l10n.batchSaveChanges : l10n.batchCreateAction),
          ),
        ],
      ),
    );
  }
}
