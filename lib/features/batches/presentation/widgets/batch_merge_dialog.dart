import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/batch_dto.dart';
import '../../data/batch_validation.dart';
import '../batch_providers.dart';

Future<BatchMergeInput?> showBatchMergeDialog(
  BuildContext context,
  WidgetRef ref, {
  required String sourceBatchId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final batches = await ref.read(batchOptionsProvider.future);
  final targets = batches.where((b) => b.id != sourceBatchId).toList();

  if (targets.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.batchMergeUnavailable)));
    }
    return null;
  }

  String? targetId = targets.first.id;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.batchMergeAction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.batchMergeHint),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: targetId,
              decoration: InputDecoration(labelText: l10n.batchMergeTarget),
              items: targets
                  .map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => targetId = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.batchMergeConfirm),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || targetId == null) return null;

  final error = BatchValidation.validateMerge(
    sourceId: sourceBatchId,
    targetId: targetId,
    message: l10n.batchMergeInvalid,
  );
  if (error != null) return null;

  return BatchMergeInput(
    sourceBatchId: sourceBatchId,
    targetBatchId: targetId!,
  );
}
