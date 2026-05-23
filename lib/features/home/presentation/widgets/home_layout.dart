import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/home_tokens.dart';
import 'home_shimmer.dart';

/// Wraps a home section for accessibility, repaint isolation, and stable layout.
class HomeSectionScope extends StatelessWidget {
  const HomeSectionScope({
    super.key,
    required this.label,
    required this.child,
    this.header,
  });

  final String label;
  final Widget child;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [?header, child],
        ),
      ),
    );
  }
}

/// Defers building heavy sections until the user scrolls near them.
class HomeLazyMount extends StatelessWidget {
  const HomeLazyMount({
    super.key,
    required this.enabled,
    required this.placeholderHeight,
    required this.child,
  });

  final bool enabled;
  final double placeholderHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (enabled) return child;
    return SizedBox(height: placeholderHeight);
  }
}

/// Horizontal list that does not compete with the parent vertical scroll.
class HomeHorizontalList extends StatelessWidget {
  const HomeHorizontalList({
    super.key,
    this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorWidth = HomeTokens.space12,
    this.controller,
  });

  final double? height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorWidth;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: HomeTokens.pageHorizontal(context),
      primary: false,
      shrinkWrap: height == null,
      cacheExtent: HomeTokens.horizontalListCacheExtent,
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(width: separatorWidth),
      itemBuilder: itemBuilder,
    );

    if (height == null) return list;
    return SizedBox(height: height, child: list);
  }
}

/// Applies RTL-safe page padding around a sliver child.
class HomeSliverPadding extends StatelessWidget {
  const HomeSliverPadding({super.key, required this.sliver});

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: HomeTokens.pageHorizontal(context),
      sliver: sliver,
    );
  }
}

/// Announces offline/cache state to screen readers.
class HomeOfflineBanner extends StatelessWidget {
  const HomeOfflineBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: HomeTokens.space16,
          end: HomeTokens.space16,
          top: HomeTokens.space8,
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}

void homeAnnounce(BuildContext context, String message) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}

/// Defers a sliver subtree until the parent scroll probe reaches its tier.
class HomeLazySliver extends StatelessWidget {
  const HomeLazySliver({
    super.key,
    required this.enabled,
    required this.placeholderHeight,
    required this.sliver,
  });

  final bool enabled;
  final double placeholderHeight;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    if (enabled) return sliver;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: placeholderHeight,
        child: const HomeSectionShimmer(lines: 2),
      ),
    );
  }
}
