import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/localization_extensions.dart';
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

    final l10n = context.tr;
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
              title: Text(l10n.t('uploadCamera')),
              onTap: () {
                Navigator.pop(ctx);
                _pickCropUpload(
                  ref,
                  kind,
                  ImageSource.camera,
                  onMessage,
                  l10n.profileUploading,
                  l10n.profileUpdatedSuccess,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.t('uploadGallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickCropUpload(
                  ref,
                  kind,
                  ImageSource.gallery,
                  onMessage,
                  l10n.profileUploading,
                  l10n.profileUpdatedSuccess,
                );
              },
            ),
            if (hasMedia)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(
                  kind == ProfileMediaKind.avatar
                      ? l10n.profileRemovePhoto
                      : l10n.profileRemoveCover,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeMedia(
                    ref,
                    kind,
                    onMessage,
                    l10n.profileUploading,
                    l10n.t('Removed'),
                  );
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
    String uploadingLabel,
    String updatedLabel,
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

    onMessage(uploadingLabel);
    final notifier = ref.read(mobileMeProvider.notifier);
    final error = kind == ProfileMediaKind.avatar
        ? await notifier.uploadAvatar(stats.outputPath)
        : await notifier.uploadCover(stats.outputPath);

    onMessage(error == null ? updatedLabel : error);
  }

  static Future<void> _removeMedia(
    WidgetRef ref,
    ProfileMediaKind kind,
    void Function(String message) onMessage,
    String uploadingLabel,
    String removedLabel,
  ) async {
    if (_lock.isUploading(kind)) return;
    onMessage(uploadingLabel);
    final error = await ref.read(mobileMeProvider.notifier).removeMedia(kind);
    onMessage(error ?? removedLabel);
  }
}
