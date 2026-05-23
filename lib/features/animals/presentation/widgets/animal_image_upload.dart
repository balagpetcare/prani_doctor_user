import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../shared/upload/services/upload_service.dart';
import '../../../shared/upload/widgets/image_picker_tile.dart';
import '../animal_providers.dart';

class AnimalImageUpload extends ConsumerWidget {
  const AnimalImageUpload({
    super.key,
    this.currentUrl,
    required this.onUploaded,
  });

  final String? currentUrl;
  final ValueChanged<String> onUploaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ImagePickerTile(
      currentUrl: currentUrl,
      cameraLabel: l10n.farmUploadCamera,
      galleryLabel: l10n.farmUploadGallery,
      onUploaded: onUploaded,
      resolveUploadUrl: (upload) => upload.animalPhotoUrl,
      uploadHandler: (path, {onProgress}) async {
        final result = await ref
            .read(uploadServiceProvider)
            .uploadAnimalPhoto(path, onProgress: onProgress);
        return result.when(
          success: (upload) {
            ref.read(animalUploadProgressProvider.notifier).state = null;
            return upload;
          },
          failure: (e) {
            ref.read(animalUploadProgressProvider.notifier).state = null;
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
