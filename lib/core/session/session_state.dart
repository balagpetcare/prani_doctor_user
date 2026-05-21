import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_state.freezed.dart';

@freezed
class SessionState with _$SessionState {
  const factory SessionState({
    @Default(false) bool isAuthenticated,
    String? userId,
    String? displayName,
  }) = _SessionState;
}
