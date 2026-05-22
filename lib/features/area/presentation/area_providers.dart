import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/area/area_dto.dart';
import '../../../core/area/area_entities.dart';
import '../../../core/area/area_locale.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/area_repository.dart';

/// Area locale derived from profile (`bn` / `en` for `/api/area/*`).
final areaLocaleProvider = Provider<String>((ref) {
  final profile = ref.watch(mobileMeProvider).valueOrNull;
  return AreaLocale.fromProfileTag(profile?.locale);
});

Future<AreaLevelResult> _loadLevel(
  Ref ref,
  Future<AreaPage<AreaNodeDto>> Function(AreaRepository repo, String locale) fetch,
) async {
  final locale = ref.watch(areaLocaleProvider);
  final repo = ref.read(areaRepositoryProvider);
  try {
    final page = await fetch(repo, locale);
    if (page.data.isEmpty) return AreaLevelResult.empty;
    return AreaLevelResult(nodes: page.data);
  } catch (_) {
    rethrow;
  }
}

final divisionProvider = FutureProvider.autoDispose<AreaLevelResult>((ref) {
  return _loadLevel(ref, (repo, locale) => repo.getDivisions(pageSize: 100, locale: locale));
});

final districtProvider = FutureProvider.autoDispose.family<AreaLevelResult, String>((ref, divisionId) {
  if (divisionId.isEmpty) return Future.value(AreaLevelResult.empty);
  return _loadLevel(
    ref,
    (repo, locale) => repo.getDistricts(divisionId, pageSize: 100, locale: locale),
  );
});

final upazilaProvider = FutureProvider.autoDispose.family<AreaLevelResult, String>((ref, districtId) {
  if (districtId.isEmpty) return Future.value(AreaLevelResult.empty);
  return _loadLevel(
    ref,
    (repo, locale) => repo.getUpazilas(districtId, pageSize: 100, locale: locale),
  );
});

final unionProvider = FutureProvider.autoDispose.family<AreaLevelResult, String>((ref, upazilaId) {
  if (upazilaId.isEmpty) return Future.value(AreaLevelResult.empty);
  return _loadLevel(
    ref,
    (repo, locale) => repo.getUnions(upazilaId, pageSize: 100, locale: locale),
  );
});

final villageProvider = FutureProvider.autoDispose.family<AreaLevelResult, String>((ref, unionId) {
  if (unionId.isEmpty) return Future.value(AreaLevelResult.empty);
  return _loadLevel(
    ref,
    (repo, locale) => repo.getVillages(unionId, pageSize: 100, locale: locale),
  );
});

/// Tracks whether last successful load used disk/memory fallback.
final areaOfflineHintProvider = StateProvider<bool>((ref) => false);
