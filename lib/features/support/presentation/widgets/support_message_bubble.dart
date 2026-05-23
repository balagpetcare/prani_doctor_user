import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/support_dto.dart';

class SupportMessageBubble extends StatelessWidget {
  const SupportMessageBubble({super.key, required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.authorType == SupportMessageAuthor.customer;
    final isSystem = message.authorType == SupportMessageAuthor.system;
    final alignment = isCustomer ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSystem
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : isCustomer
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSystem)
                  Text(
                    AppLocalizations.of(context)!.supportTimelineSystem,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                Text(message.body),
                if (message.attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...message.attachments.map(
                    (a) => _AttachmentLink(attachment: a),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (message.pendingSync)
                  Text(
                    AppLocalizations.of(context)!.supportPendingSync,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _AttachmentLink extends StatelessWidget {
  const _AttachmentLink({required this.attachment});

  final SupportAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: attachment.downloadUrl == null
          ? null
          : () {
              context.push(
                Uri(
                  path: AppRoutes.supportAttachmentView,
                  queryParameters: {
                    'url': attachment.downloadUrl!,
                    'name': attachment.fileName,
                    'mime': attachment.mimeType,
                  },
                ).toString(),
              );
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.isPdf ? Icons.picture_as_pdf : Icons.attach_file,
            size: 16,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(attachment.fileName, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class SupportTimeline extends StatelessWidget {
  const SupportTimeline({super.key, required this.messages});

  final List<SupportMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context)!.supportTimelineTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...messages.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SupportMessageBubble(message: m),
          ),
        ),
      ],
    );
  }
}
