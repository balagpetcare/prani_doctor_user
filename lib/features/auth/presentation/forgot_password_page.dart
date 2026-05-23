import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../routing/app_routes.dart';
import '../../app_config/presentation/app_config_provider.dart';
import 'widgets/auth_feedback.dart';

/// Password reset UI — backend endpoint not available; routes to support.
class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  Future<void> _callSupport(BuildContext context, String? phone) async {
    final target = phone?.trim();
    if (target == null || target.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: target);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(appConfigProvider);
    final supportPhone = config?.supportPhone ?? config?.emergencyPhone;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.forgotPasswordBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (supportPhone != null && supportPhone.isNotEmpty) ...[
              FilledButton.icon(
                onPressed: () => _callSupport(context, supportPhone),
                icon: const Icon(Icons.phone),
                label: Text(l10n.forgotPasswordCallSupport),
              ),
              const SizedBox(height: 12),
              AuthEmptyHint(message: supportPhone),
            ] else ...[
              AuthErrorBanner(message: l10n.forgotPasswordUnavailable),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text(l10n.loginLink),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.otp),
              child: Text(l10n.forgotPasswordUseOtp),
            ),
          ],
        ),
      ),
    );
  }
}
