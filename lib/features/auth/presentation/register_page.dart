import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../notifications/push_registration.dart';
import '../data/auth_repository.dart';
import 'auth_navigation.dart';
import 'widgets/auth_feedback.dart';
import 'widgets/social_login_buttons.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool _loading = false;
  bool _rememberSession = true;
  String? _error;

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;
    final email = _emailController.text.trim();

    if (name.isEmpty || mobile.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pushToken = await ref.read(pushRegistrationProvider).fetchPushToken();
      final result = await ref.read(authRepositoryProvider).register(
            name: name,
            mobile: mobile,
            password: password,
            email: email.isEmpty ? null : email,
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
      appBar: AppBar(title: Text(l10n.registerTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorBanner(message: _error ?? ''),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.nameLabel),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneLabel),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailOptionalLabel),
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.passwordLabel),
              enabled: !_loading,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.rememberSession),
              value: _rememberSession,
              onChanged:
                  _loading ? null : (v) => setState(() => _rememberSession = v ?? true),
            ),
            const SizedBox(height: 8),
            AuthLoadingButton(
              loading: _loading,
              label: l10n.createAccount,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            const SocialLoginButtons(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.hasAccountPrompt),
                TextButton(
                  onPressed: _loading ? null : () => context.go(AppRoutes.login),
                  child: Text(l10n.loginLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
