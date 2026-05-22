import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/branding/brand_assets.dart';
import '../../../core/branding/brand_image.dart';import '../boot_controller.dart';
import '../boot_navigation.dart';
import '../boot_state.dart';
import 'pages/splash_page.dart';

class BootPage extends ConsumerStatefulWidget {
  const BootPage({super.key});

  @override
  ConsumerState<BootPage> createState() => _BootPageState();
}

class _BootPageState extends ConsumerState<BootPage> {
  bool _splashAnimationDone = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bootControllerProvider.notifier).run());
  }

  void _tryNavigate(BootState boot) {
    if (!boot.isReady || !_splashAnimationDone || !mounted) return;
    resolveBootDestination(ref).then((destination) {
      if (mounted) context.go(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(bootControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(bootControllerProvider, (previous, next) => _tryNavigate(next));

    if (_splashAnimationDone) {
      _tryNavigate(boot);
    }

    final isLoadingPhase = switch (boot.phase) {
      BootPhase.forceUpdate ||
      BootPhase.optionalUpdate ||
      BootPhase.maintenance ||
      BootPhase.error =>
        false,
      BootPhase.ready => false,
      _ => true,
    };

    if (isLoadingPhase) {
      return SplashPage(
        statusMessage: _statusMessage(l10n, boot.phase),
        onAnimationComplete: () {
          if (!mounted) return;
          setState(() => _splashAnimationDone = true);
          _tryNavigate(boot);
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _BootOverlay(
            boot: boot,
            l10n: l10n,
            onRetry: () {
              setState(() => _splashAnimationDone = false);
              ref.read(bootControllerProvider.notifier).retry();
            },
            onUpdate: () => _openUpdateUrl(
              boot.forceUpdate?.updateUrl ?? boot.optionalUpdate?.updateUrl,
            ),
            onSkipOptionalUpdate: () =>
                ref.read(bootControllerProvider.notifier).skipOptionalUpdate(),
          ),
        ),
      ),
    );
  }

  String? _statusMessage(AppLocalizations l10n, BootPhase phase) {
    return switch (phase) {
      BootPhase.splash => l10n.bootSplash,
      BootPhase.initializing => l10n.bootInitializing,
      BootPhase.checkingUpdate => l10n.bootCheckingUpdate,
      BootPhase.restoringSession => l10n.bootRestoringSession,
      _ => l10n.bootInitializing,
    };
  }

  Future<void> _openUpdateUrl(String? url) async {
    final target = url?.trim();
    if (target == null || target.isEmpty) return;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _BootOverlay extends StatelessWidget {
  const _BootOverlay({
    required this.boot,
    required this.l10n,
    required this.onRetry,
    required this.onUpdate,
    required this.onSkipOptionalUpdate,
  });

  final BootState boot;
  final AppLocalizations l10n;
  final VoidCallback onRetry;
  final VoidCallback onUpdate;
  final VoidCallback onSkipOptionalUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrandImage.logo(
          asset: BrandAssets.primaryLogo,
          height: 72,
        ),        const SizedBox(height: 16),
        Text(
          BrandAssets.splashTitleBn,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
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
              BootPhase.optionalUpdate => _OptionalUpdateView(
                  boot: boot,
                  l10n: l10n,
                  onUpdate: onUpdate,
                  onLater: onSkipOptionalUpdate,
                ),
              BootPhase.maintenance => _MaintenanceView(
                  boot: boot,
                  l10n: l10n,
                  onRetry: onRetry,
                ),
              BootPhase.error => _ErrorView(
                  message: boot.errorMessage ?? l10n.bootInitError,
                  l10n: l10n,
                  onRetry: onRetry,
                ),
              _ => const SizedBox.shrink(),
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
        Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.error),
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

class _MaintenanceView extends StatelessWidget {
  const _MaintenanceView({
    required this.boot,
    required this.l10n,
    required this.onRetry,
  });

  final BootState boot;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = boot.maintenance?.message ?? l10n.bootMaintenanceDefault;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.engineering_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(l10n.bootMaintenanceTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.bootRetry)),
      ],
    );
  }
}

class _ForceUpdateView extends StatelessWidget {
  const _ForceUpdateView({required this.boot, required this.l10n, required this.onUpdate});

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
        Icon(Icons.system_update_alt, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(l10n.bootForceUpdateTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(info.message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.bootForceUpdateVersion(info.currentVersion, info.minimumVersion),
            style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (hasUrl)
          FilledButton.icon(onPressed: onUpdate, icon: const Icon(Icons.open_in_new), label: Text(l10n.bootUpdateNow))
        else
          Text(l10n.bootUpdateUnavailable, textAlign: TextAlign.center),
      ],
    );
  }
}

class _OptionalUpdateView extends StatelessWidget {
  const _OptionalUpdateView({
    required this.boot,
    required this.l10n,
    required this.onUpdate,
    required this.onLater,
  });

  final BootState boot;
  final AppLocalizations l10n;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final info = boot.optionalUpdate!;
    final hasUrl = info.updateUrl != null && info.updateUrl!.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.new_releases_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(l10n.bootOptionalUpdateTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(info.message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.bootOptionalUpdateVersion(info.currentVersion, info.recommendedVersion),
            style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (hasUrl)
          FilledButton.icon(onPressed: onUpdate, icon: const Icon(Icons.open_in_new), label: Text(l10n.bootUpdateNow)),
        const SizedBox(height: 12),
        TextButton(onPressed: onLater, child: Text(l10n.bootUpdateLater)),
      ],
    );
  }
}
