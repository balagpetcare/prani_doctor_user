import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/support_attachment_service.dart';
import '../../data/support_dto.dart';
import '../../data/support_validation.dart';

class SupportAttachmentPicker extends ConsumerWidget {
  const SupportAttachmentPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final attachments = ref.watch(pendingAttachmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: attachments.length >= SupportValidation.maxAttachments
                  ? null
                  : () => _pickImage(context, ref),
              icon: const Icon(Icons.photo_outlined),
              label: Text(l10n.supportAddImage),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: attachments.length >= SupportValidation.maxAttachments
                  ? null
                  : () => _pickDocument(context, ref, l10n),
              icon: const Icon(Icons.attach_file),
              label: Text(l10n.supportAddDocument),
            ),
          ],
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...attachments.map((a) => _AttachmentTile(attachment: a)),
        ],
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    _addFile(
      ref,
      file.path,
      file.name,
      file.mimeType ?? 'image/jpeg',
      await file.length(),
    );
  }

  Future<void> _pickDocument(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );
    final file = result?.files.single;
    if (file == null || file.path == null) return;
    final mime = _mimeFromName(file.name);
    _addFile(ref, file.path!, file.name, mime, file.size);
  }

  void _addFile(
    WidgetRef ref,
    String path,
    String name,
    String mime,
    int size,
  ) {
    final l10nError = SupportValidation.validateFile(
      mimeType: mime,
      sizeBytes: size,
      unsupportedType: 'unsupported',
      fileTooLarge: 'too large',
    );
    if (l10nError != null) return;

    ref
        .read(pendingAttachmentsProvider.notifier)
        .add(
          PendingSupportAttachment(
            localPath: path,
            fileName: name,
            mimeType: mime,
            sizeBytes: size,
          ),
        );
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({required this.attachment});

  final PendingSupportAttachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(pendingAttachmentsProvider.notifier);
    final service = ref.read(supportAttachmentServiceProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _leading(context),
        title: Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachment.state == SupportAttachmentUploadState.uploading)
              LinearProgressIndicator(
                value: attachment.progress > 0 ? attachment.progress : null,
              ),
            if (attachment.state == SupportAttachmentUploadState.error)
              Text(
                attachment.errorMessage ?? l10n.supportUploadFailed,
                style: const TextStyle(color: Colors.red),
              ),
            if (attachment.isUploaded) Text(l10n.supportUploadComplete),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachment.state == SupportAttachmentUploadState.error)
              IconButton(
                onPressed: () async {
                  final updated = await service.upload(attachment);
                  notifier.updateAttachment(updated);
                },
                icon: const Icon(Icons.refresh),
              ),
            if (!attachment.isUploaded &&
                attachment.state != SupportAttachmentUploadState.uploading)
              IconButton(
                onPressed: () async {
                  final updated = await service.upload(attachment);
                  notifier.updateAttachment(updated);
                },
                icon: const Icon(Icons.cloud_upload_outlined),
              ),
            IconButton(
              onPressed: () => notifier.remove(attachment.localPath),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leading(BuildContext context) {
    if (attachment.mimeType.startsWith('image/') &&
        File(attachment.localPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(attachment.localPath),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    if (attachment.mimeType == 'application/pdf') {
      return const Icon(Icons.picture_as_pdf);
    }
    return const Icon(Icons.insert_drive_file);
  }
}
