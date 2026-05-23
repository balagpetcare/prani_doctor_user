import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/provider_stability.dart';
import '../../../../core/session/session_providers.dart';
import '../../../support/data/support_dto.dart';
import '../../../support/presentation/support_providers.dart';
import '../home_analytics.dart';
import '../models/home_section_models.dart';

HomeCommunityContentKind _kindFromCategory(String category) {
  final normalized = category.toUpperCase();
  if (normalized.contains('VIDEO')) return HomeCommunityContentKind.video;
  if (normalized.contains('TIP') || normalized.contains('HOW')) {
    return HomeCommunityContentKind.tip;
  }
  if (normalized.contains('ARTICLE') || normalized.contains('GUIDE')) {
    return HomeCommunityContentKind.article;
  }
  return HomeCommunityContentKind.post;
}

HomeCommunityItem _mapFaq(SupportHelpFaqItem item) => HomeCommunityItem(
  id: item.id.isNotEmpty ? item.id : item.question.hashCode.toString(),
  title: item.question,
  body: item.answer,
  kind: _kindFromCategory(item.category),
  category: item.category,
);

/// Community preview from support help FAQ (`supportHelpProvider`).
final homeCommunityPreviewProvider = FutureProvider<HomeCommunityPreview>((
  ref,
) async {
  ref.persistProvider('homeCommunityPreview');
  if (!ref.watch(protectedApisEnabledProvider)) {
    return HomeCommunityPreview.empty;
  }

  try {
    final help = await ref.watch(supportHelpProvider.future);
    final all = help.faq.map(_mapFaq).toList();
    if (all.isEmpty) {
      HomeAnalytics.sectionEmpty('community');
    } else {
      HomeAnalytics.sectionLoaded('community', fromCache: help.fromCache);
    }
    return HomeCommunityPreview(
      items: all.take(5).toList(),
      totalCount: all.length,
      fromCache: help.fromCache,
    );
  } catch (e) {
    HomeAnalytics.sectionError('community');
    rethrow;
  }
});

/// Paginated community feed — client-side paging over cached help content.
class HomeCommunityFeedNotifier extends Notifier<HomeCommunityFeedState> {
  @override
  HomeCommunityFeedState build() {
    ref.listen<AsyncValue<SupportHelpData>>(supportHelpProvider, (_, next) {
      next.whenData(_syncFromHelp);
    });
    final help = ref.read(supportHelpProvider);
    return help.maybeWhen(
      data: (data) => _stateFromHelp(data, pageSize: _defaultPageSize),
      orElse: () => const HomeCommunityFeedState.loading(),
    );
  }

  static const _defaultPageSize = 10;

  void _syncFromHelp(SupportHelpData help) {
    state = _stateFromHelp(
      help,
      pageSize: state.visibleCount.clamp(_defaultPageSize, help.faq.length),
    );
  }

  HomeCommunityFeedState _stateFromHelp(
    SupportHelpData help, {
    required int pageSize,
  }) {
    final all = help.faq.map(_mapFaq).toList();
    final visible = pageSize.clamp(0, all.length);
    return HomeCommunityFeedState(
      items: all.take(visible).toList(),
      totalCount: all.length,
      visibleCount: visible,
      fromCache: help.fromCache,
    );
  }

  Future<void> refresh() async {
    state = const HomeCommunityFeedState.loading();
    ref.invalidate(supportHelpProvider);
    await ref.read(supportHelpProvider.future);
  }

  void loadMore() {
    if (!state.hasMore) return;
    state = state.copyWith(
      visibleCount: (state.visibleCount + _defaultPageSize).clamp(
        0,
        state.totalCount,
      ),
    );
    final help = ref.read(supportHelpProvider).valueOrNull;
    if (help != null) {
      state = _stateFromHelp(help, pageSize: state.visibleCount);
    }
  }
}

class HomeCommunityFeedState {
  const HomeCommunityFeedState({
    required this.items,
    required this.totalCount,
    required this.visibleCount,
    this.fromCache = false,
    this.isLoading = false,
  });

  const HomeCommunityFeedState.loading()
    : items = const [],
      totalCount = 0,
      visibleCount = 0,
      fromCache = false,
      isLoading = true;

  final List<HomeCommunityItem> items;
  final int totalCount;
  final int visibleCount;
  final bool fromCache;
  final bool isLoading;

  bool get hasMore => visibleCount < totalCount;

  HomeCommunityFeedState copyWith({
    List<HomeCommunityItem>? items,
    int? totalCount,
    int? visibleCount,
    bool? fromCache,
    bool? isLoading,
  }) {
    return HomeCommunityFeedState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      visibleCount: visibleCount ?? this.visibleCount,
      fromCache: fromCache ?? this.fromCache,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final homeCommunityFeedProvider =
    NotifierProvider<HomeCommunityFeedNotifier, HomeCommunityFeedState>(
      HomeCommunityFeedNotifier.new,
    );
