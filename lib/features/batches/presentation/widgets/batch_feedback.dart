import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../shared/widgets/widgets.dart';

class BatchFeedback {
  BatchFeedback._();

  static Widget loading() => const AppLoadingView();

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppErrorView(
      message: message ?? l10n.batchLoadError,
      onRetry: onRetry,
      retryLabel: l10n.batchRetry,
    );
  }

  static Widget empty(BuildContext context, {required VoidCallback onCreate}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyView(
      icon: Icons.groups_outlined,
      message: l10n.batchEmpty,
      actionLabel: l10n.batchAddTitle,
      onAction: onCreate,
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        l10n.batchOfflineHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
