import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/api_result.dart';
import '../../../../core/error/app_exception.dart';
import '../models/upload_result.dart';
import '../providers/upload_provider.dart';
import '../services/upload_service.dart';
import 'upload_progress.dart';

typedef ImageUploadHandler =
    Future<UploadResult?> Function(
      String filePath, {
      void Function(int sent, int total)? onProgress,
    });

typedef UploadUrlResolver = String Function(UploadResult upload);

class ImagePickerTile extends ConsumerStatefulWidget {
  const ImagePickerTile({
    super.key,
    this.currentUrl,
    required     this.onUploaded,
    this.uploadHandler,
    this.resolveUploadUrl,
    this.aspectRatio = 1,
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.imageQuality = 70,
    this.allowCamera = true,
    this.allowGallery = true,
    this.cameraLabel = 'Camera',
    this.galleryLabel = 'Gallery',
    this.emptyIcon = Icons.image_outlined,
  });

  final String? currentUrl;
  final ValueChanged<String> onUploaded;
  final ImageUploadHandler? uploadHandler;
  final UploadUrlResolver? resolveUploadUrl;
  final double aspectRatio;
  final int maxWidth;
  final int maxHeight;
  final int imageQuality;
  final bool allowCamera;
  final bool allowGallery;
  final String cameraLabel;
  final String galleryLabel;
  final IconData emptyIcon;

  @override
  ConsumerState<ImagePickerTile> createState() => _ImagePickerTileState();
}

class _ImagePickerTileState extends ConsumerState<ImagePickerTile> {
  final _picker = ImagePicker();
  String? _localPreview;
  String? _activePath;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: widget.maxWidth.toDouble(),
      maxHeight: widget.maxHeight.toDouble(),
      imageQuality: widget.imageQuality,
    );
    if (picked == null) return;

    setState(() {
      _localPreview = picked.path;
      _activePath = picked.path;
    });

    final upload = await ref
        .read(uploadProgressProvider.notifier)
        .upload(
          localPath: picked.path,
          uploadCall: ({required filePath, onProgress, cancelToken}) {
            final handler = widget.uploadHandler;
            if (handler != null) {
              return handler(filePath, onProgress: onProgress).then(
                (value) => value == null
                    ? const ApiResult.failure(
                        AppException(message: 'Upload failed'),
                      )
                    : ApiResult.success(value),
              );
            }
            return ref
                .read(uploadServiceProvider)
                .uploadProfileImage(
                  filePath,
                  onProgress: onProgress,
                  cancelToken: cancelToken,
                );
          },
        );

    if (!mounted) return;

    if (upload != null) {
      final resolver = widget.resolveUploadUrl;
      final url = resolver != null
          ? resolver(upload)
          : (upload.userProfilePhotoUrl.isNotEmpty
                ? upload.userProfilePhotoUrl
                : upload.url);
      if (url.isNotEmpty) {
        setState(() {
          _localPreview = null;
          _activePath = null;
        });
        widget.onUploaded(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _localPreview ?? widget.currentUrl;
    final task = _activePath != null
        ? ref.watch(uploadProgressProvider)[_activePath!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null
                  ? DecorationImage(
                      image: imageUrl.startsWith('http')
                          ? NetworkImage(imageUrl)
                          : FileImage(File(imageUrl)) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Center(child: Icon(widget.emptyIcon, size: 48))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        UploadProgress(
          progress: task?.progress,
          state: task?.state ?? UploadTaskState.idle,
          errorMessage: task?.errorMessage,
          onRetry: _activePath != null && task?.state == UploadTaskState.error
              ? () => _pick(ImageSource.gallery)
              : null,
          onCancel:
              _activePath != null && task?.state == UploadTaskState.uploading
              ? () => ref
                    .read(uploadProgressProvider.notifier)
                    .cancel(_activePath!)
              : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (widget.allowCamera)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: task?.state == UploadTaskState.uploading
                      ? null
                      : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(widget.cameraLabel),
                ),
              ),
            if (widget.allowCamera && widget.allowGallery)
              const SizedBox(width: 8),
            if (widget.allowGallery)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: task?.state == UploadTaskState.uploading
                      ? null
                      : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(widget.galleryLabel),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
