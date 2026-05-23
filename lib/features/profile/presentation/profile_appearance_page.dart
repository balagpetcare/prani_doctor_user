import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_media_models.dart';
import '../services/profile_media_optimizer.dart';
import '../services/profile_media_upload_lock.dart';
import 'profile_providers.dart';
import 'widgets/profile_feedback.dart';
import 'widgets/profile_media_image.dart';

/// Cover + avatar only. Media updates after server confirms upload.
class ProfileAppearancePage extends ConsumerStatefulWidget {
  const ProfileAppearancePage({super.key});

  @override
  ConsumerState<ProfileAppearancePage> createState() =>
      _ProfileAppearancePageState();
}

class _ProfileAppearancePageState extends ConsumerState<ProfileAppearancePage> {
  final _picker = ImagePicker();
  final _lock = ProfileMediaUploadLock.instance;

  bool _avatarUploading = false;
  bool _coverUploading = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openAvatarPicker() {
    if (kDebugMode) debugPrint('[AVATAR_TAP]');
    if (_lock.isUploading(ProfileMediaKind.avatar) || _avatarUploading) return;
    _showImageSourceSheet(kind: ProfileMediaKind.avatar);
  }

  Future<void> _showImageSourceSheet({required ProfileMediaKind kind}) async {
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
                _pickCropUpload(kind, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCropUpload(kind, ImageSource.gallery);
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
                  _removeMedia(kind);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCropUpload(
    ProfileMediaKind kind,
    ImageSource source,
  ) async {
    if (_lock.isUploading(kind)) return;

    final isAvatar = kind == ProfileMediaKind.avatar;
    if (kDebugMode) {
      debugPrint(
        isAvatar
            ? '[AVATAR_PICK] source=${source.name}'
            : '[MEDIA_PICK] kind=${kind.name} source=${source.name}',
      );
    }

    final picked = await _picker.pickImage(source: source);
    if (picked == null || !mounted) return;

    if (kDebugMode) {
      debugPrint(
        isAvatar
            ? '[AVATAR_PICK] ok path=${picked.path}'
            : '[MEDIA_PICK] ok path=${picked.path}',
      );
    }

    final croppedPath = await ProfileMediaOptimizer.cropImage(
      sourcePath: picked.path,
      kind: kind,
    );
    if (croppedPath == null || !mounted) return;

    if (kDebugMode) {
      debugPrint(
        isAvatar
            ? '[AVATAR_CROP] ok path=$croppedPath'
            : '[MEDIA_CROP] ok path=$croppedPath',
      );
    }

    final stats = await ProfileMediaOptimizer.compressForUpload(
      inputPath: croppedPath,
      kind: kind,
    );
    if (stats == null || !mounted) return;

    _snack('Uploading…');
    setState(() {
      if (isAvatar) {
        _avatarUploading = true;
      } else {
        _coverUploading = true;
      }
    });

    if (kDebugMode && isAvatar) debugPrint('[AVATAR_UPLOAD] start');

    final notifier = ref.read(mobileMeProvider.notifier);
    final error = isAvatar
        ? await notifier.uploadAvatar(stats.outputPath)
        : await notifier.uploadCover(stats.outputPath);

    if (!mounted) return;

    setState(() {
      if (isAvatar) {
        _avatarUploading = false;
      } else {
        _coverUploading = false;
      }
    });

    if (error == null) {
      if (kDebugMode && isAvatar) debugPrint('[AVATAR_APPLY] ok');
      _snack('Updated');
      return;
    }

    if (kDebugMode && isAvatar) debugPrint('[AVATAR_APPLY] failed $error');
    _snack('Upload failed');
  }

  Future<void> _removeMedia(ProfileMediaKind kind) async {
    if (_lock.isUploading(kind)) return;

    _snack('Uploading…');
    setState(() {
      if (kind == ProfileMediaKind.avatar) {
        _avatarUploading = true;
      } else {
        _coverUploading = true;
      }
    });

    final error = await ref.read(mobileMeProvider.notifier).removeMedia(kind);

    if (!mounted) return;

    setState(() {
      if (kind == ProfileMediaKind.avatar) {
        _avatarUploading = false;
      } else {
        _coverUploading = false;
      }
    });

    _snack(error == null ? 'Updated' : 'Upload failed');
  }

  Widget _avatarCameraButton({required VoidCallback? onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _coverCameraButton({required VoidCallback? onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _fadeMedia({
    required String? url,
    required String? thumbUrl,
    required IconData placeholderIcon,
    String? fallbackText,
    required BoxFit fit,
  }) {
    final key = ValueKey<String>(thumbUrl ?? url ?? 'empty');
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: key,
        child: ProfileMediaImage(
          url: url,
          thumbUrl: thumbUrl,
          fallbackText: fallbackText,
          placeholderIcon: placeholderIcon,
          fit: fit,
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required MobileMeDto profile,
    required ThemeData theme,
    required bool avatarBusy,
  }) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: avatarBusy ? null : _openAvatarPicker,
              child: CircleAvatar(
                radius: 56,
                backgroundColor: theme.colorScheme.surface,
                child: ClipOval(
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: _fadeMedia(
                      url: profile.profilePhotoUrl,
                      thumbUrl: profile.profilePhotoThumbUrl,
                      fallbackText: profile.name,
                      placeholderIcon: Icons.person_outline,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_avatarUploading)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _avatarCameraButton(
              onTap: avatarBusy ? null : _openAvatarPicker,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(mobileMeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: safeAppBar(context, title: const Text('Profile appearance')),
      body: profileAsync.when(
        loading: ProfileFeedback.editSkeleton,
        error: (e, _) => ProfileFeedback.errorFromObject(
          context,
          failure: e,
          onRetry: () =>
              ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);

          final avatarBusy = _lock.isUploading(ProfileMediaKind.avatar);
          final coverBusy = _lock.isUploading(ProfileMediaKind.cover);

          const coverHeight = 240.0;
          const avatarOverhang = 56.0;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(
                  height: coverHeight + avatarOverhang,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: coverHeight,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _fadeMedia(
                                url: profile.coverPhotoUrl,
                                thumbUrl: profile.coverPhotoThumbUrl,
                                placeholderIcon: Icons.landscape_outlined,
                                fit: BoxFit.cover,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.08),
                                      Colors.black.withValues(alpha: 0.35),
                                    ],
                                  ),
                                ),
                              ),
                              if (_coverUploading)
                                const ColoredBox(
                                  color: Color(0x66000000),
                                  child: Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: _coverCameraButton(
                                  onTap: coverBusy
                                      ? null
                                      : () => _showImageSourceSheet(
                                          kind: ProfileMediaKind.cover,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: _buildAvatar(
                            profile: profile,
                            theme: theme,
                            avatarBusy: avatarBusy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.name.trim().isEmpty ? '—' : profile.name.trim(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Profile appearance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// @deprecated Use [ProfileAppearancePage].
typedef ProfileEditPage = ProfileAppearancePage;
