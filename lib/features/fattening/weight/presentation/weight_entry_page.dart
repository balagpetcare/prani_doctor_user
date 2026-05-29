import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/fattening_repository.dart';
import '../../presentation/fattening_providers.dart';
import '../data/weight_dto.dart';

class FatteningWeightEntryPage extends ConsumerStatefulWidget {
  const FatteningWeightEntryPage({
    super.key,
    required this.farmId,
    required this.batchId,
    this.animalId,
  });

  final String farmId;
  final String batchId;
  final String? animalId;

  @override
  ConsumerState<FatteningWeightEntryPage> createState() =>
      _FatteningWeightEntryPageState();
}

class _FatteningWeightEntryPageState
    extends ConsumerState<FatteningWeightEntryPage> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedAnimalId;
  DateTime _recordedAt = DateTime.now();
  WeightRecordMethod _method = WeightRecordMethod.scale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedAnimalId = widget.animalId;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _recordedAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  String _recordedOn() {
    final d = _recordedAt.toUtc();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final animalId = _selectedAnimalId;
    if (animalId == null || animalId.isEmpty) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    setState(() => _saving = true);
    final clientId =
        'weight-${widget.batchId}-$animalId-${_recordedOn()}';
    final result = await ref.read(fatteningRepositoryProvider).createWeightRecord(
      WeightRecordInput(
        animalId: animalId,
        batchId: widget.batchId,
        weightKg: weight,
        recordedAt: _recordedAt,
        recordedOn: _recordedOn(),
        method: _method,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        clientRecordId: clientId,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (record) {
        refreshFatteningAfterMutation(ref, farmId: widget.farmId);
        ref.invalidate(fatteningWeightHistoryProvider(widget.batchId));
        ref.invalidate(fatteningBatchProgressProvider(widget.batchId));
        ref.invalidate(fatteningBatchDetailProvider(widget.batchId));
        ref.invalidate(fatteningQurbaniProvider(widget.batchId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              record.pendingSync
                  ? l10n.fatteningWeightSavedOffline
                  : l10n.fatteningWeightSaved,
            ),
          ),
        );
        context.go(AppRoutes.fatteningBatchProgress(widget.farmId, widget.batchId));
      },
      failure: (e) {
        final msg = e.code == 'DUPLICATE_WEIGHT_DAY'
            ? l10n.fatteningWeightDuplicateDay
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(fatteningBatchDetailProvider(widget.batchId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningWeightEntryTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (detail) {
          final animals = detail.animals;
          if (_selectedAnimalId == null && animals.isNotEmpty) {
            _selectedAnimalId = animals.first.id;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedAnimalId,
                  decoration: InputDecoration(labelText: l10n.selectAnimal),
                  items: animals
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAnimalId = v),
                  validator: (v) =>
                      v == null || v.isEmpty ? l10n.selectAnimal : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: l10n.fatteningWeightKgLabel,
                    suffixText: 'kg',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) {
                      return l10n.fatteningWeightInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.fatteningWeightMethod,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<WeightRecordMethod>(
                  segments: [
                    ButtonSegment(
                      value: WeightRecordMethod.scale,
                      label: Text(l10n.fatteningWeightMethodScale),
                    ),
                    ButtonSegment(
                      value: WeightRecordMethod.tape,
                      label: Text(l10n.fatteningWeightMethodTape),
                    ),
                    ButtonSegment(
                      value: WeightRecordMethod.estimate,
                      label: Text(l10n.fatteningWeightMethodEstimate),
                    ),
                  ],
                  selected: {_method},
                  onSelectionChanged: (s) =>
                      setState(() => _method = s.first),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fatteningRecordedDate),
                  subtitle: Text(_recordedOn()),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(labelText: l10n.fatteningWeightNote),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.fatteningSaveWeight),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
