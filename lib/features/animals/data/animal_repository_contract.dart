import '../../../core/error/api_result.dart';
import 'animal_dto.dart';

abstract class AnimalRepositoryContract {
  Future<ApiResult<AnimalPageResult>> listAnimals({
    int page = 1,
    int pageSize = 20,
    String search = '',
    AnimalFilter filter = AnimalFilter.all,
    bool includeInactive = false,
    bool forceRefresh = false,
  });

  Future<ApiResult<AnimalDetail>> getAnimal(String id, {bool forceRefresh = false});

  Future<ApiResult<AnimalProfile>> createAnimal(AnimalInput input);

  Future<ApiResult<AnimalProfile>> updateAnimal(String id, AnimalInput input);

  Future<ApiResult<AnimalProfile>> deactivateAnimal(String id);

  Future<ApiResult<String>> uploadPhoto(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  });

  Future<AnimalPageResult?> readCachedList();

  Future<void> saveDraft(AnimalInput input, {String? animalId});

  Future<AnimalInput?> readDraft({String? animalId});

  Future<void> clearDraft({String? animalId});
}
