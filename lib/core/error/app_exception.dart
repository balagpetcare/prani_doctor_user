import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_exception.freezed.dart';

@freezed
class AppException with _$AppException {
  const factory AppException({
    required String message,
    String? code,
    Object? cause,
  }) = _AppException;
}
