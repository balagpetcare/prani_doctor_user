import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/session/session_controller.dart';
import '../../../routing/app_routes.dart';
import '../../notifications/push_registration.dart';
import '../data/auth_repository.dart';
import 'auth_navigation.dart';
import 'widgets/auth_feedback.dart';
import 'widgets/social_login_buttons.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _loading = false;
  bool _rememberSession = true;
  String? _error;

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pushToken = await ref.read(pushRegistrationProvider).fetchPushToken();
      final result = await ref.read(authRepositoryProvider).loginWithPassword(
            identifier: identifier,
            password: password,
            pushToken: pushToken,
            rememberSession: _rememberSession,
          );
      result.when(
        success: (_) {
          if (mounted) navigateAfterAuth(context, ref);
        },
        failure: (e) => setState(() => _error = e.message),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            AuthErrorBanner(message: _error ?? ''),
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
              onSubmitted: (_) => _submitPassword(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : () => context.go(AppRoutes.forgotPassword),
                child: Text(l10n.forgotPasswordLink),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.rememberSession),
              value: _rememberSession,
              onChanged:
                  _loading ? null : (v) => setState(() => _rememberSession = v ?? true),
            ),
            AuthLoadingButton(
              loading: _loading,
              label: l10n.signIn,
              onPressed: _submitPassword,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading ? null : () => context.go(AppRoutes.otp),
              child: Text(l10n.authSignInWithOtp),
            ),
            const SizedBox(height: 16),
            const SocialLoginButtons(),
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
                        if (mounted) context.go(AppRoutes.home);
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
