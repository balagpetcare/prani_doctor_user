import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/support_dto.dart';
import 'support_ticket_card.dart';

class SupportStatusBadge extends StatelessWidget {
  const SupportStatusBadge({super.key, required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, _) = _style(status);
    return Chip(
      label: Text(
        supportStatusLabel(l10n, status),
        style: TextStyle(color: color, fontSize: 11),
      ),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  (Color, Color) _style(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return (Colors.blue, Colors.blue.shade50);
      case SupportTicketStatus.inProgress:
        return (Colors.orange, Colors.orange.shade50);
      case SupportTicketStatus.waitingCustomer:
        return (Colors.amber.shade800, Colors.amber.shade50);
      case SupportTicketStatus.resolved:
        return (Colors.green, Colors.green.shade50);
      case SupportTicketStatus.closed:
        return (Colors.grey, Colors.grey.shade200);
    }
  }
}
