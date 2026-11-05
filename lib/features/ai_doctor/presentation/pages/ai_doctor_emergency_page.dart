import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../providers/ai_doctor_providers.dart';
import '../widgets/risk_banner.dart';

class AiDoctorEmergencyPage extends ConsumerWidget {
  const AiDoctorEmergencyPage({super.key, required this.caseId});

  final String caseId;

  Future<void> _callEmergency(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '999');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কল করা যায়নি')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(aiDoctorCaseProvider(caseId));
    final analysis = caseAsync.valueOrNull?.lastAnalysis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('জরুরি সতর্কতা'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: caseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (viewState) {
            final risk = analysis?.riskAssessment ??
                viewState.aiCase?.riskAssessment;
            if (risk == null) {
              return const Center(child: Text('ঝুঁকি তথ্য লোড ব্যর্থ'));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.emergency, size: 48, color: Colors.red.shade800),
                        const SizedBox(height: 12),
                        Text(
                          'এটি জরুরি পরিস্থিতি',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI চিকিৎসা নির্ণয় দেয় না। '
                          'অবিলম্বে স্থানীয় ভেটের সাথে যোগাযোগ করুন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                RiskBanner(risk: risk),
                if (analysis != null && analysis.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(analysis.content),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: () => _callEmergency(context),
                  icon: const Icon(Icons.phone),
                  label: const Text('জরুরি কল (৯৯৯)'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.aiDoctorCaseHandoff(caseId)),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('ভেটে হস্তান্তর'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push(AppRoutes.services),
                  child: const Text('কাছের ভেট/সেবা খুঁজুন'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
