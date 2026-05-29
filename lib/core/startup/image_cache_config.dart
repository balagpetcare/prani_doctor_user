import 'package:flutter/painting.dart';

/// Tunes Flutter's in-memory image cache for mobile-first performance.
abstract final class ImageCacheConfig {
  ImageCacheConfig._();

  /// Applies conservative limits before any network images decode.
  static void apply() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 200;
    cache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB
  }
}
