import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../data/ai_doctor_dto.dart';
import '../providers/ai_doctor_providers.dart';

class AiDoctorEscalationPage extends ConsumerStatefulWidget {
  const AiDoctorEscalationPage({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<AiDoctorEscalationPage> createState() =>
      _AiDoctorEscalationPageState();
}

class _AiDoctorEscalationPageState extends ConsumerState<AiDoctorEscalationPage> {
  EscalationChannel? _selected;
  bool _submitting = false;
  String? _escalationId;

  Future<void> _escalate() async {
    setState(() => _submitting = true);
    final result = await ref
        .read(aiDoctorCaseProvider(widget.caseId).notifier)
        .escalate();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _escalationId = result?.escalationId;
    });

    if (result == null) {
      final err = ref
          .read(aiDoctorCaseProvider(widget.caseId))
          .valueOrNull
          ?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'হস্তান্তর ব্যর্থ')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('হস্তান্তর রেকর্ড #: ${result.escalationId}')),
    );
  }

  void _continueToServices() {
    switch (_selected) {
      case EscalationChannel.vetBooking:
      case EscalationChannel.asyncVetReview:
      case EscalationChannel.vetCallNow:
        context.push(AppRoutes.services);
      case EscalationChannel.clinicFinder:
        context.push(AppRoutes.services);
      case null:
        context.push(AppRoutes.services);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ভেটে হস্তান্তর')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'কিভাবে সাহায্য চান?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final channel in EscalationChannel.values)
              RadioListTile<EscalationChannel>(
                value: channel,
                groupValue: _selected,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _selected = v),
                title: Text(channel.labelBn()),
              ),
            const SizedBox(height: 16),
            if (_escalationId == null)
              FilledButton(
                onPressed: _submitting ? null : _escalate,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('কেস ভেট ইনবক্সে পাঠান'),
              )
            else ...[
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('হস্তান্তর সম্পন্ন'),
                  subtitle: Text('Escalation ID: $_escalationId'),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _continueToServices,
                child: const Text('ভেট সেবায় যান'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
