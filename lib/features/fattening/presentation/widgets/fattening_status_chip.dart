import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_status_chip.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/fattening_batch_dto.dart';

class FatteningStatusChip extends StatelessWidget {
  const FatteningStatusChip({super.key, required this.status});

  final FatteningBatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      FatteningBatchStatus.draft => ('Draft', StatusTone.muted),
      FatteningBatchStatus.active => ('Active', StatusTone.positive),
      FatteningBatchStatus.completed => ('Completed', StatusTone.info),
      FatteningBatchStatus.archived => ('Archived', StatusTone.neutral),
    };
    return AppStatusChip(label: label, tone: tone);
  }
}
