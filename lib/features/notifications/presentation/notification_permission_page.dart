import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import 'package:url_launcher/url_launcher.dart';

import '../notification_service.dart';
import '../push_registration.dart';
import 'widgets/notification_feedback.dart';

class NotificationPermissionPage extends ConsumerStatefulWidget {
  const NotificationPermissionPage({super.key});

  @override
  ConsumerState<NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends ConsumerState<NotificationPermissionPage> {
  NotificationPermissionStatus? _status;
  bool _loading = true;
  bool _requesting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadStatus);
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await ref
          .read(notificationServiceProvider)
          .getPermissionStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      final status = await ref
          .read(notificationServiceProvider)
          .requestPermission();
      if (!mounted) return;
      setState(() {
        _status = status;
        _requesting = false;
      });
      if (status.isGranted) {
        await ref.read(pushRegistrationProvider).register();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.notificationPermissionGranted,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _requesting = false;
      });
    }
  }

  Future<void> _openSystemSettings() async {
    final info = await PackageInfo.fromPlatform();
    final uri = Uri.parse('package:${info.packageName}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    final fallback = Uri.parse('app-settings:');
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _status;

    return Scaffold(
      appBar: safeAppBar(
        context,
        title: Text(l10n.notificationPermissionTitle),
      ),
      body: _loading
          ? NotificationFeedback.loading()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Icon(
                  status?.isGranted == true
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _statusLabel(l10n, status),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.notificationPermissionBody,
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _requesting ? null : _requestPermission,
                  child: _requesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.notificationPermissionRequest),
                ),
                const SizedBox(height: 8),
                if (status?.isDenied == true ||
                    status?.isPermanentlyDenied == true)
                  OutlinedButton(
                    onPressed: _openSystemSettings,
                    child: Text(l10n.notificationPermissionOpenSettings),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadStatus,
                  child: Text(l10n.notificationRetry),
                ),
              ],
            ),
    );
  }

  String _statusLabel(
    AppLocalizations l10n,
    NotificationPermissionStatus? status,
  ) {
    if (status == null) return l10n.notificationPermissionUnknown;
    if (status.isGranted) return l10n.notificationPermissionGrantedStatus;
    if (status.isPermanentlyDenied) {
      return l10n.notificationPermissionDeniedPermanent;
    }
    if (status.isDenied) return l10n.notificationPermissionDenied;
    return l10n.notificationPermissionUnknown;
  }
}
