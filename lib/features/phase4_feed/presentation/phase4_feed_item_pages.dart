import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';
import '../data/phase4_feed_dto.dart';
import 'phase4_feed_providers.dart';
import 'widgets/phase4_feed_feedback.dart';

class Phase4FeedItemListPage extends ConsumerWidget {
  const Phase4FeedItemListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final itemsAsync = ref.watch(phase4FeedItemsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.phase4FeedCatalogTitle))),
      body: itemsAsync.when(
        loading: Phase4FeedFeedback.loading,
        error: (e, _) => Phase4FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(phase4FeedItemsProvider),
        ),
        data: (page) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(phase4FeedItemsProvider);
              await ref.read(phase4FeedItemsProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: page.items.length + (page.fromCache ? 1 : 0),
              itemBuilder: (context, index) {
                if (page.fromCache && index == 0) {
                  return Phase4FeedFeedback.offlineHint(context);
                }
                final itemIndex = page.fromCache ? index - 1 : index;
                final item = page.items[itemIndex];
                return _FeedItemTile(
                  item: item,
                  onTap: () => context.push(AppRoutes.phase4FeedItemDetail(item.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FeedItemTile extends StatelessWidget {
  const _FeedItemTile({required this.item, required this.onTap});

  final Phase4FeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.displayName(preferBn: true)),
      subtitle: Text('${item.category} · ${item.defaultUnit}'),
      trailing: item.approxPriceBdt != null
          ? Text('৳${item.approxPriceBdt!.toStringAsFixed(0)}')
          : null,
      onTap: onTap,
    );
  }
}

class Phase4FeedItemDetailPage extends ConsumerWidget {
  const Phase4FeedItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final itemAsync = ref.watch(phase4FeedItemDetailProvider(itemId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.phase4FeedDetailTitle))),
      body: itemAsync.when(
        loading: Phase4FeedFeedback.loading,
        error: (e, _) => Phase4FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(phase4FeedItemDetailProvider(itemId)),
        ),
        data: (item) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.fromCache) Phase4FeedFeedback.offlineHint(context),
              Text(
                item.displayName(preferBn: true),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(item.nameEn),
              const SizedBox(height: 12),
              _Row(l10n.t(TranslationKeys.phase4FeedCategoryLabel), item.category),
              _Row(l10n.t(TranslationKeys.phase4FeedUnitLabel), item.defaultUnit),
              if (item.approxPriceBdt != null)
                _Row(
                  l10n.t(TranslationKeys.phase4FeedPriceLabel),
                  '৳${item.approxPriceBdt!.toStringAsFixed(2)}',
                ),
              if (item.nutrition?.cpPercent != null)
                _Row(
                  'CP',
                  '${item.nutrition!.cpPercent!.toStringAsFixed(1)}%',
                ),
              if (item.nutrition?.tdnPercent != null)
                _Row(
                  'TDN',
                  '${item.nutrition!.tdnPercent!.toStringAsFixed(1)}%',
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
