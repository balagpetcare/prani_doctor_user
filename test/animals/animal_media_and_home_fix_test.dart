import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/core/offline/local_cache_contract.dart';
import 'package:pranidoctor_user/features/animals/data/animal_dto.dart';
import 'package:pranidoctor_user/features/animals/data/animal_api_paths.dart';
import 'package:pranidoctor_user/features/animals/presentation/animal_providers.dart';
import 'package:pranidoctor_user/features/shared/upload/models/media_owner.dart';
import 'package:pranidoctor_user/features/shared/upload/models/upload_purpose.dart';
import 'package:pranidoctor_user/features/shared/upload/models/upload_result.dart';

void main() {
  group('animal media domain separation', () {
    test('animal upload purpose is not profile photo', () {
      expect(UploadPurpose.animalPhoto.apiValue, 'ANIMAL_PHOTO');
      expect(
        UploadPurpose.animalPhoto.apiValue,
        isNot(UploadPurpose.customerProfilePhoto.apiValue),
      );
      expect(
        MediaPurpose.animal.uploadPurposeApiValue,
        UploadPurpose.animalPhoto.apiValue,
      );
      expect(
        MediaPurpose.profile.uploadPurposeApiValue,
        UploadPurpose.customerProfilePhoto.apiValue,
      );
    });

    test('animal API path is generic upload not profile-image', () {
      expect(AnimalApiPaths.uploadImage, '/api/mobile/upload');
      expect(AnimalApiPaths.uploadImage, isNot(contains('profile-image')));
    });

    test('generic upload result uses url for animalPhotoUrl not profile fields', () {
      const upload = UploadResult(
        fileId: 'f1',
        url: 'https://cdn.example/api/mobile/uploads/f1',
        objectKey: 'uploads/v1/u1/ANIMAL_PHOTO/x.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 100,
        bucket: 'dev',
        profilePhotoUrl: 'https://cdn.example/avatar-should-not-use',
      );
      expect(upload.animalPhotoUrl, upload.url);
      expect(upload.animalPhotoUrl, isNot(upload.profilePhotoUrl));
      expect(upload.userProfilePhotoUrl, upload.profilePhotoUrl);
    });

    test('UploadResult.fromJson prefers download url for animals', () {
      final upload = UploadResult.fromJson({
        'fileId': 'abc',
        'downloadUrl': 'https://cdn.example/animal.jpg',
        'profilePhotoUrl': 'https://cdn.example/wrong-avatar.jpg',
      });
      expect(upload.url, 'https://cdn.example/animal.jpg');
      expect(upload.animalPhotoUrl, 'https://cdn.example/animal.jpg');
    });
  });

  group('AnimalListState upsert', () {
    test('prepends new animal and updates counts', () {
      const current = AnimalListState(
        animals: [],
        total: 0,
        activeCount: 0,
        inactiveCount: 0,
        livestockCount: 0,
      );

      final animal = AnimalProfile(
        id: 'a1',
        customerId: 'c1',
        name: 'Bella',
        species: 'Cattle',
        category: 'LIVESTOCK',
        animalType: 'CATTLE',
        active: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        photoUrl: 'https://cdn.example/animal.jpg',
      );

      final state = AnimalListNotifier.applyUpsert(current, animal);
      expect(state.animals.length, 1);
      expect(state.animals.first.id, 'a1');
      expect(state.activeCount, 1);
      expect(state.total, 1);
    });

    test('updates existing animal without duplicating', () {
      final existing = AnimalProfile(
        id: 'a1',
        customerId: 'c1',
        name: 'Old',
        species: 'Goat',
        category: 'LIVESTOCK',
        active: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final current = AnimalListState(animals: [existing], total: 1, activeCount: 1);

      final updated = existing.copyWith(
        name: 'New',
        photoUrl: 'https://cdn/x.jpg',
      );
      final state = AnimalListNotifier.applyUpsert(current, updated);

      expect(state.animals.length, 1);
      expect(state.animals.first.name, 'New');
      expect(state.animals.first.primaryImageUrl, 'https://cdn/x.jpg');
    });
  });

  group('cache keys', () {
    test('profile and animal image keys are distinct', () {
      expect(
        LocalCacheContract.profileImageCacheKey('u1'),
        isNot(LocalCacheContract.animalImageCacheKey('a1')),
      );
      expect(LocalCacheContract.profileImageCacheKey('u1'), 'profile_image:u1');
      expect(LocalCacheContract.animalImageCacheKey('a1'), 'animal_image:a1');
    });
  });
}
