import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../routing/app_routes.dart';
import 'support_providers.dart';
import 'widgets/support_feedback.dart';

class SupportHelpPage extends ConsumerWidget {
  const SupportHelpPage({super.key});

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _launchWhatsapp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/${digits.replaceAll('+', '')}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final helpAsync = ref.watch(supportHelpProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportHelpTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.supportTickets),
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
        ],
      ),
      body: helpAsync.when(
        loading: () => SupportFeedback.loading(),
        error: (e, _) => SupportFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(supportHelpProvider),
        ),
        data: (help) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supportHelpProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (help.fromCache) SupportFeedback.offlineHint(context),
                Text(l10n.supportQuickActionsTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in help.quickActions)
                      ActionChip(
                        label: Text(action.label),
                        onPressed: () => _handleQuickAction(context, action),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(l10n.supportContactTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
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
                    onTap: () => launchUrl(Uri.parse('mailto:${help.contact.email}')),
                  ),
                const SizedBox(height: 24),
                Text(l10n.supportFaqTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...help.faq.map(
                  (item) => Card(
                    child: ExpansionTile(
                      title: Text(item.question),
                      children: [Padding(padding: const EdgeInsets.all(16), child: Text(item.answer))],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleQuickAction(BuildContext context, dynamic action) {
    switch (action.action as String) {
      case 'create_ticket':
        context.push(AppRoutes.supportTicketCreate);
      case 'view_tickets':
        context.push(AppRoutes.supportTickets);
      case 'call':
        _launchPhone(action.value as String?);
      case 'whatsapp':
        _launchWhatsapp(action.value as String?);
    }
  }
}
