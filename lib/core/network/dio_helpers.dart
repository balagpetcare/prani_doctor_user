import 'package:dio/dio.dart';

import 'api_envelope.dart';

/// JSON request helpers that unwrap the standard `{ ok/success, data }`
/// envelope and convert [DioException]s into typed [AppException]s.
///
/// All helpers accept an optional [cancelToken] so callers (repositories) can
/// cancel in-flight requests (e.g. on widget disposal / search debounce).

Future<Map<String, dynamic>> postJson(
  Dio dio,
  String path,
  Map<String, dynamic> body, {
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.post<dynamic>(
      path,
      data: body,
      cancelToken: cancelToken,
    );
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}

Future<Map<String, dynamic>> patchJson(
  Dio dio,
  String path,
  Map<String, dynamic> body, {
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.patch<dynamic>(
      path,
      data: body,
      cancelToken: cancelToken,
    );
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}

Future<Map<String, dynamic>> putJson(
  Dio dio,
  String path,
  Map<String, dynamic> body, {
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.put<dynamic>(
      path,
      data: body,
      cancelToken: cancelToken,
    );
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}

Future<Map<String, dynamic>> deleteJson(
  Dio dio,
  String path, {
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.delete<dynamic>(path, cancelToken: cancelToken);
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}

Future<Map<String, dynamic>> getJson(
  Dio dio,
  String path, {
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}

Future<({List<dynamic> data, Map<String, dynamic>? meta})> getJsonList(
  Dio dio,
  String path, {
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
    return (
      data: ApiEnvelope.unwrapListData(response),
      meta: ApiEnvelope.unwrapMeta(response),
    );
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}
