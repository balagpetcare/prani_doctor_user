import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_exception.dart';

part 'api_result.freezed.dart';

@freezed
class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult.success(T data) = ApiSuccess<T>;
  const factory ApiResult.failure(AppException error) = ApiFailure<T>;
}
