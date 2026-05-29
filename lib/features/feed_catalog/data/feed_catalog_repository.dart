import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import 'feed_catalog_api_paths.dart';
import 'feed_catalog_dto.dart';

abstract class FeedCatalogRepositoryContract {
  Future<ApiResult<List<FeedCatalogItem>>> listCatalog({String? search});
}

class FeedCatalogRepository implements FeedCatalogRepositoryContract {
  FeedCatalogRepository(this._dio);

  final Dio _dio;

  Future<List<FeedCatalogItem>> _loadAssetCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/seeds/feed_catalog.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'];
      if (items is! List) return [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(FeedCatalogItem.fromJson)
          .toList();
    } catch (e, st) {
      AppLog.warn(
        'Offline feed catalog asset unavailable',
        tag: 'FeedCatalog',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  List<FeedCatalogItem> _filterLocal(
    List<FeedCatalogItem> items,
    String? search,
  ) {
    if (search == null || search.trim().isEmpty) return items;
    return items.where((item) => item.matchesQuery(search)).toList();
  }

  @override
  Future<ApiResult<List<FeedCatalogItem>>> listCatalog({String? search}) async {
    try {
      final data = await getJson(
        _dio,
        FeedCatalogApiPaths.catalog,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
          'limit': 200,
        },
      );
      final raw = data['items'];
      if (raw is! List) {
        return const ApiResult.failure(
          AppException(message: 'Invalid feed catalog response'),
        );
      }
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(FeedCatalogItem.fromJson)
          .toList();
      return ApiResult.success(items);
    } on AppException catch (e) {
      try {
        final local = await _loadAssetCatalog();
        return ApiResult.success(_filterLocal(local, search));
      } catch (_) {
        return ApiResult.failure(e);
      }
    }
  }
}

final feedCatalogRepositoryProvider = Provider<FeedCatalogRepositoryContract>(
  (ref) => FeedCatalogRepository(ref.watch(dioProvider)),
);
