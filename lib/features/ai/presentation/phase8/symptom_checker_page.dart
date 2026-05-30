import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import '../../data/ai_phase8_dto.dart';
import '../../data/ai_phase8_repository.dart';
import '../compliance/ai_compliance_model.dart';
import '../compliance/ai_compliance_shell.dart';
import '../compliance/ai_output_compliance_wrapper.dart';
import 'phase8_providers.dart';

class SymptomCheckerPage extends ConsumerStatefulWidget {
  const SymptomCheckerPage({super.key, this.species = 'CATTLE'});

  final String species;

  @override
  ConsumerState<SymptomCheckerPage> createState() => _SymptomCheckerPageState();
}

class _SymptomCheckerPageState extends ConsumerState<SymptomCheckerPage> {
  final _selected = <String>{};
  SymptomCheckResultModel? _result;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final taxonomyAsync = ref.watch(symptomTaxonomyProvider(widget.species));

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text('লক্ষণ যাচাই')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: _result != null
            ? _ResultView(
                result: _result!,
                onReset: () => setState(() => _result = null),
              )
            : taxonomyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e is Exception
                          ? e.toString().replaceFirst('Exception: ', '')
                          : 'লোড ব্যর্থ',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (taxonomy) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      l10n.aiSymptomGuidanceNote,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'প্রাণীর লক্ষণ নির্বাচন করুন',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 12),
                  for (final system in taxonomy.bodySystems) ...[
                    Text(system.bodySystem, style: Theme.of(context).textTheme.titleSmall),
                    ...system.symptoms.map(
                      (s) => CheckboxListTile(
                        value: _selected.contains(s.code),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(s.code);
                          } else {
                            _selected.remove(s.code);
                          }
                        }),
                        title: Text(s.labelBn),
                        subtitle: s.redFlag
                            ? const Text('⚠️ জরুরি লক্ষণ', style: TextStyle(color: Colors.red))
                            : null,
                      ),
                    ),
                    const Divider(),
                  ],
                  FilledButton(
                    onPressed: _selected.isEmpty || _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('বিশ্লেষণ করুন'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await ref.read(aiPhase8RepositoryProvider).runSymptomCheck(
      SymptomCheckInput(species: widget.species, symptomCodes: _selected.toList()),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (data) => setState(() => _result = data),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.result, required this.onReset});

  final SymptomCheckResultModel result;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = result.emergency
        ? Colors.red
        : result.triageBucket == 'HIGH'
        ? Colors.orange
        : Colors.green;
    final evaluation = AiComplianceEvaluation.fromSymptomCheck(result);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AiOutputComplianceWrapper(
          evaluation: evaluation,
          apiEscalationDisclosure: result.escalationFields?.disclosure,
          showKeywordLimitation: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: color.withValues(alpha: 0.1),
                child: ListTile(
                  title: Text('ঝুঁকি: ${result.triageBucket}'),
                  subtitle: Text(result.recommendation),
                ),
              ),
              if (result.redFlags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '⚠️ জরুরি লক্ষণ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.red),
                ),
                ...result.redFlags.map(
                  (f) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.warning_amber, color: Colors.red),
                    title: Text(f['labelBn']?.toString() ?? f['labelEn']?.toString() ?? ''),
                  ),
                ),
              ],
              if (result.differentials.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('সম্ভাব্য বিষয় (শিক্ষামূলক)', style: Theme.of(context).textTheme.titleSmall),
                ...result.differentials.map(
                  (d) => ListTile(
                    title: Text(d['title']?.toString() ?? ''),
                    subtitle: Text(d['disclaimer']?.toString() ?? ''),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onReset, child: const Text('আবার চেষ্টা')),
      ],
    );
  }
}

