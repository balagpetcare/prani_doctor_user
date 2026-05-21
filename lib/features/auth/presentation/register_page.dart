import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool _loading = false;

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
      _showError(l10n.fieldRequired);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ref.read(authRepositoryProvider).register(
            name: name,
            mobile: mobile,
            password: password,
            email: email.isEmpty ? null : email,
          );
      result.when(
        success: (_) {
          if (mounted) context.go(AppRoutes.home);
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.createAccount),
            ),
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
