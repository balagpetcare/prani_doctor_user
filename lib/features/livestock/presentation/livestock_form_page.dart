import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../../animals/presentation/widgets/animal_image_upload.dart';
import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import '../data/livestock_dto.dart';
import '../data/livestock_repository.dart';
import '../data/livestock_validation.dart';
import 'livestock_providers.dart';

class LivestockFormPage extends ConsumerStatefulWidget {
  const LivestockFormPage({super.key, this.livestockId});

  final String? livestockId;

  @override
  ConsumerState<LivestockFormPage> createState() => _LivestockFormPageState();
}

class _LivestockFormPageState extends ConsumerState<LivestockFormPage> {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _weightController = TextEditingController();
  final _breedController = TextEditingController();
  final _notesController = TextEditingController();

  String _species = 'COW';
  String _gender = 'FEMALE';
  String _purpose = 'MIXED';
  String? _photoUrl;
  bool _loading = false;
  bool _bootstrapped = false;

  static const _speciesOptions = ['COW', 'GOAT', 'SHEEP', 'BUFFALO', 'OTHER'];
  static const _genderOptions = ['MALE', 'FEMALE'];
  static const _purposeOptions = ['DAIRY', 'MEAT', 'MIXED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    final repo = ref.read(livestockRepositoryProvider);
    final draft = await repo.readDraft(livestockId: widget.livestockId);
    if (!mounted) return;
    if (draft != null) {
      _applyInput(draft);
    } else if (widget.livestockId != null) {
      final profile = await ref.read(
        livestockDetailProvider(widget.livestockId!).future,
      );
      if (!mounted) return;
      _applyInput(
        LivestockInput(
          farmRef: profile.farmRef,
          name: profile.name,
          species: profile.species,
          gender: profile.gender,
          purpose: profile.purpose,
          breedName: profile.breedName,
          weightKg: profile.weightKg,
          earTagNumber: profile.earTagNumber,
          notes: profile.notes,
          photoUrl: profile.photoUrl,
        ),
      );
    }
    setState(() => _bootstrapped = true);
  }

  void _applyInput(LivestockInput input) {
    _nameController.text = input.name;
    _tagController.text = input.earTagNumber ?? '';
    _weightController.text =
        input.weightKg != null ? input.weightKg!.toStringAsFixed(1) : '';
    _breedController.text = input.breedName ?? '';
    _notesController.text = input.notes ?? '';
    _species = input.species;
    _gender = input.gender;
    _purpose = input.purpose;
    _photoUrl = input.photoUrl;
  }

  LivestockInput _buildInput(String farmRef) {
    return LivestockInput(
      farmRef: farmRef,
      name: _nameController.text,
      species: _species,
      gender: _gender,
      purpose: _purpose,
      breedName: _breedController.text.trim().isEmpty
          ? null
          : _breedController.text.trim(),
      weightKg: double.tryParse(_weightController.text.trim()),
      earTagNumber: _tagController.text.trim().isEmpty
          ? null
          : _tagController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      photoUrl: _photoUrl,
    );
  }

  Future<void> _saveDraft() async {
    final farmRef = ref.read(activeFarmRefProvider);
    if (farmRef == null) return;
    await ref
        .read(livestockRepositoryProvider)
        .saveDraft(_buildInput(farmRef), livestockId: widget.livestockId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.t(TranslationKeys.livestockDraftSaved))),
    );
  }

  Future<void> _submit() async {
    final l10n = context.tr;
    final farmRef = ref.read(activeFarmRefProvider);
    if (farmRef == null || farmRef.isEmpty) return;

    final input = _buildInput(farmRef);
    if (!LivestockValidation.isValid(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t(TranslationKeys.livestockFormInvalid))),
      );
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(livestockRepositoryProvider);
    final result = widget.livestockId == null
        ? await repo.createLivestock(input)
        : await repo.updateLivestock(widget.livestockId!, input);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (profile) {
        ref.invalidate(livestockListProvider);
        if (widget.livestockId != null) {
          ref.invalidate(livestockDetailProvider(widget.livestockId!));
        }
        context.go(AppRoutes.livestockDetail(profile.id));
      },
      failure: (e) {
        final msg = e.code == offlineQueuedCode
            ? l10n.t(TranslationKeys.livestockOfflineSaved)
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (e.code == offlineQueuedCode) context.pop();
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final isEdit = widget.livestockId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t(
            isEdit
                ? TranslationKeys.livestockEditTitle
                : TranslationKeys.livestockAddTitle,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveDraft,
            child: Text(l10n.t(TranslationKeys.livestockSaveDraft)),
          ),
        ],
      ),
      body: !_bootstrapped
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AnimalImageUpload(
                  currentUrl: _photoUrl,
                  onUploaded: (url) => setState(() => _photoUrl = url),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockNameLabel),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _species,
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockSpeciesLabel),
                  ),
                  items: _speciesOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _species = v ?? _species),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockGenderLabel),
                  ),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _purpose,
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockPurposeLabel),
                  ),
                  items: _purposeOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _purpose = v ?? _purpose),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockBreedLabel),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockWeightLabel),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockEarTagLabel),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.t(TranslationKeys.livestockNotesLabel),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.t(TranslationKeys.livestockSave)),
                ),
              ],
            ),
    );
  }
}
