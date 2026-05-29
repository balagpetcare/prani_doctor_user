import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_error_mapper.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../feed/data/feed_dto.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/data/feed_validation.dart';
import 'fattening_providers.dart';

/// Logs feed against a fattening batch (reuses feed API + [FeedRepository]).
class FatteningLogFeedPage extends ConsumerStatefulWidget {
  const FatteningLogFeedPage({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
  });

  final String farmId;
  final String batchId;
  final String? batchName;

  @override
  ConsumerState<FatteningLogFeedPage> createState() =>
      _FatteningLogFeedPageState();
}

class _FatteningLogFeedPageState extends ConsumerState<FatteningLogFeedPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  String? _animalId;
  bool _defaultAnimalScheduled = false;
  FeedType _feedType = FeedType.grass;
  FeedUnit _unit = FeedUnit.kg;
  DateTime _recordedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.tr;
    if (!_formKey.currentState!.validate()) return;
    final animalId = _animalId;
    if (animalId == null) return;

    final amount = double.parse(_amountController.text.trim());
    final cost = _costController.text.trim().isEmpty
        ? null
        : double.tryParse(_costController.text.trim());

    setState(() => _saving = true);
    final result = await ref.read(feedRepositoryProvider).createRecord(
      FeedInput(
        farmRef: widget.farmId,
        animalId: animalId,
        fatteningBatchId: widget.batchId,
        batchId: widget.batchId,
        batchName: widget.batchName,
        feedType: _feedType,
        amount: amount,
        unit: _unit,
        costBdt: cost,
        recordedDate: _recordedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        target: FeedTarget.animal,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        refreshFatteningAfterMutation(ref, farmId: widget.farmId);
        ref.invalidate(fatteningFeedDashboardProvider(widget.batchId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('fatteningFeedLogged'))),
        );
        context.pop();
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
    final l10n = context.tr;
    final detailAsync = ref.watch(fatteningBatchDetailProvider(widget.batchId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningLogFeed)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(UserErrorMapper.message(context, e)),
        ),
        data: (detail) {
          final animals = detail.animals;
          if (!_defaultAnimalScheduled &&
              _animalId == null &&
              animals.isNotEmpty) {
            _defaultAnimalScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _animalId = animals.first.id);
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _animalId,
                  decoration: InputDecoration(labelText: l10n.selectAnimal),
                  items: animals
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _animalId = v),
                  validator: (v) =>
                      v == null || v.isEmpty ? l10n.selectAnimal : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FeedType>(
                  initialValue: _feedType,
                  decoration: InputDecoration(labelText: l10n.feedTypeLabel),
                  items: FeedType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _feedType = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: l10n.feedAmountLabel,
                          suffixText: _unit.apiValue.toLowerCase(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => FeedValidation.validateAmount(
                          v,
                          message: l10n.feedAmountRequired,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<FeedUnit>(
                        initialValue: _unit,
                        decoration: InputDecoration(labelText: l10n.feedUnitLabel),
                        items: FeedUnit.values
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.apiValue),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _unit = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: l10n.feedCostLabel,
                    prefixText: '৳ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.feedNotesLabel),
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
                      : Text(l10n.fatteningSaveFeed),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
