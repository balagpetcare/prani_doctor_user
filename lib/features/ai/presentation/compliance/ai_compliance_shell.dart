import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_disclaimer_dto.dart';
import '../ai_disclaimer_providers.dart';
import '../ai_escalation_disclosure_providers.dart';
import '../widgets/ai_disclaimer_banner.dart';
import 'ai_compliance_model.dart';

/// Persistent AI limitation banner shell for AI-enabled screens.
class AiComplianceShell extends ConsumerWidget {
  const AiComplianceShell({
    super.key,
    required this.child,
    this.surface = AiComplianceSurface.chat,
    this.showEscalationAwarenessBanner = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final AiComplianceSurface surface;
  final bool showEscalationAwarenessBanner;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feature = disclaimerFeatureForSurface(surface);
    final escalationBanner = showEscalationAwarenessBanner
        ? ref.watch(aiEscalationDisclosureBannerProvider)
        : null;

    return Semantics(
      container: true,
      label: 'AI assistive guidance with limitations',
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (escalationBanner != null && escalationBanner.isNotEmpty)
              MaterialBanner(
                content: Text(escalationBanner),
                leading: const Icon(Icons.person_search_outlined),
                actions: const [SizedBox.shrink()],
              ),
            AiDisclaimerBanner(feature: feature),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Page-level scaffold wrapper: T1/T2 banner + scrollable body.
class AiCompliancePageBody extends ConsumerWidget {
  const AiCompliancePageBody({
    super.key,
    required this.surface,
    required this.child,
    this.showEscalationAwarenessBanner = false,
  });

  final AiComplianceSurface surface;
  final Widget child;
  final bool showEscalationAwarenessBanner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feature = disclaimerFeatureForSurface(surface);
    final escalationBanner = showEscalationAwarenessBanner
        ? ref.watch(aiEscalationDisclosureBannerProvider)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (escalationBanner != null && escalationBanner.isNotEmpty)
          MaterialBanner(
            content: Text(escalationBanner),
            leading: const Icon(Icons.person_search_outlined),
            actions: const [SizedBox.shrink()],
          ),
        AiDisclaimerBanner(feature: feature),
        Expanded(child: child),
      ],
    );
  }
}
