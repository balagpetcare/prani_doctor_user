import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/emergency_limitation_dto.dart';
import '../emergency_limitation_providers.dart';

class EmergencyLimitationBanner extends ConsumerWidget {
  const EmergencyLimitationBanner({
    super.key,
    this.context,
    this.fallback,
    this.urgent = false,
  });

  final EmergencyLimitationContext? context;
  final String? fallback;
  final bool urgent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = urgent
        ? ref.watch(emergencyLimitationUrgentTextProvider)
        : this.context == null
        ? ref.watch(emergencyLimitationBannerTextProvider)
        : ref.watch(emergencyLimitationContextualProvider(this.context!));

    final display = (text != null && text.isNotEmpty) ? text : fallback;
    if (display == null || display.isEmpty) return const SizedBox.shrink();

    return Card(
      color: urgent
          ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              urgent ? Icons.emergency_outlined : Icons.info_outline,
              size: 20,
              color: urgent ? Theme.of(context).colorScheme.error : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(display, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showEmergencyLimitationAcceptSheet(
  BuildContext context,
  WidgetRef ref, {
  required EmergencyLimitationAcceptSurface surface,
  EmergencyLimitationContext? contextualHint,
  bool urgentHighlight = false,
}) async {
  final bundle = ref.read(emergencyLimitationProvider).valueOrNull;
  if (bundle == null) return false;

  final locale = ref.read(emergencyLimitationLocaleProvider);
  final hint = contextualHint != null
      ? bundle.contextualFor(contextualHint, locale)
      : null;
  final fullText = bundle.full.forLocale(locale);
  final urgentText = urgentHighlight ? bundle.urgentForLocale(locale) : null;

  var accepted = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: !bundle.enforceAcceptance,
    enableDrag: !bundle.enforceAcceptance,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bundle.title.isNotEmpty
                    ? bundle.title
                    : 'Emergency Service Limitation Notice',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (urgentText != null && urgentText.isNotEmpty) ...[
                Text(
                  urgentText,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (hint != null && hint.isNotEmpty) ...[
                Text(hint, style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],
              Flexible(
                child: SingleChildScrollView(child: Text(fullText)),
              ),
              const SizedBox(height: 16),
              if (!bundle.enforceAcceptance)
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Not now'),
                ),
              if (!bundle.enforceAcceptance) const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  final ok = await ref
                      .read(emergencyLimitationProvider.notifier)
                      .accept(surface);
                  if (!ctx.mounted) return;
                  if (ok) {
                    accepted = true;
                    Navigator.of(ctx).pop();
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Could not save acceptance')),
                    );
                  }
                },
                child: const Text('I understand — continue'),
              ),
            ],
          ),
        ),
      );
    },
  );
  return accepted || !(bundle.enforceAcceptance && bundle.acceptanceRequired);
}
