import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/support_attachment_service.dart';
import '../data/support_dto.dart';
import '../data/support_repository.dart';
import '../data/support_validation.dart';
import 'support_providers.dart';
import 'widgets/support_attachment_picker.dart';
import 'widgets/support_feedback.dart';
import 'widgets/support_ticket_card.dart';

class SupportTicketCreatePage extends ConsumerStatefulWidget {
  const SupportTicketCreatePage({super.key});

  @override
  ConsumerState<SupportTicketCreatePage> createState() => _SupportTicketCreatePageState();
}

class _SupportTicketCreatePageState extends ConsumerState<SupportTicketCreatePage> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  SupportTicketCategory _category = SupportTicketCategory.other;
  SupportTicketPriority _priority = SupportTicketPriority.medium;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final validationError = SupportValidation.validateTicket(
      category: _category,
      subject: _subjectController.text,
      description: _descriptionController.text,
      subjectRequired: l10n.supportSubjectRequired,
      descriptionRequired: l10n.supportDescriptionRequired,
      subjectTooShort: l10n.supportSubjectTooShort,
      descriptionTooShort: l10n.supportDescriptionTooShort,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    await ref.read(pendingAttachmentsProvider.notifier).uploadAll();
    final attachments = ref.read(pendingAttachmentsProvider.notifier);
    if (attachments.hasUploading || attachments.hasErrors) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supportUploadFailed)),
        );
      }
      return;
    }

    final input = SupportTicketInput(
      category: _category,
      subject: _subjectController.text,
      description: _descriptionController.text,
      priority: _priority,
      attachmentFileIds: attachments.uploadedFileIds(),
      attachmentLocalPaths: attachments.pendingLocalPaths(),
    );

    final result = await ref.read(supportRepositoryProvider).createTicket(input);
    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (ticket) {
        ref.read(pendingAttachmentsProvider.notifier).clear();
        ref.invalidate(supportTicketListProvider);
        context.go(AppRoutes.supportTicketDetail(ticket.id));
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportCreateTicketTitle)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<SupportTicketCategory>(
                value: _category,
                decoration: InputDecoration(labelText: l10n.supportCategoryLabel),
                items: SupportTicketCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(supportCategoryLabel(l10n, c)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SupportTicketPriority>(
                value: _priority,
                decoration: InputDecoration(labelText: l10n.supportPriorityLabel),
                items: SupportTicketPriority.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(supportPriorityLabel(l10n, p)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: l10n.supportSubjectLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(labelText: l10n.supportDescriptionLabel),
              ),
              const SizedBox(height: 16),
              Text(l10n.supportAttachmentsLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              const SupportAttachmentPicker(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(l10n.supportSubmitTicket),
              ),
            ],
          ),
          if (_submitting) SupportFeedback.submissionOverlay(context, message: l10n.supportSubmitting),
        ],
      ),
    );
  }
}
