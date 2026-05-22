import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../data/mobile_me_dto.dart';
import '../data/profile_validation.dart';
import 'profile_providers.dart';
import 'widgets/profile_feedback.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _uploading = false;
  bool _initialized = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initFromProfile(MobileMeDto profile) {
    if (_initialized) return;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _initialized = true;
  }

  Future<void> _pickAvatar(MobileMeDto profile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    final uploadError =
        await ref.read(mobileMeProvider.notifier).uploadAvatar(picked.path);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (uploadError != null) {
      setState(() => _error = uploadError);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final nameError =
        ProfileValidation.validateName(_nameController.text, requiredMessage: l10n.fieldRequired);
    final emailError = ProfileValidation.validateEmail(_emailController.text);
    final validationError = nameError ?? emailError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final patch = PatchMobileMeInput(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
    final error = await ref.read(mobileMeProvider.notifier).save(patch);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      context.pop();
      return;
    }

    if (error == l10n.savedOffline || error.contains('offline')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedOffline)),
      );
      context.pop();
      return;
    }

    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
      body: profileAsync.when(
        loading: () => ProfileFeedback.loading(),
        error: (_, __) => ProfileFeedback.error(
          context,
          onRetry: () => ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);
          _initFromProfile(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileFeedback.banner(context, _error ?? ''),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ProfileAvatar(
                        photoUrl: profile.profilePhotoUrl,
                        name: profile.name,
                        radius: 48,
                      ),
                      IconButton.filledTonal(
                        onPressed: _uploading || _loading
                            ? null
                            : () => _pickAvatar(profile),
                        icon: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.nameLabel),
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
                Text(profile.phone, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveProfile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
