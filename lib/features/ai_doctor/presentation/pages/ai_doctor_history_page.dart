import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../data/ai_doctor_dto.dart';
import '../../data/ai_doctor_repository.dart';
import '../providers/ai_doctor_providers.dart';

class AiDoctorHistoryPage extends ConsumerWidget {
  const AiDoctorHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(aiDoctorHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Doctor ইতিহাস')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (cases) {
            if (cases.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('কোনো কেস নেই'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push(AppRoutes.aiDoctorCaseNew),
                      child: const Text('নতুন কেস'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final aiCase = cases[index];
                return Card(
                  child: ListTile(
                    leading: Icon(_iconForState(aiCase.state)),
                    title: Text(
                      apiSpeciesLabelBn(livestockSpeciesToApi(aiCase.species)),
                    ),
                    subtitle: Text(
                      '${_stateLabel(aiCase.state)} · ${aiCase.updatedAt ?? aiCase.createdAt ?? ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openCase(context, ref, aiCase.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconForState(AiDoctorCaseStateEnum state) {
    switch (state) {
      case AiDoctorCaseStateEnum.emergencyTriage:
        return Icons.emergency;
      case AiDoctorCaseStateEnum.escalated:
        return Icons.support_agent;
      case AiDoctorCaseStateEnum.responseDelivered:
        return Icons.check_circle_outline;
      default:
        return Icons.medical_information_outlined;
    }
  }

  String _stateLabel(AiDoctorCaseStateEnum state) {
    switch (state) {
      case AiDoctorCaseStateEnum.created:
        return 'তৈরি';
      case AiDoctorCaseStateEnum.intake:
        return 'ইনটেক';
      case AiDoctorCaseStateEnum.awaitingClarification:
        return 'আরও তথ্য';
      case AiDoctorCaseStateEnum.emergencyTriage:
        return 'জরুরি';
      case AiDoctorCaseStateEnum.analyzing:
        return 'বিশ্লেষণ';
      case AiDoctorCaseStateEnum.responseDelivered:
        return 'ফলাফল';
      case AiDoctorCaseStateEnum.blocked:
        return 'ব্লক';
      case AiDoctorCaseStateEnum.escalated:
        return 'হস্তান্তর';
      case AiDoctorCaseStateEnum.closed:
        return 'বন্ধ';
    }
  }

  Future<void> _openCase(
    BuildContext context,
    WidgetRef ref,
    String caseId,
  ) async {
    final result = await ref.read(aiDoctorRepositoryProvider).getCase(caseId);
    if (!context.mounted) return;
    result.when(
      success: (aiCase) {
        context.push(AppRoutes.aiDoctorCase(caseId, routeForCaseState(aiCase)));
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }
}
