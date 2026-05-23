import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../profile/data/mobile_me_dto.dart';
import '../../profile/data/profile_validation.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/presentation/widgets/profile_feedback.dart';

/// Email and phone — separate from profile appearance (media + display name).
class SettingsPersonalInfoPage extends ConsumerStatefulWidget {
  const SettingsPersonalInfoPage({super.key});

  @override
  ConsumerState<SettingsPersonalInfoPage> createState() =>
      _SettingsPersonalInfoPageState();
}

class _SettingsPersonalInfoPageState
    extends ConsumerState<SettingsPersonalInfoPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _init(MobileMeDto profile) {
    if (_initialized) return;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _initialized = true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final nameError = ProfileValidation.validateName(
      _nameController.text,
      requiredMessage: l10n.fieldRequired,
      tooLongMessage: l10n.profileNameTooLong,
    );
    if (nameError != null) {
      setState(() => _error = nameError);
      return;
    }
    final emailError = ProfileValidation.validateEmail(
      _emailController.text,
      invalidMessage: l10n.authInvalidEmail,
      tooLongMessage: l10n.profileEmailTooLong,
    );
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final patch = PatchMobileMeInput(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? ''
          : _emailController.text.trim(),
    );
    final err = await ref.read(mobileMeProvider.notifier).save(patch);
    if (!mounted) return;

    setState(() => _saving = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileUpdatedSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: const Text('Personal information')),
      body: profileAsync.when(
        loading: ProfileFeedback.editSkeleton,
        error: (e, _) => ProfileFeedback.errorFromObject(
          context,
          failure: e,
          onRetry: () =>
              ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);
          _init(profile);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ProfileFeedback.banner(context, _error ?? ''),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.nameLabel),
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.phoneLabel,
                  helperText: l10n.profilePhoneReadonly,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(profile.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.emailOptionalLabel),
                enabled: !_saving,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveProfile),
              ),
            ],
          );
        },
      ),
    );
  }
}
