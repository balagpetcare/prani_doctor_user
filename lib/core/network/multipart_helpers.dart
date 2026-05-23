import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/http_error_mapper.dart';
import 'api_envelope.dart';

Future<Map<String, dynamic>> patchMultipart(
  Dio dio,
  String path,
  FormData formData, {
  required String logTag,
  Duration? timeout,
}) async {
  if (kDebugMode) {
    debugPrint('[${logTag}_REQ] METHOD=PATCH URL=$path (multipart/form-data)');
  }
  try {
    final response = await dio.patch<dynamic>(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );
    if (kDebugMode) {
      debugPrint('[${logTag}_RES] STATUS=${response.statusCode} URL=$path');
    }
    return ApiEnvelope.unwrapData(response);
  } on DioException catch (e) {
    if (kDebugMode) {
      debugPrint('[${logTag}_RES] ERROR status=${e.response?.statusCode}');
    }
    throw HttpErrorMapper.fromDio(e);
  }
}
