import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import 'livestock_providers.dart';
import 'widgets/livestock_feedback.dart';

class LivestockTimelinePage extends ConsumerWidget {
  const LivestockTimelinePage({super.key, required this.livestockId});

  final String livestockId;

  IconData _iconForType(String type) {
    switch (type) {
      case 'vaccine':
        return Icons.vaccines_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'feed':
        return Icons.grass_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final timelineAsync = ref.watch(livestockTimelineProvider(livestockId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(TranslationKeys.animalTimelineTitle)),
      ),
      body: timelineAsync.when(
        loading: LivestockFeedback.loading,
        error: (e, _) => LivestockFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(livestockTimelineProvider(livestockId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(l10n.t(TranslationKeys.animalNoHistory)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(_iconForType(item.type)),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: Text(
                  item.occurredAt.length >= 10
                      ? item.occurredAt.substring(0, 10)
                      : item.occurredAt,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LivestockQrPage extends ConsumerWidget {
  const LivestockQrPage({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final detailAsync = ref.watch(livestockDetailProvider(livestockId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.animalQrCode))),
      body: detailAsync.when(
        loading: LivestockFeedback.loading,
        error: (e, _) => LivestockFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(livestockDetailProvider(livestockId)),
        ),
        data: (profile) {
          final payload = profile.qrCodePayload ??
              profile.earTagNumber ??
              profile.id;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.qr_code_2, size: 120, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (profile.earTagNumber != null)
                  Text(
                    l10n.t(
                      TranslationKeys.animalTagLabel,
                      {'tag': profile.earTagNumber!},
                    ),
                  ),
                const SizedBox(height: 24),
                SelectableText(
                  payload,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: payload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.t(TranslationKeys.animalQrCopied)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.t(TranslationKeys.animalQrCopy)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
