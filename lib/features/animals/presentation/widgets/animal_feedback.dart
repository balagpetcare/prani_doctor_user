import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../shared/widgets/widgets.dart';

class AnimalFeedback {
  AnimalFeedback._();

  static Widget loading() => const AppLoadingView();

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppErrorView(
      message: message ?? l10n.animalLoadError,
      onRetry: onRetry,
      retryLabel: l10n.animalRetry,
    );
  }

  static Widget empty(BuildContext context, {required VoidCallback onCreate}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyView(
      icon: Icons.pets_outlined,
      message: l10n.animalEmpty,
      actionLabel: l10n.animalAddTitle,
      onAction: onCreate,
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
