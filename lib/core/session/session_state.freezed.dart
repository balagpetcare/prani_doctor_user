// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SessionState {
  bool get isAuthenticated => throw _privateConstructorUsedError;

  /// True after cold-start restore or a login/logout mutation finished.
  bool get sessionReady => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionStateCopyWith<SessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionStateCopyWith<$Res> {
  factory $SessionStateCopyWith(
    SessionState value,
    $Res Function(SessionState) then,
  ) = _$SessionStateCopyWithImpl<$Res, SessionState>;
  @useResult
  $Res call({
    bool isAuthenticated,
    bool sessionReady,
    String? userId,
    String? displayName,
    String? phone,
  });
}

/// @nodoc
class _$SessionStateCopyWithImpl<$Res, $Val extends SessionState>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAuthenticated = null,
    Object? sessionReady = null,
    Object? userId = freezed,
    Object? displayName = freezed,
    Object? phone = freezed,
  }) {
    return _then(
      _value.copyWith(
            isAuthenticated: null == isAuthenticated
                ? _value.isAuthenticated
                : isAuthenticated // ignore: cast_nullable_to_non_nullable
                      as bool,
            sessionReady: null == sessionReady
                ? _value.sessionReady
                : sessionReady // ignore: cast_nullable_to_non_nullable
                      as bool,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionStateImplCopyWith<$Res>
    implements $SessionStateCopyWith<$Res> {
  factory _$$SessionStateImplCopyWith(
    _$SessionStateImpl value,
    $Res Function(_$SessionStateImpl) then,
  ) = __$$SessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isAuthenticated,
    bool sessionReady,
    String? userId,
    String? displayName,
    String? phone,
  });
}

/// @nodoc
class __$$SessionStateImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionStateImpl>
    implements _$$SessionStateImplCopyWith<$Res> {
  __$$SessionStateImplCopyWithImpl(
    _$SessionStateImpl _value,
    $Res Function(_$SessionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAuthenticated = null,
    Object? sessionReady = null,
    Object? userId = freezed,
    Object? displayName = freezed,
    Object? phone = freezed,
  }) {
    return _then(
      _$SessionStateImpl(
        isAuthenticated: null == isAuthenticated
            ? _value.isAuthenticated
            : isAuthenticated // ignore: cast_nullable_to_non_nullable
                  as bool,
        sessionReady: null == sessionReady
            ? _value.sessionReady
            : sessionReady // ignore: cast_nullable_to_non_nullable
                  as bool,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SessionStateImpl implements _SessionState {
  const _$SessionStateImpl({
    this.isAuthenticated = false,
    this.sessionReady = false,
    this.userId,
    this.displayName,
    this.phone,
  });

  @override
  @JsonKey()
  final bool isAuthenticated;

  /// True after cold-start restore or a login/logout mutation finished.
  @override
  @JsonKey()
  final bool sessionReady;
  @override
  final String? userId;
  @override
  final String? displayName;
  @override
  final String? phone;

  @override
  String toString() {
    return 'SessionState(isAuthenticated: $isAuthenticated, sessionReady: $sessionReady, userId: $userId, displayName: $displayName, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionStateImpl &&
            (identical(other.isAuthenticated, isAuthenticated) ||
                other.isAuthenticated == isAuthenticated) &&
            (identical(other.sessionReady, sessionReady) ||
                other.sessionReady == sessionReady) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.phone, phone) || other.phone == phone));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isAuthenticated,
    sessionReady,
    userId,
    displayName,
    phone,
  );

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionStateImplCopyWith<_$SessionStateImpl> get copyWith =>
      __$$SessionStateImplCopyWithImpl<_$SessionStateImpl>(this, _$identity);
}

abstract class _SessionState implements SessionState {
  const factory _SessionState({
    final bool isAuthenticated,
    final bool sessionReady,
    final String? userId,
    final String? displayName,
    final String? phone,
  }) = _$SessionStateImpl;

  @override
  bool get isAuthenticated;

  /// True after cold-start restore or a login/logout mutation finished.
  @override
  bool get sessionReady;
  @override
  String? get userId;
  @override
  String? get displayName;
  @override
  String? get phone;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionStateImplCopyWith<_$SessionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
