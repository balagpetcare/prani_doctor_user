import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../shared/upload/services/upload_service.dart';
import '../../../shared/upload/widgets/image_picker_tile.dart';
import '../farm_providers.dart';

class FarmImageUpload extends ConsumerWidget {
  const FarmImageUpload({super.key, this.currentUrl, required this.onUploaded});

  final String? currentUrl;
  final ValueChanged<String> onUploaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ImagePickerTile(
      currentUrl: currentUrl,
      aspectRatio: 16 / 9,
      cameraLabel: l10n.farmUploadCamera,
      galleryLabel: l10n.farmUploadGallery,
      onUploaded: onUploaded,
      uploadHandler: (path, {onProgress}) async {
        final result = await ref
            .read(uploadServiceProvider)
            .uploadCoverImage(path, onProgress: onProgress);
        return result.when(
          success: (upload) {
            ref.read(farmUploadProgressProvider.notifier).state = null;
            return upload;
          },
          failure: (e) {
            ref.read(farmUploadProgressProvider.notifier).state = null;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.farmUploadFailed}: ${e.message}'),
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
