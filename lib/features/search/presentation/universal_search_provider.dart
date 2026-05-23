import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../animals/presentation/animal_providers.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../service_requests/data/service_request_repository.dart';
import '../../support/presentation/support_providers.dart';
import '../../../routing/app_routes.dart';

const _recentKey = 'universal_search_recent';
const _maxRecent = 8;

class UniversalSearchResult {
  const UniversalSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String route;
}

final universalSearchQueryProvider = StateProvider<String>((ref) => '');

final universalSearchRecentProvider =
    NotifierProvider<UniversalSearchRecentNotifier, List<String>>(
      UniversalSearchRecentNotifier.new,
    );

class UniversalSearchRecentNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void setInitial(List<String> values) {
    state = values;
  }

  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final current = [...state];
    current.remove(trimmed);
    current.insert(0, trimmed);
    state = current.take(_maxRecent).toList();
  }

  void clear() {
    state = const [];
  }
}

final universalSearchResultsProvider =
    FutureProvider<List<UniversalSearchResult>>((ref) async {
      final query = ref.watch(universalSearchQueryProvider).trim().toLowerCase();
      if (query.isEmpty) return const [];

      final results = <UniversalSearchResult>[];

      void addIfMatch({
        required String id,
        required String title,
        required String subtitle,
        required String category,
        required String route,
      }) {
        final haystack = '$title $subtitle $category'.toLowerCase();
        if (haystack.contains(query)) {
          results.add(
            UniversalSearchResult(
              id: id,
              title: title,
              subtitle: subtitle,
              category: category,
              route: route,
            ),
          );
        }
      }

      try {
        final doctors = await ref.watch(doctorListProvider.future);
        for (final doctor in doctors.doctors) {
          addIfMatch(
            id: 'doc-${doctor.id}',
            title: doctor.name,
            subtitle: doctor.serviceType ?? doctor.fee ?? '',
            category: 'Doctors',
            route: AppRoutes.doctorDetail(doctor.id),
          );
        }
      } catch (_) {}

      try {
        final categories = await ref.watch(serviceCategoriesProvider.future);
        for (final category in categories) {
          addIfMatch(
            id: 'cat-${category.id}',
            title: category.name,
            subtitle: category.description ?? category.slug,
            category: 'Services',
            route: AppRoutes.services,
          );
        }
      } catch (_) {}

      try {
        final help = await ref.watch(supportHelpProvider.future);
        for (final item in help.faq) {
          addIfMatch(
            id: 'faq-${item.id}',
            title: item.question,
            subtitle: item.answer,
            category: 'Community',
            route: AppRoutes.supportHelp,
          );
        }
      } catch (_) {}

      try {
        final animalState = await ref.watch(animalListProvider.future);
        for (final animal in animalState.animals) {
          addIfMatch(
            id: 'animal-${animal.id}',
            title: animal.name,
            subtitle: animal.species,
            category: 'Animals',
            route: AppRoutes.animalDetail(animal.id),
          );
        }
      } catch (_) {}

      const staticEntries = [
        (
          id: 'ai-chat',
          title: 'AI Assistant',
          subtitle: 'Ask health questions',
          category: 'AI Assistant',
          route: AppRoutes.aiChat,
        ),
        (
          id: 'marketplace',
          title: 'Marketplace',
          subtitle: 'Services and offers',
          category: 'Marketplace',
          route: AppRoutes.marketplace,
        ),
        (
          id: 'reports',
          title: 'Reports',
          subtitle: 'Health records and reports',
          category: 'Reports',
          route: AppRoutes.healthHistory,
        ),
        (
          id: 'emergency',
          title: 'Emergency',
          subtitle: 'Emergency doctors and services',
          category: 'Emergency',
          route: AppRoutes.services,
        ),
      ];

      for (final entry in staticEntries) {
        addIfMatch(
          id: entry.id,
          title: entry.title,
          subtitle: entry.subtitle,
          category: entry.category,
          route: entry.route,
        );
      }

      return results.take(40).toList();
    });
