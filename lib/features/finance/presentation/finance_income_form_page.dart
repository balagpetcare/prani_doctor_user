import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/finance_dto.dart';
import '../data/finance_repository.dart';
import '../data/finance_validation.dart';
import 'finance_navigation.dart';
import 'finance_providers.dart';
import 'widgets/finance_labels.dart';

class FinanceIncomeFormPage extends ConsumerStatefulWidget {
  const FinanceIncomeFormPage({super.key, this.recordId});

  final String? recordId;

  @override
  ConsumerState<FinanceIncomeFormPage> createState() =>
      _FinanceIncomeFormPageState();
}

class _FinanceIncomeFormPageState extends ConsumerState<FinanceIncomeFormPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _farmRef;
  IncomeSource _source = IncomeSource.milkSales;
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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(financeRepositoryProvider);
    final draft = await repo.readIncomeDraft(recordId: widget.recordId);
    if (draft != null && mounted) {
      _applyInput(draft);
      setState(() {});
      return;
    }
    if (widget.recordId != null) {
      final record = await ref.read(
        financeIncomeRecordProvider(widget.recordId!).future,
      );
      _applyInput(
        IncomeInput(
          farmRef: record.farmRef,
          source: record.source ?? IncomeSource.other,
          amountBdt: record.amountBdt,
          recordedDate: record.recordedDate,
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

  void _applyInput(IncomeInput input) {
    _farmRef = input.farmRef;
    _source = input.source;
    _recordedDate = input.recordedDate;
    _amountController.text = input.amountBdt.toString();
    _notesController.text = input.notes ?? '';
  }

  IncomeInput _currentInput() {
    return IncomeInput(
      farmRef: _farmRef,
      source: _source,
      amountBdt: double.tryParse(_amountController.text.trim()) ?? 0,
      recordedDate: _recordedDate,
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _saveDraft() async {
    await ref
        .read(financeRepositoryProvider)
        .saveIncomeDraft(_currentInput(), recordId: widget.recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.financeDraftSaved),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context)!;
    final amountError = FinanceValidation.validateAmount(
      _amountController.text,
      message: l10n.financeAmountRequired,
    );
    final dateError = FinanceValidation.validateDate(
      _recordedDate,
      message: l10n.financeDateInvalid,
    );
    final error = amountError ?? dateError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(financeRepositoryProvider);
    final input = _currentInput();
    final result = widget.recordId == null
        ? await repo.createIncome(input)
        : await repo.updateIncome(widget.recordId!, input);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (record) {
        FinanceNavigation.afterIncomeSave(ref, recordId: record.id);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          FinanceNavigation.afterIncomeSave(ref, recordId: widget.recordId);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.financeOfflineSaved)));
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
        title: Text(l10n.financeDeleteTitle),
        content: Text(l10n.financeIncomeDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.financeDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final result = await ref.read(financeRepositoryProvider).deleteIncome(id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        FinanceNavigation.afterDelete(ref);
        context.pop();
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          FinanceNavigation.afterDelete(ref);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.financeOfflineSaved)));
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
    final farmsAsync = ref.watch(farmListProvider);
    final isEdit = widget.recordId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? l10n.financeIncomeEditTitle : l10n.financeIncomeAddTitle,
        ),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: _loading ? null : _saveDraft,
            child: Text(l10n.financeSaveDraft),
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
            error: (_, _) => Text(l10n.financeFarmLoadError),
            data: (state) {
              if (state.farms.isEmpty) return Text(l10n.financeNoFarm);
              return DropdownButtonFormField<String>(
                initialValue: _farmRef ?? state.farms.first.id,
                decoration: InputDecoration(labelText: l10n.financeFarmLabel),
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
          DropdownButtonFormField<IncomeSource>(
            initialValue: _source,
            decoration: InputDecoration(labelText: l10n.financeSourceLabel),
            items: IncomeSource.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(incomeSourceLabel(l10n, s)),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (v) => setState(() => _source = v ?? IncomeSource.other),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.financeAmountLabel),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.financeDateLabel),
            subtitle: Text(_recordedDate.toLocal().toString().split(' ').first),
            trailing: IconButton(
              onPressed: _loading ? null : _pickDate,
              icon: const Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.financeNotesLabel),
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
                    isEdit ? l10n.financeSaveChanges : l10n.financeCreateAction,
                  ),
          ),
        ],
      ),
    );
  }
}
