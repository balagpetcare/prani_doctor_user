import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../routing/app_routes.dart';
import '../../app_config/presentation/app_config_provider.dart';
import 'settings_providers.dart';
import 'widgets/settings_section_header.dart';

class SettingsAboutPage extends ConsumerStatefulWidget {
  const SettingsAboutPage({super.key});

  @override
  ConsumerState<SettingsAboutPage> createState() => _SettingsAboutPageState();
}

class _SettingsAboutPageState extends ConsumerState<SettingsAboutPage> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(appConfigProvider);
    final legal = ref.watch(settingsProvider).valueOrNull?.legal;
    final version = _info?.version ?? '—';
    final build = _info?.buildNumber ?? '—';

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsAboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text('${l10n.settingsVersionLabel} $version ($build)'),
          ),
          if (config?.supportPhone?.isNotEmpty == true) ...[
            SettingsSectionHeader(title: l10n.settingsAboutSupportTitle),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(config!.supportPhone!),
              onTap: () => launchUrl(Uri.parse('tel:${config.supportPhone}')),
            ),
          ],
          SettingsSectionHeader(title: l10n.settingsAboutLegalTitle),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            subtitle: legal?.privacyAccepted == true
                ? Text(l10n.settingsAccepted)
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsPrivacy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsTermsTitle),
            subtitle: legal?.termsAccepted == true
                ? Text(l10n.settingsAccepted)
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsTerms),
          ),
        ],
      ),
    );
  }
}
