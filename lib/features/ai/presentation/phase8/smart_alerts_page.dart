import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_phase8_dto.dart';
import '../../data/ai_phase8_repository.dart';
import '../../data/ai_disclaimer_dto.dart';
import '../compliance/ai_compliance_shell.dart';
import '../compliance/ai_compliance_model.dart';
import '../widgets/ai_disclaimer_banner.dart';
import 'phase8_providers.dart';

class SmartAlertsPage extends ConsumerWidget {
  const SmartAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(smartAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('স্মার্ট সতর্কতা')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.alerts,
        child: alertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (alerts) {
            if (alerts.isEmpty) {
              return const Center(child: Text('কোনো সতর্কতা নেই'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, i) {
                final alert = alerts[i];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(alert.title),
                        subtitle: Text(alert.body),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            final result =
                                await ref.read(aiPhase8RepositoryProvider).dismissAlert(alert.id);
                            if (!context.mounted) return;
                            result.when(
                              success: (_) => ref.invalidate(smartAlertsProvider),
                              failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              ),
                            );
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: AiDisclaimerFooter(feature: AiDisclaimerFeature.advisory),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class KnowledgeSearchPage extends ConsumerStatefulWidget {
  const KnowledgeSearchPage({super.key});

  @override
  ConsumerState<KnowledgeSearchPage> createState() => _KnowledgeSearchPageState();
}

class _KnowledgeSearchPageState extends ConsumerState<KnowledgeSearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hitsAsync = _query.length >= 2
        ? ref.watch(knowledgeSearchProvider(_query))
        : const AsyncValue<List<KnowledgeHitModel>>.data([]);

    return Scaffold(
      appBar: AppBar(title: const Text('জ্ঞান ভান্ডার')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.knowledge,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'রোগ, টিকা, খাদ্য...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: hitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (hits) => ListView.builder(
                  itemCount: hits.length,
                  itemBuilder: (context, i) {
                    final hit = hits[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            title: Text(hit.title),
                            subtitle: Text(hit.excerpt),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: AiDisclaimerFooter(feature: AiDisclaimerFeature.advisory),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FollowUpSuggestionsPage extends ConsumerWidget {
  const FollowUpSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpsAsync = ref.watch(followUpsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ফলো-আপ')),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.followUps,
        child: followUpsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('কোনো ফলো-আপ নেই'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(item.title),
                        subtitle: Text(item.action),
                        trailing: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () async {
                            final result =
                                await ref.read(aiPhase8RepositoryProvider).dismissFollowUp(item.id);
                            if (!context.mounted) return;
                            result.when(
                              success: (_) => ref.invalidate(followUpsProvider),
                              failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              ),
                            );
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: AiDisclaimerFooter(feature: AiDisclaimerFeature.advisory),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
