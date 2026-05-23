import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/util/safe_numeric.dart';
import '../theme/home_theme_extension.dart';
import '../theme/home_tokens.dart';
import 'home_shimmer.dart';

/// Reusable elevated surface used across home sections.
class HomeSurfaceCard extends StatelessWidget {
  const HomeSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(HomeTokens.space16),
    this.margin = EdgeInsets.zero,
    this.semanticLabel,
    this.heroTag,
    this.elevated = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final String? semanticLabel;
  final Object? heroTag;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final homeTheme = HomeThemeExtension.of(context);
    final radius = BorderRadius.circular(HomeTokens.radiusLg);

    Widget surface = AnimatedContainer(
      duration: HomeTokens.durationNormal,
      curve: HomeTokens.curveStandard,
      margin: margin,
      child: Material(
        color: scheme.surfaceContainerLowest,
        elevation: elevated
            ? homeTheme.raisedElevation
            : homeTheme.cardElevation,
        shadowColor: scheme.shadow.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (heroTag != null) {
      surface = Hero(
        tag: heroTag!,
        child: Material(type: MaterialType.transparency, child: surface),
      );
    }

    if (semanticLabel != null) {
      surface = Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: surface,
      );
    }

    return surface;
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: HomeTokens.space16,
        end: HomeTokens.space16,
        top: HomeTokens.space8,
        bottom: HomeTokens.space12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class HomeErrorRetry extends StatelessWidget {
  const HomeErrorRetry({
    super.key,
    required this.message,
    this.onRetry,
    this.offline = false,
    this.showCachedHint = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool offline;
  final bool showCachedHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: HomeSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  offline ? Icons.cloud_off_outlined : Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: HomeTokens.space12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: Text(l10n.dashboardRetry),
                  ),
              ],
            ),
            if (showCachedHint) ...[
              const SizedBox(height: HomeTokens.space8),
              Text(
                l10n.dashboardOfflineHint,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Offline-aware section wrapper — loading, cached data, empty, or retry.
class HomeSectionState<T> extends StatelessWidget {
  const HomeSectionState({
    super.key,
    required this.asyncValue,
    required this.dataBuilder,
    required this.onRetry,
    this.emptyBuilder,
    this.loadingHeight = 120,
    this.fromCache = false,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(T data) dataBuilder;
  final VoidCallback onRetry;
  final Widget Function()? emptyBuilder;
  final double loadingHeight;
  final bool fromCache;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return asyncValue.when(
      loading: () => HomeSectionLoading(height: loadingHeight),
      error: (_, _) => HomeErrorRetry(
        message: l10n.dashboardSectionOffline,
        offline: true,
        showCachedHint: fromCache,
        onRetry: onRetry,
      ),
      data: (data) {
        if (emptyBuilder != null && _isEmpty(data)) {
          return emptyBuilder!();
        }
        return dataBuilder(data);
      },
    );
  }

  bool _isEmpty(T data) {
    if (data is Iterable) return data.isEmpty;
    if (data is List) return data.isEmpty;
    return false;
  }
}

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HomeTokens.space16),
      child: HomeSurfaceCard(
        semanticLabel: message,
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: HomeTokens.space8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: HomeTokens.space8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeCachedImage extends StatelessWidget {
  const HomeCachedImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackText,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final String? fallbackText;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = url?.trim() ?? '';
    if (resolved.isEmpty) {
      return _fallback(context);
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
        final total = progress.expectedTotalBytes;
        final loaded = progress.cumulativeBytesLoaded;
        final fraction = total != null && total > 0
            ? safePercent(loaded, total)
            : null;
        return SizedBox(
          width: layoutWidth,
          height: layoutHeight,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: fraction,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => _fallback(context),
    );

    if (semanticLabel != null) {
      image = Semantics(label: semanticLabel, image: true, child: image);
    }

    return image;
  }

  Widget _fallback(BuildContext context) {
    final layoutWidth = width != null && width!.isFinite && width! > 0
        ? width
        : null;
    final layoutHeight = height != null && height!.isFinite && height! > 0
        ? height
        : null;
    return Container(
      width: layoutWidth,
      height: layoutHeight,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: fallbackText != null && fallbackText!.isNotEmpty
          ? Text(
              fallbackText![0].toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Icon(fallbackIcon, size: 28),
    );
  }
}

/// Per-section loading shimmer — keeps layout height stable (no shift).
class HomeSectionLoading extends StatelessWidget {
  const HomeSectionLoading({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(width: 220, child: HomeShimmerBox(height: 12)),
      ),
    );
  }
}
