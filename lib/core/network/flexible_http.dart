import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';
import '../error/http_error_mapper.dart';
import 'api_envelope.dart';

/// Remembers the first successful HTTP verb per path (405 fallback).
final class ApiMethodCache {
  ApiMethodCache._();
  static final Map<String, String> _methods = {};
  static const _maxEntries = 128;

  static String? preferred(String path) => _methods[path];

  static void remember(String path, String method) {
    if (_methods.length >= _maxEntries) {
      _methods.clear();
    }
    _methods[path] = method;
  }
}

Future<Map<String, dynamic>> requestJson({
  required Dio dio,
  required String path,
  required String logTag,
  String preferredMethod = 'GET',
  Map<String, dynamic>? body,
  Map<String, dynamic>? queryParameters,
  List<String> fallbackMethods = const ['GET', 'POST', 'PATCH', 'PUT'],
}) async {
  final methods = <String>{
    if (ApiMethodCache.preferred(path) != null) ApiMethodCache.preferred(path)!,
    preferredMethod,
    ...fallbackMethods,
  }.toList(growable: false);

  AppException? lastError;

  for (final method in methods) {
    if (kDebugMode) {
      debugPrint(
        '[${logTag}_REQ] METHOD=$method URL=$path'
        '${body != null && body.isNotEmpty ? ' BODY_KEYS=${body.keys.join(',')}' : ''}',
      );
    }

    try {
      final Response<dynamic> response;
      switch (method) {
        case 'GET':
          response = await dio.get<dynamic>(
            path,
            queryParameters: queryParameters,
          );
        case 'POST':
          response = await dio.post<dynamic>(path, data: body ?? {});
        case 'PATCH':
          response = await dio.patch<dynamic>(path, data: body ?? {});
        case 'PUT':
          response = await dio.put<dynamic>(path, data: body ?? {});
        default:
          continue;
      }

      if (kDebugMode) {
        debugPrint('[${logTag}_RES] STATUS=${response.statusCode} URL=$path');
      }

      if (response.statusCode == 405) {
        lastError = HttpErrorMapper.fromStatus(
          statusCode: 405,
          cause: response,
        );
        continue;
      }

      final data = ApiEnvelope.unwrapData(response);
      ApiMethodCache.remember(path, method);
      return data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (kDebugMode) {
        debugPrint('[${logTag}_RES] STATUS=$status URL=$path ERROR=${e.type}');
      }
      if (status == 405) {
        lastError = HttpErrorMapper.fromDio(e);
        continue;
      }
      throw HttpErrorMapper.fromDio(e);
    } on AppException catch (e) {
      if (e.code == '405') {
        lastError = e;
        continue;
      }
      rethrow;
    }
  }

  throw lastError ??
      const AppException(message: 'Request failed', code: 'METHOD_NOT_ALLOWED');
}

Future<Map<String, dynamic>> getJsonFlexible(
  Dio dio,
  String path, {
  required String logTag,
  Map<String, dynamic>? queryParameters,
}) => requestJson(
  dio: dio,
  path: path,
  logTag: logTag,
  preferredMethod: 'GET',
  queryParameters: queryParameters,
  fallbackMethods: const ['GET', 'POST', 'PATCH', 'PUT'],
);

Future<Map<String, dynamic>> patchJsonFlexible(
  Dio dio,
  String path,
  Map<String, dynamic> body, {
  required String logTag,
}) => requestJson(
  dio: dio,
  path: path,
  logTag: logTag,
  preferredMethod: 'PATCH',
  body: body,
  fallbackMethods: const ['PATCH', 'PUT', 'POST'],
);
