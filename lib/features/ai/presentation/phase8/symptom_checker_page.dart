import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../data/ai_phase8_dto.dart';
import '../../data/ai_phase8_repository.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('লক্ষণ যাচাই')),
      body: _result != null
          ? _ResultView(result: _result!, onReset: () => setState(() => _result = null))
          : taxonomyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'লোড ব্যর্থ',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (taxonomy) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('সহায়ক তথ্য মাত্র'),
                      subtitle: Text(
                        'এটি চিকিৎসা নির্ণয় নয়। জরুরি হলে স্থানীয় প্রাণী চিকিৎসকের সহায়তা নিন।',
                      ),
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

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onReset});

  final SymptomCheckResultModel result;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final color = result.emergency
        ? Colors.red
        : result.triageBucket == 'HIGH'
        ? Colors.orange
        : Colors.green;

    return ListView(
      padding: const EdgeInsets.all(16),
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
          Text('⚠️ জরুরি লক্ষণ', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.red)),
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
        const SizedBox(height: 12),
        const Text(
          'এটি চিকিৎসা নির্ণয় নয় — শুধুমাত্র সহায়ক তথ্য।',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (result.escalationRequired)
          FilledButton(
            onPressed: () => context.push(AppRoutes.services),
            child: const Text('চিকিৎসক খুঁজুন'),
          ),
        OutlinedButton(onPressed: onReset, child: const Text('আবার চেষ্টা')),
      ],
    );
  }
}
