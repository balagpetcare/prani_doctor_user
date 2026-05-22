import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/farm_repository.dart';
import '../farm_providers.dart';

class FarmImageUpload extends ConsumerStatefulWidget {
  const FarmImageUpload({
    super.key,
    this.currentUrl,
    required this.onUploaded,
  });

  final String? currentUrl;
  final ValueChanged<String> onUploaded;

  @override
  ConsumerState<FarmImageUpload> createState() => _FarmImageUploadState();
}

class _FarmImageUploadState extends ConsumerState<FarmImageUpload> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _error;
  String? _localPreview;

  Future<void> _pickAndUpload(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _error = null;
    });

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _localPreview = picked.path;
    });
    ref.read(farmUploadProgressProvider.notifier).state = 0;

    final result = await ref.read(farmRepositoryProvider).uploadCoverImage(
          picked.path,
          onProgress: (sent, total) {
            if (total > 0) {
              ref.read(farmUploadProgressProvider.notifier).state = sent / total;
            }
          },
        );

    if (!mounted) return;
    ref.read(farmUploadProgressProvider.notifier).state = null;

    result.when(
      success: (url) {
        setState(() {
          _uploading = false;
          _localPreview = null;
        });
        widget.onUploaded(url);
      },
      failure: (e) {
        setState(() {
          _uploading = false;
          _error = e.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.farmUploadFailed}: ${e.message}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(farmUploadProgressProvider);
    final imageUrl = _localPreview ?? widget.currentUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null
                  ? DecorationImage(
                      image: imageUrl.startsWith('http')
                          ? NetworkImage(imageUrl) as ImageProvider
                          : FileImage(File(imageUrl)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Center(child: Icon(Icons.image_outlined, size: 48))
                : null,
          ),
        ),
        if (_uploading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : () => _pickAndUpload(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.farmUploadCamera),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : () => _pickAndUpload(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.farmUploadGallery),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
