import 'package:dio/dio.dart';

import 'api_envelope.dart';

Future<Map<String, dynamic>> postJson(
  Dio dio,
  String path,
  Map<String, dynamic> body,
) async {
  try {
    final response = await dio.post<dynamic>(path, data: body);
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}

Future<Map<String, dynamic>> patchJson(
  Dio dio,
  String path,
  Map<String, dynamic> body,
) async {
  try {
    final response = await dio.patch<dynamic>(path, data: body);
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}

Future<Map<String, dynamic>> getJson(
  Dio dio,
  String path, {
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    final response = await dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
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
}) async {
  try {
    final response = await dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return (
      data: ApiEnvelope.unwrapListData(response),
      meta: ApiEnvelope.unwrapMeta(response),
    );
  } on DioException catch (e) {
    throw ApiEnvelope.fromDioException(e);
  }
}
