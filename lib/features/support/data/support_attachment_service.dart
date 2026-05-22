import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support_dto.dart';import 'support_repository.dart';
import 'support_validation.dart';

class SupportAttachmentService {
  SupportAttachmentService(this._repository);

  final SupportRepository _repository;

  Future<PendingSupportAttachment> upload(
    PendingSupportAttachment attachment, {
    void Function(double progress)? onProgress,
  }) async {
    final validationError = SupportValidation.validateFile(
      mimeType: attachment.mimeType,
      sizeBytes: attachment.sizeBytes,
      unsupportedType: 'Unsupported file type',
      fileTooLarge: 'File exceeds 8 MB limit',
    );
    if (validationError != null) {
      return attachment.copyWith(
        state: SupportAttachmentUploadState.error,
        errorMessage: validationError,
      );
    }

    var current = attachment.copyWith(
      state: SupportAttachmentUploadState.uploading,
      progress: 0,
      errorMessage: null,
    );

    final result = await _repository.uploadAttachment(
      attachment.localPath,
      onProgress: (sent, total) {
        if (total <= 0) return;
        final p = sent / total;
        onProgress?.call(p);
        current = current.copyWith(progress: p);
      },
    );

    return result.when(
      success: (upload) => current.copyWith(
        fileId: upload.fileId,
        downloadUrl: upload.downloadUrl,
        progress: 1,
        state: SupportAttachmentUploadState.success,
      ),
      failure: (e) => current.copyWith(
        state: SupportAttachmentUploadState.error,
        errorMessage: e.message,
      ),
    );
  }
}

final supportAttachmentServiceProvider = Provider<SupportAttachmentService>((ref) {
  return SupportAttachmentService(ref.watch(supportRepositoryProvider));
});

final pendingAttachmentsProvider =
    StateNotifierProvider<PendingAttachmentsNotifier, List<PendingSupportAttachment>>(
  PendingAttachmentsNotifier.new,
);

class PendingAttachmentsNotifier extends StateNotifier<List<PendingSupportAttachment>> {
  PendingAttachmentsNotifier(this._ref) : super(const []);

  final Ref _ref;

  void add(PendingSupportAttachment attachment) {
    if (state.length >= SupportValidation.maxAttachments) return;
    state = [...state, attachment];
  }

  void remove(String localPath) {
    state = state.where((a) => a.localPath != localPath).toList();
  }

  void clear() => state = const [];

  void updateAttachment(PendingSupportAttachment attachment) {
    state = [
      for (final item in state)
        if (item.localPath == attachment.localPath) attachment else item,
    ];
  }

  Future<void> uploadAll() async {
    final service = _ref.read(supportAttachmentServiceProvider);
    for (final attachment in state) {
      if (attachment.isUploaded) continue;
      final updated = await service.upload(
        attachment,
        onProgress: (p) {
          updateAttachment(attachment.copyWith(progress: p));
        },
      );
      updateAttachment(updated);
    }
  }

  List<String> uploadedFileIds() {
    return state
        .where((a) => a.isUploaded)
        .map((a) => a.fileId!)
        .toList();
  }

  List<String> pendingLocalPaths() {
    return state.where((a) => !a.isUploaded).map((a) => a.localPath).toList();
  }

  bool get allUploaded => state.every((a) => a.isUploaded);
  bool get hasUploading => state.any((a) => a.state == SupportAttachmentUploadState.uploading);
  bool get hasErrors => state.any((a) => a.state == SupportAttachmentUploadState.error);
}
