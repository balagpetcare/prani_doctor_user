import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/session/session_controller.dart';
import '../../../routing/app_routes.dart';
import '../../auth/data/auth_preferences.dart';
import '../boot_controller.dart';
import '../boot_state.dart';

class BootPage extends ConsumerStatefulWidget {
  const BootPage({super.key});

  @override
  ConsumerState<BootPage> createState() => _BootPageState();
}

class _BootPageState extends ConsumerState<BootPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bootControllerProvider.notifier).run());
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(bootControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    ref.listen(bootControllerProvider, (previous, next) {
      if (next.isReady && context.mounted) {
        final authed = ref.read(sessionControllerProvider).isAuthenticated;
        if (authed) {
          context.go(AppRoutes.home);
          return;
        }
        ref.read(authPreferencesProvider).isWelcomeSeen().then((seen) {
          if (context.mounted) {
            context.go(seen ? AppRoutes.login : AppRoutes.welcome);
          }
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _BootBody(
            boot: boot,
            l10n: l10n,
            theme: theme,
            onRetry: () => ref.read(bootControllerProvider.notifier).retry(),
            onUpdate: () => _openUpdateUrl(boot.forceUpdate?.updateUrl),
          ),
        ),
      ),
    );
  }

  Future<void> _openUpdateUrl(String? url) async {
    final target = url?.trim();
    if (target == null || target.isEmpty) return;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _BootBody extends StatelessWidget {
  const _BootBody({
    required this.boot,
    required this.l10n,
    required this.theme,
    required this.onRetry,
    required this.onUpdate,
  });

  final BootState boot;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onRetry;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pets, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          l10n.appTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 48),
        Expanded(
          child: Center(
            child: switch (boot.phase) {
              BootPhase.forceUpdate => _ForceUpdateView(
                  boot: boot,
                  l10n: l10n,
                  onUpdate: onUpdate,
                ),
              BootPhase.error => _ErrorView(
                  message: boot.errorMessage ?? l10n.bootInitError,
                  l10n: l10n,
                  onRetry: onRetry,
                ),
              BootPhase.ready => const SizedBox.shrink(),
              _ => _LoadingView(boot: boot, l10n: l10n),
            },
          ),
        ),
        if (boot.configFromCache && boot.config != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.bootOfflineConfig,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.boot, required this.l10n});

  final BootState boot;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final message = switch (boot.phase) {
      BootPhase.splash => l10n.bootSplash,
      BootPhase.initializing => l10n.bootInitializing,
      BootPhase.checkingUpdate => l10n.bootCheckingUpdate,
      BootPhase.restoringSession => l10n.bootRestoringSession,
      _ => l10n.bootInitializing,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center),
        if (boot.config != null && !boot.config!.hasSupportContacts) ...[
          const SizedBox(height: 12),
          Text(
            l10n.bootConfigEmpty,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.l10n,
    required this.onRetry,
  });

  final String message;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.bootRetry),
        ),
      ],
    );
  }
}

class _ForceUpdateView extends StatelessWidget {
  const _ForceUpdateView({
    required this.boot,
    required this.l10n,
    required this.onUpdate,
  });

  final BootState boot;
  final AppLocalizations l10n;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final info = boot.forceUpdate!;
    final hasUrl = info.updateUrl != null && info.updateUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.system_update_alt,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.bootForceUpdateTitle,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(info.message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          l10n.bootForceUpdateVersion(
            info.currentVersion,
            info.minimumVersion,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (hasUrl)
          FilledButton.icon(
            onPressed: onUpdate,
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.bootUpdateNow),
          )
        else
          Text(l10n.bootUpdateUnavailable, textAlign: TextAlign.center),
      ],
    );
  }
}
