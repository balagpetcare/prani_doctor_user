import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

import '../data/profile_media_models.dart';

/// Local crop + WEBP compression before backend upload.
abstract final class ProfileMediaOptimizer {
  static Future<String?> cropImage({
    required String sourcePath,
    required ProfileMediaKind kind,
  }) async {
    final ratio = kind == ProfileMediaKind.avatar
        ? const CropAspectRatio(ratioX: 1, ratioY: 1)
        : const CropAspectRatio(ratioX: 16, ratioY: 9);

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: ratio,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: kind == ProfileMediaKind.avatar
              ? 'Crop avatar'
              : 'Crop cover',
          initAspectRatio: kind == ProfileMediaKind.avatar
              ? CropAspectRatioPreset.square
              : CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: kind == ProfileMediaKind.avatar ? 'Crop avatar' : 'Crop cover',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: kind != ProfileMediaKind.avatar,
        ),
      ],
    );

    return cropped?.path;
  }

  static Future<ProfileCompressionStats?> compressForUpload({
    required String inputPath,
    required ProfileMediaKind kind,
  }) async {
    final originalFile = File(inputPath);
    if (!await originalFile.exists()) return null;
    final originalBytes = await originalFile.length();

    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}${Platform.pathSeparator}profile_${kind.name}_${DateTime.now().millisecondsSinceEpoch}.webp';

    final maxWidth = kind == ProfileMediaKind.avatar ? 800 : 1600;
    final maxHeight = kind == ProfileMediaKind.avatar ? 800 : 900;
    final quality = kind == ProfileMediaKind.avatar ? 82 : 80;

    final out = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outPath,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      keepExif: false,
    );

    if (out == null) return null;
    var optimizedBytes = await out.length();

    // Second pass if still above target
    final target = kind == ProfileMediaKind.avatar ? 200 * 1024 : 350 * 1024;
    var currentPath = out.path;
    var q = quality;
    while (optimizedBytes > target && q > 55) {
      q -= 8;
      final retryPath =
          '${dir.path}${Platform.pathSeparator}profile_${kind.name}_retry_${DateTime.now().millisecondsSinceEpoch}.webp';
      final retry = await FlutterImageCompress.compressAndGetFile(
        currentPath,
        retryPath,
        format: CompressFormat.webp,
        quality: q,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );
      if (retry == null) break;
      currentPath = retry.path;
      optimizedBytes = await retry.length();
    }

    if (kDebugMode) {
      debugPrint(
        '[MEDIA_CROP] ${kind.name} compressed '
        '${ProfileCompressionStats(originalBytes: originalBytes, optimizedBytes: optimizedBytes, outputPath: currentPath).label}',
      );
    }

    return ProfileCompressionStats(
      originalBytes: originalBytes,
      optimizedBytes: optimizedBytes,
      outputPath: currentPath,
    );
  }
}
