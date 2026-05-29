import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_disclaimer_dto.dart';
import '../widgets/ai_disclaimer_banner.dart';
import 'phase8_providers.dart';

class FarmHealthDashboardPage extends ConsumerWidget {
  const FarmHealthDashboardPage({super.key, required this.farmRef});

  final String farmRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(farmHealthProvider(farmRef));

    return Scaffold(
      appBar: AppBar(title: const Text('খামার স্বাস্থ্য')),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (dash) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AiDisclaimerBanner(feature: AiDisclaimerFeature.advisory),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScoreCard(
                    label: 'ঝিড় স্বাস্থ্য',
                    score: dash.herdHealthScore,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScoreCard(
                    label: 'ঝুঁকি (invert)',
                    score: (100 - dash.farmRiskScore).clamp(0, 100),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('${dash.livestockCount}টি সক্রিয় পশু', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('আজকের পরামর্শ', style: Theme.of(context).textTheme.titleSmall),
            ...dash.recommendations.map(
              (r) => ListTile(
                title: Text(r.title),
                subtitle: Text(r.explanation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.label, required this.score, required this.color});

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text('$score', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
