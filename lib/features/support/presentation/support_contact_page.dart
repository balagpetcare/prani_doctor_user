import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';


import 'package:url_launcher/url_launcher.dart';

import '../../../routing/app_routes.dart';
import 'support_providers.dart';
import 'widgets/support_feedback.dart';

class SupportContactPage extends ConsumerWidget {
  const SupportContactPage({super.key});

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _launchWhatsapp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(
      Uri.parse('https://wa.me/${digits.replaceAll('+', '')}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final helpAsync = ref.watch(supportHelpProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportContactTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.supportTicketCreate),
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: helpAsync.when(
        loading: SupportFeedback.loading,
        error: (e, _) => SupportFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(supportHelpProvider),
        ),
        data: (help) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (help.fromCache) SupportFeedback.offlineHint(context),
              Text(
                l10n.supportContactBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (help.contact.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(l10n.supportCallSupport),
                  subtitle: Text(help.contact.phone!),
                  onTap: () => _launchPhone(help.contact.phone),
                ),
              if (help.contact.whatsapp != null)
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: Text(l10n.supportWhatsappSupport),
                  subtitle: Text(help.contact.whatsapp!),
                  onTap: () => _launchWhatsapp(help.contact.whatsapp),
                ),
              if (help.contact.email != null)
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n.supportEmailSupport),
                  subtitle: Text(help.contact.email!),
                  onTap: () =>
                      launchUrl(Uri.parse('mailto:${help.contact.email}')),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push(AppRoutes.supportTicketCreate),
                child: Text(l10n.supportCreateTicket),
              ),
            ],
          );
        },
      ),
    );
  }
}
