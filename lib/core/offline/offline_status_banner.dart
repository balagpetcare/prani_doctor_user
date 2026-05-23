import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../features/home/presentation/home_navigation.dart';
import '../../features/offline/data/connectivity_service.dart';
import '../../features/offline/offline_providers.dart';
import '../network/auto_refresh_guard.dart';

/// Global offline/server-unavailable banner — shows cached data underneath.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityServiceProvider);
    final refreshState = ref.watch(autoRefreshGuardProvider);
    final l10n = AppLocalizations.of(context)!;

    final deviceOffline = !isOnlineMode(connectivity.currentMode);
    final serverDown = !refreshState.serverReachable;
    final showBanner = deviceOffline || serverDown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.offlineModeBanner,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.runWithManualRefresh(
                          () => HomeNavigation.refreshDashboard(ref),
                        );
                      },
                      child: Text(l10n.dashboardRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
