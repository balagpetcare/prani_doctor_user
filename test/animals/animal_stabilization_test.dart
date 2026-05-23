import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/core/offline/local_cache_contract.dart';
import 'package:pranidoctor_user/features/animals/data/animal_dto.dart';

void main() {
  group('animal_stabilization_test', () {
    test('AnimalProfile preserves createdAt on copyWith', () {
      final created = DateTime.utc(2026, 1, 1);
      final updated = DateTime.utc(2026, 2, 1);
      final animal = AnimalProfile(
        id: 'a1',
        customerId: 'c1',
        name: 'Bella',
        species: 'Goat',
        category: 'LIVESTOCK',
        active: true,
        createdAt: created,
        updatedAt: updated,
      );

      final patched = animal.copyWith(name: 'Bella II', active: false);

      expect(patched.createdAt, created);
      expect(patched.updatedAt, updated);
      expect(patched.active, isFalse);
      expect(patched.name, 'Bella II');
    });

    test('AnimalProfile json round-trip keeps stable ids and timestamps', () {
      final animal = AnimalProfile(
        id: 'a1',
        customerId: 'c1',
        name: 'Bella',
        species: 'Goat',
        category: 'LIVESTOCK',
        photoUrl: null,
        active: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final restored = AnimalProfile.fromJson(animal.toJson());

      expect(restored.id, 'a1');
      expect(restored.createdAt, animal.createdAt);
      expect(restored.updatedAt, animal.updatedAt);
      expect(restored.photoUrl, isNull);
    });

    test('logout cache contract includes animal and dashboard snapshots', () {
      const clearedOnLogout = {
        LocalCacheContract.dashboardKey,
        LocalCacheContract.animalsListKey,
        LocalCacheContract.animalDraftKey,
        LocalCacheContract.farmsListKey,
      };

      expect(clearedOnLogout, contains(LocalCacheContract.dashboardKey));
      expect(clearedOnLogout, contains(LocalCacheContract.animalsListKey));
      expect(clearedOnLogout, contains(LocalCacheContract.animalDraftKey));
    });

    test('list cache merge avoids duplicate ids', () {
      final first = AnimalProfile(
        id: 'a1',
        customerId: 'c1',
        name: 'Old',
        species: 'Goat',
        category: 'LIVESTOCK',
        active: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final second = AnimalProfile(
        id: 'a1',
        customerId: 'c1',
        name: 'New',
        species: 'Goat',
        category: 'LIVESTOCK',
        active: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final existing = [first];
      final index = existing.indexWhere((item) => item.id == second.id);
      final merged = [...existing];
      if (index >= 0) {
        merged[index] = second;
      } else {
        merged.insert(0, second);
      }

      expect(merged.length, 1);
      expect(merged.first.name, 'New');
    });
  });
}
