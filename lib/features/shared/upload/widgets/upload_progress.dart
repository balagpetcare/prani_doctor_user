import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/translation_keys.dart';
import '../models/upload_result.dart';

class UploadProgress extends StatelessWidget {
  const UploadProgress({
    super.key,
    this.progress,
    this.state = UploadTaskState.idle,
    this.errorMessage,
    this.onRetry,
    this.onCancel,
    this.showLabel = true,
  });

  final double? progress;
  final UploadTaskState state;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final theme = Theme.of(context);

    if (state == UploadTaskState.idle) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state == UploadTaskState.uploading ||
            state == UploadTaskState.validating) ...[
          LinearProgressIndicator(value: progress),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              state == UploadTaskState.validating
                  ? l10n.t('Validating…')
                  : l10n.profileUploading,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ],
        if (state == UploadTaskState.success) ...[
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(l10n.t('uploadComplete'), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
        if (state == UploadTaskState.error && errorMessage != null) ...[
          Text(errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
          if (onRetry != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRetry,
                child: Text(l10n.t(TranslationKeys.feedRetry)),
              ),
            ),
        ],
        if (state == UploadTaskState.cancelled) ...[
          Text(l10n.t('uploadCancelled'), style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
