import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/fattening_batch_dto.dart';
import '../data/fattening_repository.dart';
import '../data/fattening_validation.dart';
import 'fattening_providers.dart';

class FatteningCreateBatchPage extends ConsumerStatefulWidget {
  const FatteningCreateBatchPage({super.key, required this.farmId});

  final String farmId;

  @override
  ConsumerState<FatteningCreateBatchPage> createState() =>
      _FatteningCreateBatchPageState();
}

class _FatteningCreateBatchPageState
    extends ConsumerState<FatteningCreateBatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  FatteningBatchGoalType _goalType = FatteningBatchGoalType.normal;
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_goalType.isQurbani && _targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fatteningQurbaniTargetRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    final input = FatteningBatchInput(
      farmId: widget.farmId,
      name: _nameController.text.trim(),
      goalType: _goalType,
      goal: _goalController.text.trim().isEmpty
          ? null
          : _goalController.text.trim(),
      targetDate: _targetDate,
    );
    final result = await ref
        .read(fatteningRepositoryProvider)
        .createBatch(input);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (batch) {
        refreshFatteningAfterMutation(
          ref,
          farmId: widget.farmId,
          batchId: batch.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              batch.pendingSync
                  ? 'Batch saved offline — will sync when online'
                  : 'Batch created',
            ),
          ),
        );
        context.go(AppRoutes.fatteningAddAnimals(widget.farmId, batch.id));
      },
      failure: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningCreateBatch)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.fatteningBatchName),
              validator: (v) => FatteningValidation.validateName(v),
            ),
            const SizedBox(height: 16),
            Text(l10n.fatteningBatchGoalType, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<FatteningBatchGoalType>(
              segments: [
                ButtonSegment(
                  value: FatteningBatchGoalType.normal,
                  label: Text(l10n.fatteningGoalTypeNormal),
                ),
                ButtonSegment(
                  value: FatteningBatchGoalType.qurbani,
                  label: Text(l10n.fatteningGoalTypeQurbani),
                ),
              ],
              selected: {_goalType},
              onSelectionChanged: (selected) {
                setState(() {
                  _goalType = selected.first;
                  if (_goalType.isQurbani &&
                      _nameController.text.trim().isEmpty) {
                    final year = DateTime.now().year;
                    _nameController.text = 'Qurbani $year';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goalController,
              decoration: InputDecoration(labelText: l10n.fatteningBatchGoal),
              maxLines: 2,
              validator: (v) => FatteningValidation.validateGoal(v),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fatteningTargetDate),
              subtitle: Text(
                _targetDate == null
                    ? l10n.fatteningTargetDateOptional
                    : '${_targetDate!.year}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _pickTargetDate,
              ),
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
                  : Text(l10n.fatteningSaveAndAddAnimals),
            ),
          ],
        ),
      ),
    );
  }
}
