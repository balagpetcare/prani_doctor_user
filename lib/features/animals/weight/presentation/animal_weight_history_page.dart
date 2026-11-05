import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/animal_weight_dto.dart';
import '../data/animal_weight_method.dart';
import '../data/animal_weight_repository.dart';

final animalWeightHistoryProvider =
    FutureProvider.family<AnimalWeightHistoryResult, String>((ref, animalId) async {
  final result = await ref
      .read(animalWeightRepositoryProvider)
      .listHistory(animalId);
  return result.when(
    success: (v) => v,
    failure: (e) => throw e,
  );
});

class AnimalWeightHistoryPage extends ConsumerWidget {
  const AnimalWeightHistoryPage({super.key, required this.animalId});

  final String animalId;

  String _methodLabel(AnimalWeightMethod m) {
    switch (m) {
      case AnimalWeightMethod.tape:
        return 'Tape';
      case AnimalWeightMethod.scale:
        return 'Scale';
      case AnimalWeightMethod.aiCamera:
        return 'AI camera';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(animalWeightHistoryProvider(animalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Weight history')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (history) {
          if (history.records.isEmpty) {
            return const Center(child: Text('No weight records yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.records.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = history.records[index];
              final conf = r.aiConfidence != null
                  ? ' · ${(double.parse(r.aiConfidence!) * 100).toStringAsFixed(0)}% confidence'
                  : '';
              return ListTile(
                title: Text('${r.weightKg} kg'),
                subtitle: Text(
                  '${_methodLabel(r.method)} · ${r.measuredOn}$conf',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
