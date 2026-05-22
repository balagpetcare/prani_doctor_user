import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

class AreaFeedback {
  AreaFeedback._();

  static Widget loading() => const LinearProgressIndicator();

  static Widget empty(BuildContext context, {required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  static Widget error(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        TextButton(onPressed: onRetry, child: Text(l10n.areaRetry)),
      ],
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        l10n.areaOfflineHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
