import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/animal_repository.dart';
import '../animal_providers.dart';

class AnimalImageUpload extends ConsumerStatefulWidget {
  const AnimalImageUpload({super.key, this.currentUrl, required this.onUploaded});

  final String? currentUrl;
  final ValueChanged<String> onUploaded;

  @override
  ConsumerState<AnimalImageUpload> createState() => _AnimalImageUploadState();
}

class _AnimalImageUploadState extends ConsumerState<AnimalImageUpload> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _localPreview;

  Future<void> _pick(ImageSource source) async {
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
    ref.read(animalUploadProgressProvider.notifier).state = 0;

    final result = await ref.read(animalRepositoryProvider).uploadPhoto(
          picked.path,
          onProgress: (sent, total) {
            if (total > 0) {
              ref.read(animalUploadProgressProvider.notifier).state = sent / total;
            }
          },
        );

    if (!mounted) return;
    ref.read(animalUploadProgressProvider.notifier).state = null;
    result.when(
      success: (url) {
        setState(() {
          _uploading = false;
          _localPreview = null;
        });
        widget.onUploaded(url);
      },
      failure: (e) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(animalUploadProgressProvider);
    final imageUrl = _localPreview ?? widget.currentUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
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
            child: imageUrl == null ? const Center(child: Icon(Icons.pets, size: 48)) : null,
          ),
        ),
        if (_uploading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _uploading ? null : () => _pick(ImageSource.camera),
                child: Text(l10n.animalUploadCamera),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _uploading ? null : () => _pick(ImageSource.gallery),
                child: Text(l10n.animalUploadGallery),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
