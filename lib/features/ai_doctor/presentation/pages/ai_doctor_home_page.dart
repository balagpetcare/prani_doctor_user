import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../../ai/presentation/widgets/ai_disclaimer_gate.dart';
import '../../../ai/data/ai_disclaimer_dto.dart';
import '../../data/ai_doctor_dto.dart';
import '../../data/ai_doctor_repository.dart';
import '../providers/ai_doctor_providers.dart';

class AiDoctorHomePage extends ConsumerWidget {
  const AiDoctorHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(aiDoctorHistoryProvider);
    final activeIdAsync = ref.watch(aiDoctorActiveCaseIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doctor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(AppRoutes.aiDoctorHistory),
          ),
        ],
      ),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'আপনার প্রাণীর লক্ষণ যাচাই ও পরামর্শ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'এটি চিকিৎসা নির্ণয় নয়। জরুরি হলে স্থানীয় ভেটের সাথে যোগাযোগ করুন।',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            activeIdAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (activeId) {
                if (activeId == null) return const SizedBox.shrink();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.medical_services_outlined),
                    title: const Text('সক্রিয় কেস'),
                    subtitle: Text('কেস #$activeId'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _resumeCase(context, ref, activeId),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.aiDoctorCaseNew),
              icon: const Icon(Icons.add),
              label: const Text('নতুন কেস শুরু করুন'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.aiSymptomChecker),
              icon: const Icon(Icons.medical_information_outlined),
              label: const Text('দ্রুত লক্ষণ যাচাই'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/ai/legacy-home'),
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('সাধারণ AI হাব'),
            ),
            const SizedBox(height: 24),
            Text(
              'সাম্প্রতিক কেস',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('লোড ব্যর্থ: $e'),
              data: (cases) {
                if (cases.isEmpty) {
                  return const Text('এখনও কোনো কেস নেই');
                }
                return Column(
                  children: [
                    for (final aiCase in cases.take(10))
                      Card(
                        child: ListTile(
                          title: Text(apiSpeciesLabelBn(
                            livestockSpeciesToApi(aiCase.species),
                          )),
                          subtitle: Text(
                            '${aiCase.state.name} · ${aiCase.updatedAt ?? aiCase.createdAt ?? ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _resumeCase(context, ref, aiCase.id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resumeCase(
    BuildContext context,
    WidgetRef ref,
    String caseId,
  ) async {
    final result = await ref.read(aiDoctorRepositoryProvider).getCase(caseId);
    if (!context.mounted) return;
    result.when(
      success: (aiCase) {
        final segment = routeForCaseState(aiCase);
        context.push(AppRoutes.aiDoctorCase(caseId, segment));
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }
}

/// Gate wrapper for AI Doctor routes.
class AiDoctorDisclaimerGate extends StatelessWidget {
  const AiDoctorDisclaimerGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AiDisclaimerGate(
      surface: AiDisclaimerAcceptSurface.aiAdvisory,
      child: child,
    );
  }
}
