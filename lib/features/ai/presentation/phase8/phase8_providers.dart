import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_phase8_dto.dart';
import '../../data/ai_phase8_repository.dart';

final symptomTaxonomyProvider = FutureProvider.family<SymptomTaxonomyModel, String>((
  ref,
  species,
) async {
  final result = await ref.read(aiPhase8RepositoryProvider).fetchTaxonomy(species);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final smartRecommendationsProvider = FutureProvider.family<List<SmartRecommendationModel>, String?>((
  ref,
  farmRef,
) async {
  final result = await ref.read(aiPhase8RepositoryProvider).fetchRecommendations(
    farmRef: farmRef,
  );
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final smartAlertsProvider = FutureProvider<List<SmartAlertModel>>((ref) async {
  final result = await ref.read(aiPhase8RepositoryProvider).fetchAlerts();
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final farmHealthProvider = FutureProvider.family<FarmHealthDashboardModel, String>((
  ref,
  farmRef,
) async {
  final result = await ref.read(aiPhase8RepositoryProvider).fetchFarmHealth(farmRef);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final followUpsProvider = FutureProvider<List<FollowUpModel>>((ref) async {
  final result = await ref.read(aiPhase8RepositoryProvider).fetchFollowUps();
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final knowledgeSearchProvider =
    FutureProvider.family<List<KnowledgeHitModel>, String>((ref, query) async {
      if (query.trim().length < 2) return [];
      final result = await ref.read(aiPhase8RepositoryProvider).searchKnowledge(query);
      return result.when(
        success: (data) => data,
        failure: (e) => throw e,
      );
    });
