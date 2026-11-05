import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../livestock/presentation/livestock_providers.dart';
import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../data/ai_doctor_dto.dart';
import '../providers/ai_doctor_providers.dart';

class AiDoctorCaseSetupPage extends ConsumerStatefulWidget {
  const AiDoctorCaseSetupPage({
    super.key,
    this.prefilledSpecies,
    this.prefilledLivestockId,
    this.symptomCheckSessionId,
  });

  final String? prefilledSpecies;
  final String? prefilledLivestockId;
  final String? symptomCheckSessionId;

  @override
  ConsumerState<AiDoctorCaseSetupPage> createState() =>
      _AiDoctorCaseSetupPageState();
}

class _AiDoctorCaseSetupPageState extends ConsumerState<AiDoctorCaseSetupPage> {
  late String _species;
  String? _livestockId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _species = widget.prefilledSpecies ?? 'CATTLE';
    _livestockId = widget.prefilledLivestockId;
  }

  Future<void> _createCase() async {
    setState(() => _loading = true);
    final aiCase = await createAiDoctorCase(
      ref,
      species: _species,
      livestockId: _livestockId,
      symptomCheckSessionId: widget.symptomCheckSessionId,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (aiCase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কেস তৈরি ব্যর্থ')),
      );
      return;
    }
    context.go(AppRoutes.aiDoctorCaseIntake(aiCase.id));
  }

  @override
  Widget build(BuildContext context) {
    final livestockAsync = ref.watch(livestockListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('নতুন AI Doctor কেস')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'প্রাণীর ধরন নির্বাচন করুন',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _species,
              decoration: const InputDecoration(
                labelText: 'প্রজাতি',
                border: OutlineInputBorder(),
              ),
              items: aiDoctorApiSpecies
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(apiSpeciesLabelBn(s)),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : (v) => setState(() => _species = v!),
            ),
            const SizedBox(height: 20),
            Text(
              'নির্দিষ্ট প্রাণী (ঐচ্ছিক)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            livestockAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('প্রাণী তালিকা লোড ব্যর্থ'),
              data: (state) {
                final animals = state.items;
                return DropdownButtonFormField<String?>(
                  value: _livestockId,
                  decoration: const InputDecoration(
                    labelText: 'প্রাণী',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('নির্দিষ্ট প্রাণী নেই'),
                    ),
                    ...animals.map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.name} (${a.displaySpecies})'),
                      ),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) => setState(() {
                          _livestockId = v;
                          if (v != null) {
                            final animal = animals.firstWhere((a) => a.id == v);
                            _species = livestockSpeciesToApi(animal.species);
                          }
                        }),
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _createCase,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('কেস তৈরি করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
