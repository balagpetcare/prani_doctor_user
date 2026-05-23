import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/support_dto.dart';
import 'support_status_badge.dart';

class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final SupportTicketSummary ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SupportStatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                supportCategoryLabel(l10n, ticket.category),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (ticket.lastMessagePreview != null) ...[
                const SizedBox(height: 8),
                Text(
                  ticket.lastMessagePreview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(supportPriorityLabel(l10n, ticket.priority)),
                  const Spacer(),
                  if (ticket.pendingSync)
                    Chip(
                      label: Text(
                        l10n.supportPendingSync,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (ticket.attachmentCount > 0) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                    Text('${ticket.attachmentCount}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String supportCategoryLabel(
  AppLocalizations l10n,
  SupportTicketCategory category,
) {
  switch (category) {
    case SupportTicketCategory.account:
      return l10n.supportCategoryAccount;
    case SupportTicketCategory.billing:
      return l10n.supportCategoryBilling;
    case SupportTicketCategory.technical:
      return l10n.supportCategoryTechnical;
    case SupportTicketCategory.animalHealth:
      return l10n.supportCategoryAnimalHealth;
    case SupportTicketCategory.appUsage:
      return l10n.supportCategoryAppUsage;
    case SupportTicketCategory.other:
      return l10n.supportCategoryOther;
  }
}

String supportPriorityLabel(
  AppLocalizations l10n,
  SupportTicketPriority priority,
) {
  switch (priority) {
    case SupportTicketPriority.low:
      return l10n.supportPriorityLow;
    case SupportTicketPriority.medium:
      return l10n.supportPriorityMedium;
    case SupportTicketPriority.high:
      return l10n.supportPriorityHigh;
    case SupportTicketPriority.urgent:
      return l10n.supportPriorityUrgent;
  }
}

String supportStatusLabel(AppLocalizations l10n, SupportTicketStatus status) {
  switch (status) {
    case SupportTicketStatus.open:
      return l10n.supportStatusOpen;
    case SupportTicketStatus.inProgress:
      return l10n.supportStatusInProgress;
    case SupportTicketStatus.waitingCustomer:
      return l10n.supportStatusWaitingCustomer;
    case SupportTicketStatus.resolved:
      return l10n.supportStatusResolved;
    case SupportTicketStatus.closed:
      return l10n.supportStatusClosed;
  }
}
