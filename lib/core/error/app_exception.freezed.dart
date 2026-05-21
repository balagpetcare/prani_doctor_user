// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppException {
  String get message => throw _privateConstructorUsedError;
  String? get code => throw _privateConstructorUsedError;
  Object? get cause => throw _privateConstructorUsedError;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppExceptionCopyWith<AppException> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppExceptionCopyWith<$Res> {
  factory $AppExceptionCopyWith(
    AppException value,
    $Res Function(AppException) then,
  ) = _$AppExceptionCopyWithImpl<$Res, AppException>;
  @useResult
  $Res call({String message, String? code, Object? cause});
}

/// @nodoc
class _$AppExceptionCopyWithImpl<$Res, $Val extends AppException>
    implements $AppExceptionCopyWith<$Res> {
  _$AppExceptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? code = freezed,
    Object? cause = freezed,
  }) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            code: freezed == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String?,
            cause: freezed == cause ? _value.cause : cause,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppExceptionImplCopyWith<$Res>
    implements $AppExceptionCopyWith<$Res> {
  factory _$$AppExceptionImplCopyWith(
    _$AppExceptionImpl value,
    $Res Function(_$AppExceptionImpl) then,
  ) = __$$AppExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String? code, Object? cause});
}

/// @nodoc
class __$$AppExceptionImplCopyWithImpl<$Res>
    extends _$AppExceptionCopyWithImpl<$Res, _$AppExceptionImpl>
    implements _$$AppExceptionImplCopyWith<$Res> {
  __$$AppExceptionImplCopyWithImpl(
    _$AppExceptionImpl _value,
    $Res Function(_$AppExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? code = freezed,
    Object? cause = freezed,
  }) {
    return _then(
      _$AppExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        code: freezed == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String?,
        cause: freezed == cause ? _value.cause : cause,
      ),
    );
  }
}

/// @nodoc

class _$AppExceptionImpl implements _AppException {
  const _$AppExceptionImpl({required this.message, this.code, this.cause});

  @override
  final String message;
  @override
  final String? code;
  @override
  final Object? cause;

  @override
  String toString() {
    return 'AppException(message: $message, code: $code, cause: $cause)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.code, code) || other.code == code) &&
            const DeepCollectionEquality().equals(other.cause, cause));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    message,
    code,
    const DeepCollectionEquality().hash(cause),
  );

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppExceptionImplCopyWith<_$AppExceptionImpl> get copyWith =>
      __$$AppExceptionImplCopyWithImpl<_$AppExceptionImpl>(this, _$identity);
}

abstract class _AppException implements AppException {
  const factory _AppException({
    required final String message,
    final String? code,
    final Object? cause,
  }) = _$AppExceptionImpl;

  @override
  String get message;
  @override
  String? get code;
  @override
  Object? get cause;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppExceptionImplCopyWith<_$AppExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
