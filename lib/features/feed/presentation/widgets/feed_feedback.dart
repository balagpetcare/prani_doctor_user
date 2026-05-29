import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../shared/widgets/widgets.dart';

class FeedFeedback {
  FeedFeedback._();

  static Widget loading() => const AppLoadingView();

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppErrorView(
      message: message ?? l10n.feedLoadError,
      onRetry: onRetry,
      retryLabel: l10n.feedRetry,
    );
  }

  static Widget empty(BuildContext context, {required VoidCallback onCreate}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyView(
      icon: Icons.grass_outlined,
      message: l10n.feedEmpty,
      actionLabel: l10n.feedAddTitle,
      onAction: onCreate,
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        l10n.feedOfflineHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
