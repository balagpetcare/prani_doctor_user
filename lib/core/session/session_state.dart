import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_state.freezed.dart';

@freezed
class SessionState with _$SessionState {
  const factory SessionState({
    @Default(false) bool isAuthenticated,

    /// True after cold-start restore or a login/logout mutation finished.
    @Default(false) bool sessionReady,
    String? userId,
    String? displayName,
    String? phone,
  }) = _SessionState;
}
