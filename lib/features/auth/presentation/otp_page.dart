import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../notifications/push_registration.dart';
import '../data/auth_repository.dart';
import '../data/auth_validators.dart';
import 'auth_navigation.dart';
import 'auth_providers.dart';
import 'widgets/auth_feedback.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key, this.phone});

  final String? phone;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _rememberSession = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final cachedPhone =
        widget.phone ??
        await ref.read(authRepositoryProvider).readCachedPhone();
    if (cachedPhone != null && cachedPhone.isNotEmpty) {
      _phoneController.text = cachedPhone;
    }
    await ref.read(otpFlowProvider.notifier).bootstrap(_phoneController.text);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    final phoneError = AuthValidators.validatePhone(
      phone,
      requiredMessage: l10n.fieldRequired,
      invalidMessage: l10n.authInvalidPhone,
    );
    if (phoneError != null) {
      setState(() => _localError = phoneError);
      return;
    }
    setState(() => _localError = null);
    final error = await ref.read(otpFlowProvider.notifier).requestOtp(phone);
    if (error == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.otpSent)));
    }
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    final otpState = ref.read(otpFlowProvider);
    final phone = otpState.phone ?? _phoneController.text.trim();
    final code = _otpController.text.trim();

    final validationError =
        AuthValidators.validatePhone(
          phone,
          requiredMessage: l10n.fieldRequired,
          invalidMessage: l10n.authInvalidPhone,
        ) ??
        AuthValidators.validateOtp(
          code,
          requiredMessage: l10n.fieldRequired,
          invalidMessage: l10n.authInvalidOtp,
        );
    if (validationError != null) {
      setState(() => _localError = validationError);
      return;
    }

    setState(() => _localError = null);
    ref.read(otpFlowProvider.notifier).setLoading(true);

    final pushToken = await ref.read(pushRegistrationProvider).fetchPushToken();
    final result = await ref
        .read(authRepositoryProvider)
        .verifyOtp(
          phone: phone,
          code: code,
          pushToken: pushToken,
          rememberSession: _rememberSession,
        );

    ref.read(otpFlowProvider.notifier).setLoading(false);

    result.when(
      success: (_) async {
        ref.read(otpFlowProvider.notifier).reset();
        if (mounted) await navigateAfterAuth(context, ref);
      },
      failure: (error) => setState(() => _localError = error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final otpState = ref.watch(otpFlowProvider);
    final error = _localError ?? otpState.errorMessage ?? '';
    final codeSent = otpState.hasActiveOtp;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authTabOtp)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorBanner(message: error),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneLabel),
              enabled: !otpState.loading && !codeSent,
            ),
            if (codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.otpCodeLabel),
                enabled: !otpState.loading,
              ),
              const SizedBox(height: 8),
              if (otpState.resendSecondsLeft > 0)
                AuthEmptyHint(
                  message: l10n.otpResendWait(otpState.resendSecondsLeft),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: otpState.canResend ? _sendOtp : null,
                    child: Text(l10n.otpResend),
                  ),
                ),
              TextButton(
                onPressed: otpState.loading
                    ? null
                    : () {
                        ref.read(otpFlowProvider.notifier).reset();
                        _otpController.clear();
                      },
                child: Text(l10n.otpChangePhone),
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.rememberSession),
              value: _rememberSession,
              onChanged: otpState.loading
                  ? null
                  : (value) => setState(() => _rememberSession = value ?? true),
            ),
            const SizedBox(height: 16),
            AuthLoadingButton(
              loading: otpState.loading,
              label: codeSent ? l10n.verifyOtp : l10n.sendOtp,
              onPressed: codeSent ? _verify : _sendOtp,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text(l10n.authUsePassword),
            ),
          ],
        ),
      ),
    );
  }
}
