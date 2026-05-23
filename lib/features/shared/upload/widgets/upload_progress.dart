import 'package:flutter/material.dart';

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
                  ? 'Validating…'
                  : 'Uploading…',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
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
              Text('Upload complete', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
        if (state == UploadTaskState.error && errorMessage != null) ...[
          Text(errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
          if (onRetry != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onRetry, child: const Text('Retry')),
            ),
        ],
        if (state == UploadTaskState.cancelled) ...[
          Text('Upload cancelled', style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
