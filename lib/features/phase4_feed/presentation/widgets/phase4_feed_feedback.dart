import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/translation_keys.dart';
import '../../../../shared/widgets/widgets.dart';

class Phase4FeedFeedback {
  Phase4FeedFeedback._();

  static Widget loading() => const AppLoadingView();

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = context.tr;
    return AppErrorView(
      message: message ?? l10n.t(TranslationKeys.phase4FeedLoadError),
      onRetry: onRetry,
      retryLabel: l10n.t(TranslationKeys.retryLabel),
    );
  }

  static Widget offlineHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        context.tr.t(TranslationKeys.phase4FeedOfflineHint),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
