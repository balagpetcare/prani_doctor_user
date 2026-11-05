import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../../ai/presentation/phase8/phase8_providers.dart';
import '../../data/ai_doctor_dto.dart';
import '../providers/ai_doctor_providers.dart';
import '../widgets/risk_banner.dart';

class AiDoctorIntakePage extends ConsumerStatefulWidget {
  const AiDoctorIntakePage({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<AiDoctorIntakePage> createState() => _AiDoctorIntakePageState();
}

class _AiDoctorIntakePageState extends ConsumerState<AiDoctorIntakePage> {
  final _selected = <String>{};
  final _freeTextController = TextEditingController();
  int? _durationDays;
  SymptomSeverity? _severity;
  bool _submitting = false;

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  String _apiSpecies(AiDoctorCaseModel? aiCase) {
    if (aiCase == null) return 'CATTLE';
    return livestockSpeciesToApi(aiCase.species);
  }

  Future<void> _submit() async {
    if (_selected.isEmpty && _freeTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একটি লক্ষণ নির্বাচন করুন')),
      );
      return;
    }

    setState(() => _submitting = true);
    final freeText = _freeTextController.text.trim();
    final result = await ref
        .read(aiDoctorCaseProvider(widget.caseId).notifier)
        .submitIntake(
          SubmitIntakeInput(
            symptomCodes: _selected.toList(),
            freeTextSymptoms: freeText.isEmpty ? null : [freeText],
            durationDays: _durationDays,
            severity: _severity,
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result == null) {
      final err = ref
          .read(aiDoctorCaseProvider(widget.caseId))
          .valueOrNull
          ?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'জমা দিতে ব্যর্থ')),
      );
      return;
    }

    if (result.emergencyHandoff || result.riskAssessment.emergency) {
      context.go(AppRoutes.aiDoctorCaseEmergency(widget.caseId));
      return;
    }
    context.go(AppRoutes.aiDoctorCaseChat(widget.caseId));
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(aiDoctorCaseProvider(widget.caseId));
    final aiCase = caseAsync.valueOrNull?.aiCase;
    final taxonomyAsync = ref.watch(symptomTaxonomyProvider(_apiSpecies(aiCase)));

    return Scaffold(
      appBar: AppBar(title: const Text('লক্ষণ ইনটেক')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: caseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (viewState) {
            final loadedCase = viewState.aiCase;
            if (loadedCase == null) {
              return const Center(child: Text('কেস লোড ব্যর্থ'));
            }

            return taxonomyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (taxonomy) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (loadedCase.riskAssessment != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RiskBanner(risk: loadedCase.riskAssessment!),
                    ),
                  Text(
                    'প্রজাতি: ${apiSpeciesLabelBn(_apiSpecies(loadedCase))}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final system in taxonomy.bodySystems) ...[
                    Text(
                      system.bodySystem,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...system.symptoms.map(
                      (s) => CheckboxListTile(
                        value: _selected.contains(s.code),
                        onChanged: _submitting
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  _selected.add(s.code);
                                } else {
                                  _selected.remove(s.code);
                                }
                              }),
                        title: Text(s.labelBn),
                        subtitle: s.redFlag
                            ? const Text(
                                '⚠️ জরুরি লক্ষণ',
                                style: TextStyle(color: Colors.red),
                              )
                            : null,
                      ),
                    ),
                    const Divider(),
                  ],
                  TextField(
                    controller: _freeTextController,
                    decoration: const InputDecoration(
                      labelText: 'অতিরিক্ত লক্ষণ (লিখিত)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    enabled: !_submitting,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _durationDays,
                    decoration: const InputDecoration(
                      labelText: 'কত দিন ধরে',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('নির্বাচন করুন')),
                      DropdownMenuItem(value: 1, child: Text('১ দিন')),
                      DropdownMenuItem(value: 3, child: Text('৩ দিন')),
                      DropdownMenuItem(value: 7, child: Text('১ সপ্তাহ')),
                      DropdownMenuItem(value: 14, child: Text('২ সপ্তাহ')),
                      DropdownMenuItem(value: 30, child: Text('১ মাস+')),
                    ],
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _durationDays = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SymptomSeverity?>(
                    value: _severity,
                    decoration: const InputDecoration(
                      labelText: 'তীব্রতা',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('নির্বাচন করুন')),
                      DropdownMenuItem(
                        value: SymptomSeverity.mild,
                        child: Text('হালকা'),
                      ),
                      DropdownMenuItem(
                        value: SymptomSeverity.moderate,
                        child: Text('মাঝারি'),
                      ),
                      DropdownMenuItem(
                        value: SymptomSeverity.severe,
                        child: Text('গুরুতর'),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _severity = v),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('বিশ্লেষণ করুন'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
