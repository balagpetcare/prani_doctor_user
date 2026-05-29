import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_phase8_repository.dart';
import 'phase8_providers.dart';

class SmartRecommendationsPage extends ConsumerWidget {
  const SmartRecommendationsPage({super.key, this.farmRef});

  final String? farmRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(smartRecommendationsProvider(farmRef));

    return Scaffold(
      appBar: AppBar(title: const Text('AI পরামর্শ')),
      body: recsAsync.when(
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
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('এখন কোনো পরামর্শ নেই'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${item.priority}')),
                  title: Text(item.title),
                  subtitle: Text(item.explanation),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      final repo = ref.read(aiPhase8RepositoryProvider);
                      final result = action == 'complete'
                          ? await repo.completeRecommendation(item.id)
                          : await repo.dismissRecommendation(item.id);
                      if (!context.mounted) return;
                      result.when(
                        success: (_) {
                          ref.invalidate(smartRecommendationsProvider(farmRef));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(action == 'complete' ? 'সম্পন্ন' : 'বাতিল')),
                          );
                        },
                        failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        ),
                      );
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'complete', child: Text('সম্পন্ন')),
                      PopupMenuItem(value: 'dismiss', child: Text('বাতিল')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
