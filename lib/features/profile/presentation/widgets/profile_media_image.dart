import 'package:flutter/material.dart';

/// Cached network avatar/cover with placeholder fallback.
class ProfileMediaImage extends StatelessWidget {
  const ProfileMediaImage({
    super.key,
    this.url,
    this.thumbUrl,
    this.fallbackText,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.person_outline,
  });

  final String? url;
  final String? thumbUrl;
  final String? fallbackText;
  final BoxFit fit;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final resolved = (thumbUrl?.isNotEmpty ?? false) ? thumbUrl! : (url ?? '');
    if (resolved.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: fallbackText != null && fallbackText!.isNotEmpty
              ? Text(
                  fallbackText![0].toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium,
                )
              : Icon(placeholderIcon, size: 40),
        ),
      );
    }

    return Image.network(
      resolved,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (_, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(placeholderIcon, size: 40),
      ),
    );
  }
}
