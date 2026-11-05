import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../theme/home_tokens.dart';

/// Fallback when home dashboard content fails to build or load.
class HomeLoadFailureView extends StatelessWidget {
  const HomeLoadFailureView({
    super.key,
    required this.onRetry,
    this.message,
  });

  final VoidCallback onRetry;
  final String? message;

  static const defaultMessageBn = 'ডেটা লোড করতে সমস্যা হয়েছে';
  static const defaultRetryLabelBn = 'পুনরায় চেষ্টা করুন';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(HomeTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: HomeTokens.space16),
                Text(
                  message ?? defaultMessageBn,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: HomeTokens.space8),
                Text(
                  l10n.dashboardLoadError,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: HomeTokens.space24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(defaultRetryLabelBn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
