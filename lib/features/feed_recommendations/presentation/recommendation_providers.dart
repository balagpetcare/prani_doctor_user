import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recommendation_dto.dart';
import '../data/recommendation_repository.dart';

final dailyRecommendationProvider = FutureProvider.autoDispose
    .family<FeedRecommendation, String>((ref, livestockId) async {
      final result = await ref
          .read(recommendationRepositoryProvider)
          .getDailyRecommendation(livestockId: livestockId);
      return result.when(
        success: (recommendation) => recommendation,
        failure: (e) => throw e,
      );
    });
