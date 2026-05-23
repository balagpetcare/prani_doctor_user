import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/network/network_service.dart';
import 'widgets/settings_feedback.dart';

class ConnectionCheckPage extends ConsumerStatefulWidget {
  const ConnectionCheckPage({super.key});

  @override
  ConsumerState<ConnectionCheckPage> createState() =>
      _ConnectionCheckPageState();
}

class _ConnectionCheckPageState extends ConsumerState<ConnectionCheckPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(networkDiagnosticsProvider.notifier).runChecks(),
    );
  }

  String _probeTitle(AppLocalizations l10n, NetworkProbeKind kind) =>
      switch (kind) {
        NetworkProbeKind.apiLive => l10n.networkProbeLive,
        NetworkProbeKind.appConfig => l10n.networkProbeAppConfig,
        NetworkProbeKind.authProfile => l10n.networkProbeAuth,
        NetworkProbeKind.refreshToken => l10n.networkProbeRefresh,
        NetworkProbeKind.uploadEndpoint => l10n.networkProbeUpload,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final env = ref.watch(appEnvProvider);
    final diagnosticsAsync = ref.watch(networkDiagnosticsProvider);
    final running = diagnosticsAsync.isLoading;

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.networkConnectionTitle)),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(networkDiagnosticsProvider.notifier).runChecks(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              l10n.networkConnectionSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _ConfigTile(label: l10n.networkApiUrlLabel, value: env.apiBaseUrl),
            _ConfigTile(
              label: l10n.networkApiSourceLabel,
              value: env.apiUrlSourceLabel,
            ),
            _ConfigTile(
              label: l10n.networkApiPortLabel,
              value: '${env.apiPort}',
            ),
            _ConfigTile(label: l10n.networkWebUrlLabel, value: env.webBaseUrl),
            _ConfigTile(
              label: l10n.networkTimeoutLabel,
              value:
                  '${env.connectTimeout.inSeconds}s / ${env.receiveTimeout.inSeconds}s',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: running
                        ? null
                        : () => ref
                              .read(networkDiagnosticsProvider.notifier)
                              .runChecks(),
                    icon: const Icon(Icons.network_check),
                    label: Text(l10n.networkRunChecks),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: running
                        ? null
                        : () => ref
                              .read(networkDiagnosticsProvider.notifier)
                              .runChecks(reconnect: true),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.networkReconnect),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            diagnosticsAsync.when(
              loading: SettingsFeedback.loading,
              error: (e, _) => SettingsFeedback.error(
                context,
                error: e,
                onRetry: () =>
                    ref.read(networkDiagnosticsProvider.notifier).runChecks(),
              ),
              data: (diagnostics) {
                if (diagnostics == null) {
                  return Text(l10n.networkChecksPending);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.networkLastChecked}: '
                      '${DateFormat.jms().format(diagnostics.checkedAt.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (!diagnostics.deviceOnline) ...[
                      const SizedBox(height: 8),
                      SettingsFeedback.offlineHint(context),
                    ],
                    const SizedBox(height: 12),
                    for (final probe in diagnostics.probes)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            probe.success
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: probe.success
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          title: Text(_probeTitle(l10n, probe.kind)),
                          subtitle: Text(probe.message ?? ''),
                          trailing: Text('${probe.latencyMs}ms'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  const _ConfigTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
