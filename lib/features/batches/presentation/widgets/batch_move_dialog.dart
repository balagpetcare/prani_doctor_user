import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/batch_dto.dart';
import '../../data/batch_validation.dart';
import '../batch_providers.dart';

Future<BatchMoveInput?> showBatchMoveDialog(
  BuildContext context,
  WidgetRef ref, {
  required String fromBatchId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final detail = await ref.read(batchDetailProvider(fromBatchId).future);
  final batches = await ref.read(batchOptionsProvider.future);
  final targets = batches.where((b) => b.id != fromBatchId).toList();

  if (targets.isEmpty || detail.animals.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.batchMoveUnavailable)),
      );
    }
    return null;
  }

  String? targetId = targets.first.id;
  final selectedIds = <String>{if (detail.animals.isNotEmpty) detail.animals.first.id};
  final notesController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.batchMoveAction),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: targetId,
                decoration: InputDecoration(labelText: l10n.batchMoveTarget),
                items: targets
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() => targetId = v),
              ),
              const SizedBox(height: 12),
              ...detail.animals.map(
                (animal) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selectedIds.contains(animal.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedIds.add(animal.id);
                      } else {
                        selectedIds.remove(animal.id);
                      }
                    });
                  },
                  title: Text(animal.label),
                ),
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l10n.batchNotesLabel),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.batchMoveConfirm)),
        ],
      ),
    ),
  );

  if (result != true || targetId == null) {
    notesController.dispose();
    return null;
  }

  final notes = notesController.text.trim();
  notesController.dispose();

  final error = BatchValidation.validateMove(
    fromBatchId: fromBatchId,
    toBatchId: targetId,
    animalIds: selectedIds.toList(),
    message: l10n.batchMoveInvalid,
  );
  if (error != null) return null;

  return BatchMoveInput(
    fromBatchId: fromBatchId,
    toBatchId: targetId!,
    animalIds: selectedIds.toList(),
    notes: notes,
  );
}
