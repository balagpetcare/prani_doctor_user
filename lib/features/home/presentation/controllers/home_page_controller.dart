import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_navigation.dart';
import '../theme/home_tokens.dart';

/// Scroll and refresh orchestration for the home dashboard.
class HomePageController {
  HomePageController(this.ref) {
    scrollController.addListener(_onScroll);
  }

  final WidgetRef ref;
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<int> lazyTier = ValueNotifier(1);

  static const _lazySectionCount = 8;
  static const _lazyWarmupOffset = 420.0;

  Future<void> refresh() => HomeNavigation.refreshDashboard(ref);

  void handleDeepLinkEntry({bool refresh = false}) {
    HomeNavigation.handleDeepLinkEntry(ref, refresh: refresh);
  }

  void syncLazyTier() => _onScroll();

  bool shouldMountSection(int sectionIndex) =>
      sectionIndex <= lazyTier.value.clamp(0, _lazySectionCount);

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final probe =
        position.pixels +
        position.viewportDimension +
        HomeTokens.scrollCacheExtent -
        _lazyWarmupOffset;
    final tier = (probe / HomeTokens.lazySectionScrollChunk).floor().clamp(
      0,
      _lazySectionCount,
    );
    if (tier != lazyTier.value) {
      lazyTier.value = tier;
    }
  }

  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    lazyTier.dispose();
  }
}
