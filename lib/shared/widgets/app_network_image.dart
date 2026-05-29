import 'package:flutter/material.dart';

import '../../core/util/safe_numeric.dart';

/// Memory-safe network image with decode caps, loading, and error fallbacks.
///
/// Use instead of raw [Image.network] in lists and cards to avoid jank and
/// unbounded decode memory. Does not require an extra package — uses Flutter's
/// in-memory image cache with [cacheWidth]/[cacheHeight].
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.placeholderIcon = Icons.image_not_supported_outlined,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final resolved = url?.trim() ?? '';
    if (resolved.isEmpty) {
      return _wrap(_fallbackWidget(context));
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = safeCacheDimension(width, dpr);
    final cacheHeight = safeCacheDimension(height, dpr);
    final layoutWidth = width != null && width!.isFinite && width! > 0
        ? width
        : null;
    final layoutHeight = height != null && height!.isFinite && height! > 0
        ? height
        : null;

    Widget image = Image.network(
      resolved,
      width: layoutWidth,
      height: layoutHeight,
      fit: fit,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: layoutWidth,
          height: layoutHeight,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => _fallbackWidget(context),
    );

    return _wrap(image);
  }

  Widget _wrap(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _fallbackWidget(BuildContext context) {
    if (fallback != null) return fallback!;
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(placeholderIcon, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
