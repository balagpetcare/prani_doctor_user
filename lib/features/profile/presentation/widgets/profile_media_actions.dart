import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/profile_media_models.dart';
import '../../services/profile_media_optimizer.dart';
import '../../services/profile_media_upload_lock.dart';
import '../profile_providers.dart';

/// Shared camera/gallery picker + upload for avatar and cover.
abstract final class ProfileMediaActions {
  ProfileMediaActions._();

  static final _picker = ImagePicker();
  static final _lock = ProfileMediaUploadLock.instance;

  static Future<void> showPickerSheet(
    BuildContext context, {
    required WidgetRef ref,
    required ProfileMediaKind kind,
    required void Function(String message) onMessage,
  }) async {
    if (_lock.isUploading(kind)) return;

    final profile = ref.read(mobileMeProvider).valueOrNull;
    final hasMedia = kind == ProfileMediaKind.avatar
        ? (profile?.profilePhotoUrl?.isNotEmpty ?? false)
        : (profile?.coverPhotoUrl?.isNotEmpty ?? false);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCropUpload(
                  ref,
                  kind,
                  ImageSource.camera,
                  onMessage,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCropUpload(
                  ref,
                  kind,
                  ImageSource.gallery,
                  onMessage,
                );
              },
            ),
            if (hasMedia)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(
                  kind == ProfileMediaKind.avatar
                      ? 'Remove photo'
                      : 'Remove cover',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeMedia(ref, kind, onMessage);
                },
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _pickCropUpload(
    WidgetRef ref,
    ProfileMediaKind kind,
    ImageSource source,
    void Function(String message) onMessage,
  ) async {
    if (_lock.isUploading(kind)) return;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final croppedPath = await ProfileMediaOptimizer.cropImage(
      sourcePath: picked.path,
      kind: kind,
    );
    if (croppedPath == null) return;

    final stats = await ProfileMediaOptimizer.compressForUpload(
      inputPath: croppedPath,
      kind: kind,
    );
    if (stats == null) return;

    onMessage('Uploading…');
    final notifier = ref.read(mobileMeProvider.notifier);
    final error = kind == ProfileMediaKind.avatar
        ? await notifier.uploadAvatar(stats.outputPath)
        : await notifier.uploadCover(stats.outputPath);

    onMessage(error == null ? 'Updated' : (error));
  }

  static Future<void> _removeMedia(
    WidgetRef ref,
    ProfileMediaKind kind,
    void Function(String message) onMessage,
  ) async {
    if (_lock.isUploading(kind)) return;
    onMessage('Uploading…');
    final error = await ref.read(mobileMeProvider.notifier).removeMedia(kind);
    onMessage(error ?? 'Removed');
  }
}
