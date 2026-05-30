import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/translation_keys.dart';
import '../../../../shared/widgets/widgets.dart';

class LivestockFeedback {
  LivestockFeedback._();

  static Widget loading() => const AppLoadingView();

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = context.tr;
    return AppErrorView(
      message: message ?? l10n.t(TranslationKeys.animalLoadError),
      onRetry: onRetry,
      retryLabel: l10n.t(TranslationKeys.retryLabel),
    );
  }

  static Widget empty(BuildContext context, {required VoidCallback onCreate}) {
    final l10n = context.tr;
    return AppEmptyView(
      icon: Icons.pets_outlined,
      message: l10n.t(TranslationKeys.animalEmpty),
      actionLabel: l10n.t(TranslationKeys.animalAddTitle),
      onAction: onCreate,
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = context.tr;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        l10n.t(TranslationKeys.animalOfflineHint),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
