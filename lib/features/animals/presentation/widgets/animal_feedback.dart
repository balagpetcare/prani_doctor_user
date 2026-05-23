import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

class AnimalFeedback {
  AnimalFeedback._();

  static Widget loading() => const Center(child: CircularProgressIndicator());

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message ?? l10n.animalLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.animalRetry)),
          ],
        ),
      ),
    );
  }

  static Widget empty(BuildContext context, {required VoidCallback onCreate}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets_outlined, size: 48),
            const SizedBox(height: 16),
            Text(l10n.animalEmpty, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onCreate, child: Text(l10n.animalAddTitle)),
          ],
        ),
      ),
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        l10n.animalOfflineHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
