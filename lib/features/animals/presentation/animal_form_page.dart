import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/animal_dto.dart';
import '../data/animal_repository.dart';
import '../data/animal_validation.dart';
import 'animal_providers.dart';
import 'widgets/animal_image_upload.dart';

class AnimalFormPage extends ConsumerStatefulWidget {
  const AnimalFormPage({super.key, this.animalId});

  final String? animalId;

  @override
  ConsumerState<AnimalFormPage> createState() => _AnimalFormPageState();
}

class _AnimalFormPageState extends ConsumerState<AnimalFormPage> {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  String _animalType = 'GOAT';
  String? _gender;
  String? _photoUrl;
  bool _loading = false;
  String? _error;

  static const _types = ['CATTLE', 'GOAT', 'POULTRY', 'DOG', 'CAT', 'OTHER'];
  static const _genders = ['MALE', 'FEMALE', 'UNKNOWN'];

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(animalRepositoryProvider);
    final draft = await repo.readDraft(animalId: widget.animalId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.animalId != null) {
      final detail = await ref.read(animalDetailProvider(widget.animalId!).future);
      _applyInput(
        AnimalInput(
          animalType: detail.animal.animalType ?? 'OTHER',
          name: detail.animal.name,
          tag: detail.animal.microchipOrTag,
          breed: detail.animal.breed,
          ageYears: detail.animal.ageYears,
          gender: detail.animal.gender,
          notes: detail.animal.notes,
          photoUrl: detail.animal.photoUrl,
          weightKg: double.tryParse(detail.animal.weightKg ?? ''),
        ),
      );
      if (mounted) setState(() {});
    }
  }

  void _applyInput(AnimalInput input) {
    _animalType = input.animalType;
    _nameController.text = input.name ?? '';
    _tagController.text = input.tag ?? '';
    _breedController.text = input.breed ?? '';
    _weightController.text = input.weightKg?.toString() ?? '';
    _ageController.text = input.ageYears?.toString() ?? '';
    _notesController.text = input.notes ?? '';
    _gender = input.gender;
    _photoUrl = input.photoUrl;
  }

  AnimalInput _currentInput() {
    return AnimalInput(
      animalType: _animalType,
      name: _nameController.text.trim(),
      tag: _tagController.text.trim(),
      breed: _breedController.text.trim(),
      ageYears: int.tryParse(_ageController.text.trim()),
      gender: _gender,
      notes: _notesController.text.trim(),
      photoUrl: _photoUrl,
      weightKg: double.tryParse(_weightController.text.trim()),
    );
  }

  Future<void> _saveDraft() async {
    await ref.read(animalRepositoryProvider).saveDraft(
          _currentInput(),
          animalId: widget.animalId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.animalDraftSaved)),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final validation = AnimalValidation.validateNameOrTag(
      name: _nameController.text,
      tag: _tagController.text,
      message: l10n.animalNameOrTagRequired,
    );
    final weightError = AnimalValidation.validateWeight(_weightController.text);
    final ageError = AnimalValidation.validateAgeYears(_ageController.text);
    final error = validation ?? weightError ?? ageError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final input = _currentInput();
    final repo = ref.read(animalRepositoryProvider);
    final result = widget.animalId == null
        ? await repo.createAnimal(input)
        : await repo.updateAnimal(widget.animalId!, input);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (animal) {
        ref.invalidate(animalListProvider);
        ref.invalidate(animalDetailProvider(animal.id));
        context.go(AppRoutes.animalDetail(animal.id));
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.savedOffline)));
          context.pop();
          return;
        }
        setState(() => _error = e.message);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.animalId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.animalEditTitle : l10n.animalAddTitle),
        actions: [
          TextButton(onPressed: _loading ? null : _saveDraft, child: Text(l10n.animalSaveDraft)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            AnimalImageUpload(
              currentUrl: _photoUrl,
              onUploaded: (url) => setState(() => _photoUrl = url),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _animalType,
              decoration: InputDecoration(labelText: l10n.animalTypeLabel),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: _loading ? null : (v) => setState(() => _animalType = v ?? _animalType),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.nameLabel),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagController,
              decoration: InputDecoration(labelText: l10n.animalTagLabel),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _breedController,
              decoration: InputDecoration(labelText: l10n.animalBreedLabel),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(labelText: l10n.animalWeightLabel),
              keyboardType: TextInputType.number,
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: l10n.animalAgeLabel),
              keyboardType: TextInputType.number,
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: l10n.animalGenderLabel),
              items: [
                DropdownMenuItem<String>(child: Text(l10n.animalGenderUnknown)),
                ..._genders.map((g) => DropdownMenuItem(value: g, child: Text(g))),
              ],
              onChanged: _loading ? null : (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.animalNotesLabel),
              maxLines: 3,
              enabled: !_loading,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? l10n.saveProfile : l10n.animalAddTitle),
            ),
          ],
        ),
      ),
    );
  }
}
