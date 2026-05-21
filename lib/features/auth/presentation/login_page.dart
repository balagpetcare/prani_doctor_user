import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../notifications/push_registration.dart';
import '../data/auth_repository.dart';

enum _AuthMode { otp, password }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  _AuthMode _mode = _AuthMode.otp;
  bool _loading = false;
  bool _otpSent = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authRepositoryProvider);

    setState(() => _loading = true);
    try {
      if (_mode == _AuthMode.otp) {
        final phone = _phoneController.text.trim();
        if (phone.isEmpty) {
          _showError(l10n.fieldRequired);
          return;
        }
        if (!_otpSent) {
          final result = await auth.requestOtp(phone);
          result.when(
            success: (_) {
              setState(() => _otpSent = true);
              _showMessage(l10n.otpSent);
            },
            failure: (e) => _showError(e.message),
          );
          return;
        }
        final code = _otpController.text.trim();
        if (code.isEmpty) {
          _showError(l10n.fieldRequired);
          return;
        }
        final pushToken = await ref.read(pushRegistrationProvider).fetchPushToken();
        final result = await auth.verifyOtp(phone: phone, code: code, pushToken: pushToken);
        result.when(
          success: (_) => _goHome(),
          failure: (e) => _showError(e.message),
        );
      } else {
        final identifier = _identifierController.text.trim();
        final password = _passwordController.text;
        if (identifier.isEmpty || password.isEmpty) {
          _showError(l10n.fieldRequired);
          return;
        }
        final pushToken = await ref.read(pushRegistrationProvider).fetchPushToken();
        final result = await auth.loginWithPassword(
          identifier: identifier,
          password: password,
          pushToken: pushToken,
        );
        result.when(
          success: (_) => _goHome(),
          failure: (e) => _showError(e.message),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goHome() {
    if (mounted) context.go(AppRoutes.home);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_AuthMode>(
              segments: [
                ButtonSegment(value: _AuthMode.otp, label: Text(l10n.authTabOtp)),
                ButtonSegment(
                  value: _AuthMode.password,
                  label: Text(l10n.authTabPassword),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) {
                setState(() {
                  _mode = value.first;
                  _otpSent = false;
                });
              },
            ),
            const SizedBox(height: 24),
            if (_mode == _AuthMode.otp) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneLabel),
                enabled: !_loading && !_otpSent,
              ),
              if (_otpSent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.otpCodeLabel),
                  enabled: !_loading,
                ),
              ],
            ] else ...[
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.identifierLabel),
                enabled: !_loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                enabled: !_loading,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _mode == _AuthMode.otp
                          ? (_otpSent ? l10n.verifyOtp : l10n.sendOtp)
                          : l10n.signIn,
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.noAccountPrompt),
                TextButton(
                  onPressed: _loading ? null : () => context.go(AppRoutes.register),
                  child: Text(l10n.registerLink),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await ref
                            .read(sessionControllerProvider.notifier)
                            .signInDevPlaceholder();
                        if (mounted) _goHome();
                        if (mounted) setState(() => _loading = false);
                      },
                child: Text(l10n.loginDevContinue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
