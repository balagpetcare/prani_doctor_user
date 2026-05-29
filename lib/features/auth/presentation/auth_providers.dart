import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_preferences.dart';
import '../data/auth_repository.dart';

class OtpFlowState {
  const OtpFlowState({
    this.phone,
    this.otpTtlSeconds = 0,
    this.resendSecondsLeft = 0,
    this.loading = false,
    this.errorMessage,
  });

  final String? phone;
  final int otpTtlSeconds;
  final int resendSecondsLeft;
  final bool loading;
  final String? errorMessage;

  bool get canResend => resendSecondsLeft <= 0 && !loading;
  bool get hasActiveOtp => phone != null && phone!.isNotEmpty;

  OtpFlowState copyWith({
    String? phone,
    int? otpTtlSeconds,
    int? resendSecondsLeft,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
    bool clearPhone = false,
  }) {
    return OtpFlowState(
      phone: clearPhone ? null : (phone ?? this.phone),
      otpTtlSeconds: otpTtlSeconds ?? this.otpTtlSeconds,
      resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Riverpod 2 [AutoDisposeNotifier] replacement for the previous
/// [StateNotifier]-based OTP flow. Timer lifecycle is managed via
/// [Ref.onDispose] so it is always cancelled when the provider is disposed
/// (auth flow complete / user navigates away).
class OtpFlowNotifier extends AutoDisposeNotifier<OtpFlowState> {
  Timer? _timer;

  @override
  OtpFlowState build() {
    ref.onDispose(() => _timer?.cancel());
    return const OtpFlowState();
  }

  Future<void> bootstrap(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final cached = await ref
        .read(authRepositoryProvider)
        .readCachedOtpRequest(phone);
    if (cached != null) {
      _startCountdown(cached.resendCooldownSeconds);
      state = state.copyWith(phone: phone, otpTtlSeconds: cached.otpTtlSeconds);
    }
  }

  Future<String?> requestOtp(String phone) async {
    state = state.copyWith(loading: true, clearError: true);
    final result = await ref.read(authRepositoryProvider).requestOtp(phone);
    return result.when(
      success: (dto) {
        _startCountdown(dto.resendCooldownSeconds);
        state = state.copyWith(
          phone: phone.trim(),
          otpTtlSeconds: dto.otpTtlSeconds,
          loading: false,
        );
        return null;
      },
      failure: (error) {
        state = state.copyWith(loading: false, errorMessage: error.message);
        return error.message;
      },
    );
  }

  Future<String?> resendOtp() async {
    final phone = state.phone;
    if (phone == null || !state.canResend) return null;
    return requestOtp(phone);
  }

  void setLoading(bool loading) {
    state = state.copyWith(loading: loading, clearError: loading);
  }

  void setError(String message) {
    state = state.copyWith(loading: false, errorMessage: message);
  }

  void reset() {
    _timer?.cancel();
    state = const OtpFlowState();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    state = state.copyWith(resendSecondsLeft: seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendSecondsLeft - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendSecondsLeft: 0);
      } else {
        state = state.copyWith(resendSecondsLeft: next);
      }
    });
  }
}

/// Scoped to the auth flow. State (phone, timer, loading flag) is
/// automatically discarded when the user leaves the OTP screen.
final otpFlowProvider = NotifierProvider.autoDispose<OtpFlowNotifier, OtpFlowState>(
  OtpFlowNotifier.new,
);

final welcomeSeenProvider = FutureProvider<bool>((ref) async {
  return ref.read(authPreferencesProvider).isWelcomeSeen();
});
