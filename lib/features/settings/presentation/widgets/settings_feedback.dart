import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/error/http_error_mapper.dart';

abstract final class SettingsFeedback {
  static Widget loading() => const Center(child: CircularProgressIndicator());

  static Widget error(
    BuildContext context, {
    Object? error,
    required VoidCallback onRetry,
  }) {
    if (kDebugMode && error != null) {
      HttpErrorMapper.logDeveloper(error, tag: 'SETTINGS');
    }
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
            Text(
              error != null
                  ? HttpErrorMapper.settingsErrorTitle(error)
                  : HttpErrorMapper.settingsLoadTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error != null
                  ? HttpErrorMapper.settingsErrorMessage(error)
                  : HttpErrorMapper.genericSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.settingsRetry)),
          ],
        ),
      ),
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      content: Text(l10n.settingsOfflineHint),
      actions: const [SizedBox.shrink()],
    );
  }
}
