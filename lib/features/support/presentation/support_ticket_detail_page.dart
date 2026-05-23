import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../data/support_attachment_service.dart';
import '../data/support_dto.dart';
import '../data/support_repository.dart';
import 'support_navigation.dart';
import 'support_providers.dart';
import 'widgets/support_attachment_picker.dart';
import 'widgets/support_feedback.dart';
import 'widgets/support_message_bubble.dart';
import 'widgets/support_status_badge.dart';
import 'widgets/support_ticket_card.dart';

class SupportTicketDetailPage extends ConsumerStatefulWidget {
  const SupportTicketDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailPage> createState() =>
      _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState
    extends ConsumerState<SupportTicketDetailPage> {
  final _replyController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final l10n = AppLocalizations.of(context)!;
    if (_replyController.text.trim().isEmpty) return;
    if (ref.read(supportSubmissionProvider) ==
        SupportSubmissionState.submitting) {
      return;
    }

    setState(() => _submitting = true);
    ref.read(supportSubmissionProvider.notifier).state =
        SupportSubmissionState.submitting;
    await ref.read(pendingAttachmentsProvider.notifier).uploadAll();
    final attachments = ref.read(pendingAttachmentsProvider.notifier);
    if (attachments.hasUploading || attachments.hasErrors) {
      setState(() => _submitting = false);
      ref.read(supportSubmissionProvider.notifier).state =
          SupportSubmissionState.idle;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.supportUploadFailed)));
      }
      return;
    }

    final result = await ref
        .read(supportRepositoryProvider)
        .reply(
          SupportReplyInput(
            ticketId: widget.ticketId,
            body: _replyController.text,
            attachmentFileIds: attachments.uploadedFileIds(),
            attachmentLocalPaths: attachments.pendingLocalPaths(),
          ),
        );

    if (!mounted) return;
    setState(() => _submitting = false);
    ref.read(supportSubmissionProvider.notifier).state =
        SupportSubmissionState.idle;

    result.when(
      success: (_) {
        _replyController.clear();
        ref.read(pendingAttachmentsProvider.notifier).clear();
        SupportNavigation.afterTicketMutation(ref, ticketId: widget.ticketId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.supportReplySent)));
      },
      failure: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  Future<void> _closeTicket() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(supportRepositoryProvider)
        .closeTicket(widget.ticketId);
    if (!mounted) return;
    result.when(
      success: (_) {
        SupportNavigation.afterTicketMutation(ref, ticketId: widget.ticketId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.supportTicketClosed)));
      },
      failure: (e) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message))),
    );
  }

  Future<void> _reopenTicket() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(supportRepositoryProvider)
        .reopenTicket(widget.ticketId);
    if (!mounted) return;
    result.when(
      success: (_) {
        SupportNavigation.afterTicketMutation(ref, ticketId: widget.ticketId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.supportTicketReopened)));
      },
      failure: (e) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(supportTicketProvider(widget.ticketId));

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.supportTicketDetailTitle)),
      body: Stack(
        children: [
          ticketAsync.when(
            loading: SupportFeedback.loading,
            error: (e, _) => SupportFeedback.error(
              context,
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(supportTicketProvider(widget.ticketId)),
            ),
            data: (ticket) {
              final isClosed = ticket.status == SupportTicketStatus.closed;
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (ticket.fromCache)
                          SupportFeedback.offlineHint(context),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.subject,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            SupportStatusBadge(status: ticket.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${supportCategoryLabel(l10n, ticket.category)} · ${supportPriorityLabel(l10n, ticket.priority)}',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.supportDescriptionLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(ticket.description),
                        const SizedBox(height: 16),
                        SupportTimeline(
                          messages: ticket.timeline.isNotEmpty
                              ? ticket.timeline
                              : ticket.messages,
                        ),
                      ],
                    ),
                  ),
                  if (!isClosed) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _replyController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: l10n.supportReplyHint,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SupportAttachmentPicker(),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _submitting ? null : _sendReply,
                            child: Text(l10n.supportSendReply),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (_submitting)
            SupportFeedback.submissionOverlay(
              context,
              message: l10n.supportSubmitting,
            ),
        ],
      ),
      bottomNavigationBar: ticketAsync.maybeWhen(
        data: (ticket) {
          if (ticket.status == SupportTicketStatus.closed) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.tonal(
                  onPressed: _reopenTicket,
                  child: Text(l10n.supportReopenTicket),
                ),
              ),
            );
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: _closeTicket,
                child: Text(l10n.supportCloseTicket),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}
