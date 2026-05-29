import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../data/ai_disclaimer_dto.dart';
import '../ai_disclaimer_providers.dart';
import '../ai_escalation_disclosure_providers.dart';
import '../../../emergency_limitation/presentation/emergency_limitation_providers.dart';

/// Ensures AI disclaimer acceptance before showing [child].
class AiDisclaimerGate extends ConsumerStatefulWidget {
  const AiDisclaimerGate({
    super.key,
    required this.child,
    required this.surface,
  });

  final Widget child;
  final AiDisclaimerAcceptSurface surface;

  @override
  ConsumerState<AiDisclaimerGate> createState() => _AiDisclaimerGateState();
}

class _AiDisclaimerGateState extends ConsumerState<AiDisclaimerGate> {
  bool _promptShown = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_maybePrompt);
  }

  Future<void> _maybePrompt() async {
    if (_promptShown || !mounted) return;
    await Future.wait([
      ref.read(aiDisclaimerProvider.future),
      ref.read(aiEscalationDisclosureProvider.future),
      ref.read(emergencyLimitationProvider.future),
    ]);
    if (!mounted) return;
    if (!ref.read(aiDisclaimerAcceptanceRequiredProvider)) return;
    _promptShown = true;
    await _showConsentSheet();
  }

  Future<void> _showConsentSheet() async {
    final bundle = ref.read(aiDisclaimerProvider).valueOrNull;
    if (bundle == null || !mounted) return;
    final locale = ref.read(aiDisclaimerLocaleProvider);
    final fullText = bundle.full.forLocale(locale);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  bundle.title.isNotEmpty ? bundle.title : 'AI Disclaimer',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(child: Text(fullText)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (context.mounted) context.pop();
                  },
                  child: const Text('Not now'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(aiDisclaimerProvider.notifier)
                        .accept(widget.surface);
                    if (!ctx.mounted) return;
                    if (ok) {
                      Navigator.of(ctx).pop();
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Could not save acceptance'),
                        ),
                      );
                    }
                  },
                  child: const Text('I understand — continue'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final required = ref.watch(aiDisclaimerAcceptanceRequiredProvider);
    if (required) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Assistant')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Review the AI disclaimer to use this feature.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _showConsentSheet,
                  child: const Text('Review disclaimer'),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.settingsAiConsent),
                  child: const Text('Open full disclaimer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
