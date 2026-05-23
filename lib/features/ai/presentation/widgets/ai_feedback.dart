import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

abstract final class AiFeedback {
  static Widget loading() => const Center(child: CircularProgressIndicator());

  static Widget skeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: index.isEven
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: 220,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget empty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.aiEmptyState, textAlign: TextAlign.center),
      ),
    );
  }

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
            FilledButton(onPressed: onRetry, child: Text(l10n.aiRetry)),
          ],
        ),
      ),
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      content: Text(l10n.aiOfflineHint),
      actions: const [SizedBox.shrink()],
    );
  }

  static Widget permissionDenied(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.aiMicPermissionDenied, textAlign: TextAlign.center),
      ),
    );
  }
}
