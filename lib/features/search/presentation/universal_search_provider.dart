import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/language_controller.dart';
import '../../../core/localization/localization_loader.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../service_requests/data/service_request_repository.dart';
import '../../support/presentation/support_providers.dart';
import '../../../routing/app_routes.dart';

const _maxRecent = 8;

/// Input debounce for the search box — prevents a request per keystroke.
const _searchDebounce = Duration(milliseconds: 350);

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

/// Scoped to the search page; resets when user dismisses search.
final universalSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Persistent in-memory recent searches for the session.
/// Not autoDispose so the list survives search-page dismissal.
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

String _localized(Ref ref, String key) {
  // Only rebuild when the language code changes, not on every locale object change.
  final locale = ref.watch(
    languageControllerProvider.select((l) => l.languageCode),
  );
  return LocalizationLoader.lookup(locale, key);
}

/// Search results for the current query.
///
/// Scoped with autoDispose so memory is reclaimed when the search page
/// is dismissed. Debounced: waits [_searchDebounce] before firing network
/// requests, so rapid keystrokes don't trigger a fetch per character.
final universalSearchResultsProvider =
    FutureProvider.autoDispose<List<UniversalSearchResult>>((ref) async {
      final query = ref.watch(universalSearchQueryProvider).trim().toLowerCase();
      if (query.isEmpty) return const [];

      // Debounce: if the query changes again within the window, Riverpod will
      // cancel this build and restart, so the delay effectively coalesces
      // rapid keystrokes into a single request.
      await Future<void>.delayed(_searchDebounce);

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
            subtitle: doctor.serviceType.isNotEmpty
                ? doctor.serviceType
                : (doctor.fee ?? ''),
            category: _localized(ref, 'homeSearchSourceDoctors'),
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
            category: _localized(ref, 'homeSearchSourceServices'),
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
            category: _localized(ref, 'homeSearchSourceCommunity'),
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
            category: _localized(ref, 'homeSearchSourceAnimals'),
            route: AppRoutes.animalDetail(animal.id),
          );
        }
      } catch (_) {}

      final staticEntries = [
        (
          id: 'ai-chat',
          titleKey: 'searchAiAssistant',
          subtitleKey: 'searchAiSubtitle',
          categoryKey: 'searchAiAssistant',
          route: AppRoutes.aiChat,
        ),
        (
          id: 'marketplace',
          titleKey: 'searchMarketplace',
          subtitleKey: 'searchMarketplaceSubtitle',
          categoryKey: 'searchMarketplace',
          route: AppRoutes.marketplace,
        ),
        (
          id: 'reports',
          titleKey: 'searchReports',
          subtitleKey: 'searchReportsSubtitle',
          categoryKey: 'searchReports',
          route: AppRoutes.healthHistory,
        ),
        (
          id: 'emergency',
          titleKey: 'searchEmergency',
          subtitleKey: 'searchEmergencySubtitle',
          categoryKey: 'searchEmergency',
          route: AppRoutes.services,
        ),
      ];

      for (final entry in staticEntries) {
        addIfMatch(
          id: entry.id,
          title: _localized(ref, entry.titleKey),
          subtitle: _localized(ref, entry.subtitleKey),
          category: _localized(ref, entry.categoryKey),
          route: entry.route,
        );
      }

      return results.take(40).toList();
    });
