import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/branding/brand_assets.dart';
import '../../../core/branding/brand_image.dart';
import '../../../routing/app_routes.dart';
import '../../notifications/push_registration.dart';
import '../data/auth_preferences.dart';
import '../data/auth_repository.dart';
import '../data/auth_validators.dart';
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
  bool _obscurePassword = true;
  String? _error;
  String? _lastLoginHint;

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadLastLogin);
  }

  Future<void> _loadLastLogin() async {
    final lastPhone = await ref.read(authPreferencesProvider).lastPhone();
    if (!mounted || lastPhone == null || lastPhone.isEmpty) return;
    setState(() {
      _lastLoginHint = lastPhone;
      if (_identifierController.text.isEmpty) {
        _identifierController.text = lastPhone;
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final identifierError = AuthValidators.validateRequired(
      identifier,
      l10n.fieldRequired,
    );
    final passwordError = AuthValidators.validatePassword(
      password,
      requiredMessage: l10n.fieldRequired,
      weakMessage: l10n.authPasswordTooShort,
    );
    final validationError = identifierError ?? passwordError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pushToken = await ref
          .read(pushRegistrationProvider)
          .fetchPushToken();
      final result = await ref
          .read(authRepositoryProvider)
          .loginWithPassword(
            identifier: identifier,
            password: password,
            pushToken: pushToken,
            rememberSession: _rememberSession,
          );
      result.when(
        success: (_) async {
          if (identifier.contains('@')) {
            await ref.read(authPreferencesProvider).setLastPhone(identifier);
          } else {
            await ref.read(authPreferencesProvider).setLastPhone(identifier);
          }
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
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: BrandImage.logo(
                  asset: BrandAssets.primaryLogo,
                  height: 72,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.loginWelcomeBack,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginWelcomeSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_lastLoginHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.loginLastLogin(_lastLoginHint!),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 28),
              AuthErrorBanner(message: _error ?? ''),
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.identifierLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: _loading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                enabled: !_loading,
                onSubmitted: (_) => _submitPassword(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => context.go(AppRoutes.forgotPassword),
                  child: Text(l10n.forgotPasswordLink),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.rememberSession),
                value: _rememberSession,
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _rememberSession = v ?? true),
              ),
              const SizedBox(height: 8),
              AuthLoadingButton(
                loading: _loading,
                label: l10n.signIn,
                onPressed: _submitPassword,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : () => context.go(AppRoutes.otp),
                icon: const Icon(Icons.sms_outlined),
                label: Text(l10n.authSignInWithOtp),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.authGoogleComingSoon)),
                        );
                      },
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: Text(l10n.authGoogleSignIn),
              ),
              const SizedBox(height: 16),
              const SocialLoginButtons(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.noAccountPrompt),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => context.go(AppRoutes.register),
                    child: Text(l10n.registerLink),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
