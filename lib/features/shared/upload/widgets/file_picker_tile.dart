import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/api_result.dart';
import '../../../../core/error/app_exception.dart';
import '../models/upload_result.dart';
import '../providers/upload_provider.dart';
import '../services/upload_service.dart';
import '../services/upload_validation.dart';
import 'upload_progress.dart';

typedef FileUploadHandler =
    Future<UploadResult?> Function(
      String filePath, {
      void Function(int sent, int total)? onProgress,
    });

class PendingFileAttachment {
  const PendingFileAttachment({
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.state = UploadTaskState.idle,
    this.progress = 0,
    this.errorMessage,
    this.result,
  });

  final String localPath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final UploadTaskState state;
  final double progress;
  final String? errorMessage;
  final UploadResult? result;

  bool get isUploaded => state == UploadTaskState.success && result != null;

  PendingFileAttachment copyWith({
    UploadTaskState? state,
    double? progress,
    String? errorMessage,
    UploadResult? result,
  }) {
    return PendingFileAttachment(
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
      result: result ?? this.result,
    );
  }
}

class FilePickerTile extends ConsumerStatefulWidget {
  const FilePickerTile({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.maxAttachments = 5,
    this.uploadHandler,
    this.allowImages = true,
    this.allowDocuments = true,
    this.imageLabel = 'Add image',
    this.documentLabel = 'Add file',
  });

  final List<PendingFileAttachment> attachments;
  final ValueChanged<List<PendingFileAttachment>> onAttachmentsChanged;
  final int maxAttachments;
  final FileUploadHandler? uploadHandler;
  final bool allowImages;
  final bool allowDocuments;
  final String imageLabel;
  final String documentLabel;

  @override
  ConsumerState<FilePickerTile> createState() => _FilePickerTileState();
}

class _FilePickerTileState extends ConsumerState<FilePickerTile> {
  final _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    if (widget.attachments.length >= widget.maxAttachments) return;
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 70,
    );
    if (file == null) return;
    await _addAndUpload(
      file.path,
      file.name,
      file.mimeType ?? 'image/jpeg',
      await file.length(),
    );
  }

  Future<void> _pickDocument() async {
    if (widget.attachments.length >= widget.maxAttachments) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'txt',
        'jpg',
        'jpeg',
        'png',
      ],
    );
    final file = result?.files.single;
    if (file?.path == null) return;
    await _addAndUpload(
      file!.path!,
      file.name,
      UploadValidation.mimeFromPath(file.name) ?? 'application/octet-stream',
      file.size,
    );
  }

  Future<void> _addAndUpload(
    String path,
    String name,
    String mime,
    int size,
  ) async {
    final validationError = UploadValidation.validateFile(
      path: path,
      sizeBytes: size,
      mimeType: mime,
      maxBytes: UploadValidation.defaultMaxSupportBytes,
    );
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    var list = [
      ...widget.attachments,
      PendingFileAttachment(
        localPath: path,
        fileName: name,
        mimeType: mime,
        sizeBytes: size,
        state: UploadTaskState.uploading,
      ),
    ];
    widget.onAttachmentsChanged(list);

    final uploadCall = widget.uploadHandler;
    final result = await ref
        .read(uploadProgressProvider.notifier)
        .upload(
          localPath: path,
          uploadCall: ({required filePath, onProgress, cancelToken}) {
            if (uploadCall != null) {
              return uploadCall(filePath, onProgress: onProgress).then(
                (value) => value == null
                    ? const ApiResult.failure(
                        AppException(message: 'Upload failed'),
                      )
                    : ApiResult.success(value),
              );
            }
            return ref
                .read(uploadServiceProvider)
                .uploadSupportAttachment(
                  filePath,
                  onProgress: onProgress,
                  cancelToken: cancelToken,
                );
          },
        );

    list = widget.attachments.map((item) {
      if (item.localPath != path) return item;
      if (result == null) {
        return item.copyWith(
          state: UploadTaskState.error,
          errorMessage: 'Upload failed',
        );
      }
      return item.copyWith(
        state: UploadTaskState.success,
        progress: 1,
        result: result,
      );
    }).toList();

    if (list.every((a) => a.localPath != path)) {
      list = [
        ...list,
        PendingFileAttachment(
          localPath: path,
          fileName: name,
          mimeType: mime,
          sizeBytes: size,
          state: result == null
              ? UploadTaskState.error
              : UploadTaskState.success,
          progress: result == null ? 0 : 1,
          result: result,
          errorMessage: result == null ? 'Upload failed' : null,
        ),
      ];
    }

    if (mounted) widget.onAttachmentsChanged(list);
  }

  void _remove(String localPath) {
    widget.onAttachmentsChanged(
      widget.attachments.where((a) => a.localPath != localPath).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (widget.allowImages)
              OutlinedButton.icon(
                onPressed: widget.attachments.length >= widget.maxAttachments
                    ? null
                    : _pickImage,
                icon: const Icon(Icons.photo_outlined),
                label: Text(widget.imageLabel),
              ),
            if (widget.allowImages && widget.allowDocuments)
              const SizedBox(width: 8),
            if (widget.allowDocuments)
              OutlinedButton.icon(
                onPressed: widget.attachments.length >= widget.maxAttachments
                    ? null
                    : _pickDocument,
                icon: const Icon(Icons.attach_file),
                label: Text(widget.documentLabel),
              ),
          ],
        ),
        if (widget.attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...widget.attachments.map((attachment) {
            final task = ref.watch(
              uploadProgressProvider,
            )[attachment.localPath];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: attachment.mimeType.startsWith('image/')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(attachment.localPath),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.insert_drive_file_outlined),
                title: Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: UploadProgress(
                  progress: task?.progress ?? attachment.progress,
                  state: task?.state ?? attachment.state,
                  errorMessage: task?.errorMessage ?? attachment.errorMessage,
                  showLabel: false,
                  onRetry: attachment.state == UploadTaskState.error
                      ? () => _addAndUpload(
                          attachment.localPath,
                          attachment.fileName,
                          attachment.mimeType,
                          attachment.sizeBytes,
                        )
                      : null,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _remove(attachment.localPath),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
