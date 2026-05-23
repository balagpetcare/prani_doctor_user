import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/area/area_dto.dart';
import '../../../core/area/area_entities.dart';
import '../../../core/area/area_locale.dart';
import '../../../core/area/area_repository_contract.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/area_repository.dart';

/// Area locale derived from profile (`bn` / `en` for `/api/mobile/locations/*`).
final areaLocaleProvider = Provider<String>((ref) {
  final profile = ref.watch(mobileMeProvider).valueOrNull;
  return AreaLocale.fromProfileTag(profile?.locale);
});

Future<AreaLevelResult> _loadLevel(
  Ref ref,
  String label,
  Future<AreaPage<AreaNodeDto>> Function(AreaRepository repo, String locale)
  fetch,
) async {
  final locale = ref.watch(areaLocaleProvider);
  final repo = ref.read(areaRepositoryProvider);
  try {
    final page = await fetch(repo, locale);
    if (page.fromCache) {
      ref.read(areaOfflineHintProvider.notifier).state = true;
      if (kDebugMode) debugPrint('[LOCATION] $label from cache');
    }
    if (page.data.isEmpty) {
      if (kDebugMode) debugPrint('[LOCATION] $label empty');
      return AreaLevelResult.empty;
    }
    if (kDebugMode) {
      debugPrint('[LOCATION] $label loaded (${page.data.length} nodes)');
    }
    return AreaLevelResult(nodes: page.data, fromCache: page.fromCache);
  } catch (e) {
    if (kDebugMode) debugPrint('[LOCATION] $label failed: $e');
    return AreaLevelResult.empty;
  }
}

final divisionProvider = FutureProvider.autoDispose<AreaLevelResult>((ref) {
  return _loadLevel(
    ref,
    'divisions',
    (repo, locale) => repo.getDivisions(pageSize: 100, locale: locale),
  );
});

final districtProvider = FutureProvider.autoDispose
    .family<AreaLevelResult, String>((ref, divisionId) {
      if (divisionId.isEmpty) return Future.value(AreaLevelResult.empty);
      return _loadLevel(
        ref,
        'districts',
        (repo, locale) =>
            repo.getDistricts(divisionId, pageSize: 100, locale: locale),
      );
    });

final upazilaProvider = FutureProvider.autoDispose
    .family<AreaLevelResult, String>((ref, districtId) {
      if (districtId.isEmpty) return Future.value(AreaLevelResult.empty);
      return _loadLevel(
        ref,
        'upazilas',
        (repo, locale) =>
            repo.getUpazilas(districtId, pageSize: 100, locale: locale),
      );
    });

final unionProvider = FutureProvider.autoDispose
    .family<AreaLevelResult, AreaUnionQuery>((ref, query) {
      if (query.districtId.isEmpty || query.upazilaId.isEmpty) {
        return Future.value(AreaLevelResult.empty);
      }
      return _loadLevel(
        ref,
        'unions',
        (repo, locale) => repo.getUnions(
          districtId: query.districtId,
          upazilaId: query.upazilaId,
          pageSize: 100,
          locale: locale,
        ),
      );
    });

final villageProvider = FutureProvider.autoDispose
    .family<AreaLevelResult, String>((ref, unionId) {
      if (unionId.isEmpty) return Future.value(AreaLevelResult.empty);
      return _loadLevel(
        ref,
        'villages',
        (repo, locale) =>
            repo.getVillages(unionId, pageSize: 100, locale: locale),
      );
    });

/// Tracks whether last successful load used disk/memory fallback.
final areaOfflineHintProvider = StateProvider<bool>((ref) => false);

/// Parameters for scoped village search.
class AreaSearchParams {
  const AreaSearchParams({
    required this.query,
    this.unionId,
    this.upazilaId,
    this.districtId,
    this.divisionId,
  });

  final String query;
  final String? unionId;
  final String? upazilaId;
  final String? districtId;
  final String? divisionId;

  @override
  bool operator ==(Object other) {
    return other is AreaSearchParams &&
        other.query == query &&
        other.unionId == unionId &&
        other.upazilaId == upazilaId &&
        other.districtId == districtId &&
        other.divisionId == divisionId;
  }

  @override
  int get hashCode =>
      Object.hash(query, unionId, upazilaId, districtId, divisionId);
}

final areaSearchProvider = FutureProvider.autoDispose
    .family<AreaPage<AreaSearchHitDto>, AreaSearchParams>((ref, params) async {
      final trimmed = params.query.trim();
      if (trimmed.length < 2) {
        return const AreaPage(
          data: [],
          meta: AreaPageMeta(total: 0, page: 1, pageSize: 20, hasMore: false),
        );
      }

      final locale = ref.watch(areaLocaleProvider);
      return ref
          .read(areaRepositoryProvider)
          .search(
            query: trimmed,
            level: 'VILLAGE',
            limit: 50,
            locale: locale,
            divisionId: params.divisionId,
            districtId: params.districtId,
            upazilaId: params.upazilaId,
            unionId: params.unionId,
          );
    });

/// Invalidates all hierarchy providers for pull-to-refresh.
void invalidateAreaHierarchy(
  WidgetRef ref, {
  String? divisionId,
  String? districtId,
  String? upazilaId,
  String? unionId,
}) {
  ref.read(areaOfflineHintProvider.notifier).state = false;
  ref.invalidate(divisionProvider);
  if (divisionId != null && divisionId.isNotEmpty) {
    ref.invalidate(districtProvider(divisionId));
  }
  if (districtId != null && districtId.isNotEmpty) {
    ref.invalidate(upazilaProvider(districtId));
  }
  if (districtId != null &&
      districtId.isNotEmpty &&
      upazilaId != null &&
      upazilaId.isNotEmpty) {
    ref.invalidate(
      unionProvider(
        AreaUnionQuery(districtId: districtId, upazilaId: upazilaId),
      ),
    );
  }
  if (unionId != null && unionId.isNotEmpty) {
    ref.invalidate(villageProvider(unionId));
  }
}
