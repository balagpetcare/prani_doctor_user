import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/localization/app_date_format.dart';
import '../../../core/navigation/navigation_guard.dart';

import '../../offline/data/sync_coordinator.dart';
import '../../offline/offline_providers.dart';
import '../../offline/presentation/offline_queue_panel.dart';
import '../data/settings_repository.dart';
import 'settings_navigation.dart';
import 'settings_providers.dart';
import 'widgets/settings_feedback.dart';

class SettingsDataSyncPage extends ConsumerWidget {
  const SettingsDataSyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);
    final lastSync = ref.watch(settingsLastSyncProvider);
    final pendingAsync = ref.watch(settingsPendingSyncCountProvider);
    final updating = ref.watch(settingsUpdateInFlightProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsDataSyncTitle)),
      body: settingsAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => SettingsFeedback.error(
          context,
          error: e,
          onRetry: () => ref.read(settingsProvider.notifier).refresh(),
        ),
        data: (bundle) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(settingsProvider.notifier).refresh();
              await ref.read(settingsRepositoryProvider).syncPending();
              SettingsNavigation.afterSync(ref);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (bundle?.fromCache == true)
                  SettingsFeedback.offlineHint(context),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsLastSyncTitle),
                  subtitle: Text(
                    lastSync != null
                        ? ref.watch(appDateFormatProvider).dateTime(lastSync)
                        : l10n.settingsLastSyncNever,
                  ),
                ),
                pendingAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (count) {
                    if (count == 0) return const SizedBox.shrink();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: Text(l10n.settingsPendingSettingsCount(count)),
                    );
                  },
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: updating
                      ? null
                      : () async {
                          await ref
                              .read(settingsRepositoryProvider)
                              .syncPending();
                          await ref
                              .read(syncCoordinatorProvider)
                              .syncNow(foreground: true);
                          SettingsNavigation.afterSync(ref);
                          ref.invalidate(offlineSyncStatusProvider);
                        },
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.syncNow),
                ),
                const SizedBox(height: 16),
                const OfflineQueuePanel(),
              ],
            ),
          );
        },
      ),
    );
  }
}
