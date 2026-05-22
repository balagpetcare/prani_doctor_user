import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/core/branding/brand_assets.dart';

void main() {
  group('BrandAssets', () {
    test('every referenced asset file exists on disk', () {
      final missing = <String>[];
      for (final path in BrandAssets.allReferencedPaths) {
        if (!File(path).existsSync()) {
          missing.add(path);
        }
      }
      expect(
        missing,
        isEmpty,
        reason: 'Missing asset files: ${missing.join(', ')}',
      );
    });

    test('onboarding slide paths are unique', () {
      final images = BrandAssets.onboardingSlides.map((s) => s.image).toList();
      expect(images.toSet().length, images.length);
    });
  });
}
