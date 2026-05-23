import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/animal_dto.dart';
import '../data/animal_repository.dart';
import '../data/animal_validation.dart';
import 'animal_navigation.dart';
import 'animal_providers.dart';
import 'widgets/animal_image_upload.dart';
import 'widgets/breed_search_field.dart';

class AnimalFormPage extends ConsumerStatefulWidget {
  const AnimalFormPage({super.key, this.animalId});

  final String? animalId;

  @override
  ConsumerState<AnimalFormPage> createState() => _AnimalFormPageState();
}

class _AnimalFormPageState extends ConsumerState<AnimalFormPage> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  String _animalType = 'GOAT';
  String? _breed;
  String? _gender;
  String? _photoUrl;
  int _step = 0;
  bool _loading = false;
  bool _isSubmitting = false;
  bool _bootstrapped = false;
  bool _userEdited = false;
  String? _error;

  static const _types = ['CATTLE', 'GOAT', 'POULTRY', 'DOG', 'CAT', 'OTHER'];
  static const _genders = ['MALE', 'FEMALE'];
  static const _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    final repo = ref.read(animalRepositoryProvider);
    try {
      final draft = await repo.readDraft(animalId: widget.animalId);
      if (!mounted || _userEdited) return;
      if (draft != null) {
        _applyInput(draft);
        setState(() => _bootstrapped = true);
        return;
      }
      if (widget.animalId != null) {
        final detail = await ref.read(
          animalDetailProvider(widget.animalId!).future,
        );
        if (!mounted || _userEdited) return;
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
      }
      if (mounted) setState(() => _bootstrapped = true);
    } catch (_) {
      if (mounted) setState(() => _bootstrapped = true);
    }
  }

  void _markEdited() {
    _userEdited = true;
  }

  void _applyInput(AnimalInput input) {
    _animalType = input.animalType;
    _nameController.text = input.name ?? '';
    _tagController.text = input.tag ?? '';
    _breed = input.breed;
    _weightController.text = input.weightKg?.toString() ?? '';
    _ageController.text = input.ageYears?.toString() ?? '';
    _notesController.text = input.notes ?? '';
    _gender = input.gender == 'UNKNOWN' ? null : input.gender;
    _photoUrl = input.photoUrl;
  }

  AnimalInput _currentInput() {
    return AnimalInput(
      animalType: _animalType,
      name: _nameController.text.trim(),
      tag: _tagController.text.trim(),
      breed: _breed,
      ageYears: int.tryParse(_ageController.text.trim()),
      gender: _gender,
      notes: _notesController.text.trim(),
      photoUrl: _photoUrl,
      weightKg: double.tryParse(_weightController.text.trim()),
    );
  }

  Future<void> _autosaveDraft() async {
    await ref
        .read(animalRepositoryProvider)
        .saveDraft(_currentInput(), animalId: widget.animalId);
  }

  Future<void> _goToStep(int step) async {
    if (step < 0 || step >= _totalSteps || step == _step) return;
    setState(() => _step = step);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
  }

  Future<void> _nextStep() async {
    await _autosaveDraft();
    if (!mounted || _step >= _totalSteps - 1) return;
    setState(() => _step++);
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
  }

  Future<void> _prevStep() async {
    if (_step <= 0) return;
    setState(() => _step--);
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_isSubmitting || _loading) return;

    final l10n = AppLocalizations.of(context)!;
    final validation = AnimalValidation.validateNameOrTag(
      name: _nameController.text,
      tag: _tagController.text,
      message: l10n.animalNameOrTagRequired,
    );
    final weightError = AnimalValidation.validateWeight(
      _weightController.text,
      invalidMessage: l10n.animalWeightInvalid,
    );
    final ageError = AnimalValidation.validateAgeYears(
      _ageController.text,
      invalidMessage: l10n.animalAgeInvalid,
    );
    final error = validation ?? weightError ?? ageError;
    if (error != null) {
      setState(() => _error = error);
      _showError(error);
      if (_step != 0 && validation != null) {
        await _goToStep(0);
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loading = true;
      _error = null;
    });

    try {
      await _autosaveDraft();
      final input = _currentInput();
      final repo = ref.read(animalRepositoryProvider);
      final result = widget.animalId == null
          ? await repo.createAnimal(input)
          : await repo.updateAnimal(widget.animalId!, input);

      if (!mounted) return;

      await result.when(
        success: (animal) async {
          await AnimalNavigation.afterSave(ref, animal);
          if (!mounted) return;
          context.go(AppRoutes.animalDetail(animal.id));
        },
        failure: (e) async {
          if (e.code == offlineQueuedCode) {
            try {
              await AnimalNavigation.refreshList(ref);
            } catch (_) {}
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.savedOffline)),
            );
            context.pop();
            return;
          }
          setState(() => _error = e.message);
          _showError(e.message);
        },
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      setState(() => _error = message);
      _showError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _tagController.dispose();
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
      appBar: safeAppBar(
        context,
        title: Text(isEdit ? l10n.animalEditTitle : l10n.animalAddTitle),
        actions: [
          TextButton(
            onPressed: _loading ? null : _autosaveDraft,
            child: Text(l10n.animalSaveDraft),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.animalFormStepOf(_step + 1, _totalSteps),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_step + 1) / _totalSteps,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _errorBanner(),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _step = index),
              children: [
                _stepBasics(l10n),
                _stepDetails(l10n),
                _stepMetrics(l10n),
                _stepNotes(l10n),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: _loading ? null : _prevStep,
                    child: Text(l10n.animalFormBack),
                  ),
                const Spacer(),
                if (_step < _totalSteps - 1)
                  FilledButton(
                    onPressed: _loading ? null : _nextStep,
                    child: Text(l10n.animalFormNext),
                  )
                else
                  FilledButton(
                    onPressed: _isSubmitting ? null : _save,
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
        ],
      ),
    );
  }

  Widget _errorBanner() {
    if (_error == null) return const SizedBox.shrink();

    return Text(
      _error!,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }

  Widget _stepBasics(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.animalFormStepBasics,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          AnimalImageUpload(
            currentUrl: _photoUrl,
            onUploaded: (url) {
              _markEdited();
              setState(() => _photoUrl = url);
              _autosaveDraft();
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _animalType,
            decoration: InputDecoration(labelText: l10n.animalTypeLabel),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: _loading
                ? null
                : (v) {
                    _markEdited();
                    setState(() {
                      _animalType = v ?? _animalType;
                      _breed = null;
                    });
                    _autosaveDraft();
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.nameLabel),
            enabled: !_loading,
            onChanged: (_) {
              _markEdited();
              _autosaveDraft();
            },
          ),
        ],
      ),
    );
  }

  Widget _stepDetails(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.animalFormStepDetails,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagController,
            decoration: InputDecoration(labelText: l10n.animalTagLabel),
            enabled: !_loading,
            onChanged: (_) {
              _markEdited();
              _autosaveDraft();
            },
          ),
          const SizedBox(height: 12),
          BreedSearchField(
            animalType: _animalType,
            value: _breed,
            enabled: !_loading,
            onChanged: (v) {
              _markEdited();
              setState(() => _breed = v);
              _autosaveDraft();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: InputDecoration(labelText: l10n.animalGenderLabel),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(l10n.animalGenderUnknown),
              ),
              ..._genders.map(
                (g) => DropdownMenuItem(value: g, child: Text(g)),
              ),
            ],
            onChanged: _loading
                ? null
                : (v) {
                    _markEdited();
                    setState(() => _gender = v);
                    _autosaveDraft();
                  },
          ),
        ],
      ),
    );
  }

  Widget _stepMetrics(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.animalFormStepMetrics,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            decoration: InputDecoration(labelText: l10n.animalWeightLabel),
            keyboardType: TextInputType.number,
            enabled: !_loading,
            onChanged: (_) {
              _markEdited();
              _autosaveDraft();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageController,
            decoration: InputDecoration(labelText: l10n.animalAgeLabel),
            keyboardType: TextInputType.number,
            enabled: !_loading,
            onChanged: (_) {
              _markEdited();
              _autosaveDraft();
            },
          ),
        ],
      ),
    );
  }

  Widget _stepNotes(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.animalFormStepNotes,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.animalNotesLabel),
            maxLines: 5,
            enabled: !_loading,
            onChanged: (_) {
              _markEdited();
              _autosaveDraft();
            },
          ),
        ],
      ),
    );
  }
}
