import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config_provider.dart';

/// Non-blocking closed-beta notice from server `app-config.closedBeta`.
class ClosedBetaBanner extends ConsumerWidget {
  const ClosedBetaBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final beta = config?.closedBeta;
    if (beta == null || !beta.enabled) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context).languageCode;
    final message = locale.startsWith('bn')
        ? (beta.betaBannerBn ?? beta.betaBannerEn)
        : (beta.betaBannerEn ?? beta.betaBannerBn);
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.science_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
