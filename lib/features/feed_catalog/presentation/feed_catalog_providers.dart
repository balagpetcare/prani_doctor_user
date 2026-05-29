import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../data/feed_catalog_dto.dart';

import '../data/feed_catalog_repository.dart';



final feedCatalogSearchQueryProvider = StateProvider.autoDispose<String>(

  (ref) => '',

);



final feedCatalogListProvider = FutureProvider.autoDispose<List<FeedCatalogItem>>(

  (ref) async {

    final search = ref.watch(feedCatalogSearchQueryProvider);

    final result = await ref

        .watch(feedCatalogRepositoryProvider)

        .listCatalog(search: search.isEmpty ? null : search);

    return result.when(

      success: (items) => items,

      failure: (e) => throw Exception(e.message),

    );

  },

);



final feedCatalogFilteredProvider =

    Provider.autoDispose<AsyncValue<List<FeedCatalogItem>>>((ref) {

  final catalogAsync = ref.watch(feedCatalogListProvider);

  final query = ref.watch(feedCatalogSearchQueryProvider);

  return catalogAsync.whenData((items) {

    if (query.trim().isEmpty) return items;

    return items.where((item) => item.matchesQuery(query)).toList();

  });

});

