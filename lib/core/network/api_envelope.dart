import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../error/http_error_mapper.dart';

/// Parses legacy compat `{ ok, data }` and foundation `{ success, data }` responses.
class ApiEnvelope {
  ApiEnvelope._();

  static bool isSuccess(Map<String, dynamic> body) {
    return body['ok'] == true || body['success'] == true;
  }

  static Map<String, dynamic> unwrapData(Response<dynamic> response) {
    final body = _bodyMap(response);
    if (isSuccess(body)) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data == null) return {};
      throw const AppException(message: 'Expected object payload');
    }
    throw exceptionFromBody(body, response.statusCode);
  }

  static List<dynamic> unwrapListData(Response<dynamic> response) {
    final body = _bodyMap(response);
    if (isSuccess(body)) {
      final data = body['data'];
      if (data is List) return data;
      throw const AppException(message: 'Expected list payload');
    }
    throw exceptionFromBody(body, response.statusCode);
  }

  static Map<String, dynamic>? unwrapMeta(Response<dynamic> response) {
    final body = _bodyMap(response);
    final meta = body['meta'];
    if (meta is Map<String, dynamic>) return meta;
    return null;
  }

  static AppException exceptionFromBody(
    Map<String, dynamic> body, [
    int? statusCode,
  ]) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'] as String? ?? 'Request failed';
      final code = error['code'] as String?;
      return AppException(
        message: message,
        code: code ?? statusCode?.toString(),
      );
    }
    return AppException(
      message: 'Request failed',
      code: statusCode?.toString(),
    );
  }

  static AppException fromDioException(DioException error) {
    final response = error.response;
    final data = response?.data;
    if (data is Map<String, dynamic> &&
        (data['ok'] == false || data['success'] == false)) {
      return exceptionFromBody(data, response?.statusCode);
    }
    return HttpErrorMapper.fromDio(error);
  }

  static Map<String, dynamic> _bodyMap(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const AppException(message: 'Invalid response format');
    }
    return body;
  }
}
