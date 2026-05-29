import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../shared/widgets/widgets.dart';

class FarmFeedback {
  FarmFeedback._();

  static Widget loading() => const AppLoadingView();

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppErrorView(
      message: message ?? l10n.farmLoadError,
      onRetry: onRetry,
      retryLabel: l10n.farmRetry,
    );
  }

  static Widget empty(BuildContext context, {required VoidCallback onCreate}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyView(
      icon: Icons.agriculture_outlined,
      message: l10n.farmEmpty,
      actionLabel: l10n.farmCreateTitle,
      onAction: onCreate,
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        l10n.farmOfflineHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  static Widget banner(BuildContext context, String message) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message),
    );
  }
}
