import 'package:flutter/foundation.dart';

import '../../features/animals/data/animal_dto.dart';
import '../../features/home/data/dashboard_context_dto.dart';
import '../../features/home/data/home_api_guard.dart';

/// Parses cached animal rows off the UI thread when the list is large.
List<AnimalProfile> parseAnimalProfilesFromMaps(List<Map<String, dynamic>> items) {
  return items
      .map((j) => AnimalProfile.fromJson(j, fromCache: true))
      .toList(growable: false);
}

Future<List<AnimalProfile>> parseAnimalProfilesOffMain(
  List<Map<String, dynamic>> items,
) async {
  if (items.length < HomeApiGuard.isolateParseMinItems) {
    return parseAnimalProfilesFromMaps(items);
  }
  return compute(parseAnimalProfilesFromMaps, items);
}

/// Parses dashboard context JSON off the UI thread (cache hydration).
DashboardContext parseDashboardContextFromMap(Map<String, dynamic> json) {
  return DashboardContext.fromJson(json, fromCache: true);
}

Future<DashboardContext> parseDashboardContextOffMain(
  Map<String, dynamic> json,
) async {
  return compute(parseDashboardContextFromMap, json);
}
