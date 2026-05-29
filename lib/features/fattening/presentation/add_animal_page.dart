import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../data/fattening_repository.dart';
import 'fattening_providers.dart';

class FatteningAddAnimalPage extends ConsumerStatefulWidget {
  const FatteningAddAnimalPage({
    super.key,
    required this.farmId,
    required this.batchId,
  });

  final String farmId;
  final String batchId;

  @override
  ConsumerState<FatteningAddAnimalPage> createState() =>
      _FatteningAddAnimalPageState();
}

class _FatteningAddAnimalPageState extends ConsumerState<FatteningAddAnimalPage> {
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final animalsAsync = ref.watch(animalListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningAddAnimals)),
      body: animalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          final cattle = state.animals
              .where(
                (a) =>
                    a.active &&
                    (a.animalType?.toUpperCase() == 'CATTLE' ||
                        a.species.toLowerCase().contains('cattle')),
              )
              .toList();
          if (cattle.isEmpty) {
            return Center(child: Text(l10n.fatteningNoCattleAvailable));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cattle.length,
                  itemBuilder: (context, index) {
                    final animal = cattle[index];
                    final selected = _selected.contains(animal.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(animal.id);
                          } else {
                            _selected.remove(animal.id);
                          }
                        });
                      },
                      title: Text(animal.name),
                      subtitle: Text(
                        [
                          animal.breed,
                          if (animal.weightKg != null) '${animal.weightKg} kg',
                        ].whereType<String>().join(' · '),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _saving || _selected.isEmpty
                        ? null
                        : () => _save(context),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.fatteningAddSelectedAnimals(_selected.length),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = context.tr;
    setState(() => _saving = true);
    final result = await ref
        .read(fatteningRepositoryProvider)
        .addAnimals(widget.batchId, _selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        refreshFatteningAfterMutation(
          ref,
          farmId: widget.farmId,
          batchId: widget.batchId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('fatteningAnimalsAdded'))),
        );
        context.go(
          AppRoutes.fatteningBatchDetail(widget.farmId, widget.batchId),
        );
      },
      failure: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }
}
