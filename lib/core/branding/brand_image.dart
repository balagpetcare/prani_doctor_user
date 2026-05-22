import 'package:flutter/material.dart';

import 'brand_theme.dart';

/// Bundled brand image with a consistent graceful fallback when loading fails.
class BrandImage extends StatelessWidget {
  const BrandImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackSize,
    this.hideOnError = false,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? fallbackSize;
  final bool hideOnError;

  /// Primary logo fallback used on splash, boot, and welcome screens.
  factory BrandImage.logo({
    Key? key,
    required String asset,
    double? height,
    double? width,
    BoxFit fit = BoxFit.contain,
  }) {
    return BrandImage(
      key: key,
      asset: asset,
      height: height,
      width: width,
      fit: fit,
      fallbackIcon: Icons.pets,
      fallbackSize: height ?? width ?? 72,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (hideOnError) {
          return SizedBox(width: width, height: height);
        }

        final iconSize = fallbackSize ?? height ?? width ?? 48;
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Icon(
              fallbackIcon,
              size: iconSize,
              color: BrandColors.primary,
            ),
          ),
        );
      },
    );
  }
}
