import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

abstract final class SupportFeedback {
  static Widget loading() => const Center(child: CircularProgressIndicator());

  static Widget error(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.supportRetry)),
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
            Text(l10n.supportEmpty, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: Text(l10n.supportCreateTicket),
            ),
          ],
        ),
      ),
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      content: Text(l10n.supportOfflineHint),
      actions: const [SizedBox.shrink()],
    );
  }

  static Widget submissionOverlay(
    BuildContext context, {
    required String message,
  }) {
    return ColoredBox(
      color: Colors.black26,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
