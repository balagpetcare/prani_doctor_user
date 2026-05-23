import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';
import '../notification_analytics.dart';
import '../data/notification_dto.dart';
import '../data/notification_repository.dart';
import 'notification_navigation.dart';
import 'notification_providers.dart';
import 'widgets/notification_feedback.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  NotificationSettingsDto? _draft;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(notificationRepositoryProvider)
        .saveSettings(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        NotificationAnalytics.settingsSaved();
        NotificationNavigation.afterSettingsSave(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.notificationSettingsSaved,
            ),
          ),
        );
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.notificationSettingsTitle)),
      body: settingsAsync.when(
        loading: NotificationFeedback.loading,
        error: (e, _) => NotificationFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationSettingsProvider),
        ),
        data: (settings) {
          _draft ??= settings;
          final draft = _draft!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (settings.fromCache) NotificationFeedback.offlineHint(context),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SwitchListTile(
                title: Text(l10n.notificationPushToggle),
                subtitle: Text(l10n.notificationPushToggleHint),
                value: draft.pushEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                        () => _draft = draft.copyWith(pushEnabled: v),
                      ),
              ),
              ListTile(
                title: Text(l10n.notificationPermissionTitle),
                subtitle: Text(l10n.notificationPermissionBody),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.notificationPermission),
              ),
              SwitchListTile(
                title: Text(l10n.notificationMarketingToggle),
                value: draft.marketingEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                        () => _draft = draft.copyWith(marketingEnabled: v),
                      ),
              ),
              SwitchListTile(
                title: Text(l10n.notificationTreatmentReminderToggle),
                value: draft.treatmentReminderEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                        () => _draft = draft.copyWith(
                          treatmentReminderEnabled: v,
                        ),
                      ),
              ),
              SwitchListTile(
                title: Text(l10n.notificationVaccineReminderToggle),
                value: draft.vaccineReminderEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                        () =>
                            _draft = draft.copyWith(vaccineReminderEnabled: v),
                      ),
              ),
              SwitchListTile(
                title: Text(l10n.notificationOrderServiceToggle),
                value: draft.orderServiceEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                        () => _draft = draft.copyWith(orderServiceEnabled: v),
                      ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.notificationSaveSettings),
              ),
            ],
          );
        },
      ),
    );
  }
}
