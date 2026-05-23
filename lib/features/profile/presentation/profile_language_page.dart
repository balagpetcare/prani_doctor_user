import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../data/mobile_me_dto.dart';
import 'profile_providers.dart';
import 'widgets/profile_feedback.dart';

class ProfileLanguagePage extends ConsumerStatefulWidget {
  const ProfileLanguagePage({super.key});

  @override
  ConsumerState<ProfileLanguagePage> createState() =>
      _ProfileLanguagePageState();
}

class _ProfileLanguagePageState extends ConsumerState<ProfileLanguagePage> {
  String? _selected;
  bool _loading = false;
  String? _error;

  Future<void> _save(String locale) async {
    setState(() {
      _loading = true;
      _error = null;
      _selected = locale;
    });

    final error = await ref
        .read(mobileMeProvider.notifier)
        .save(PatchMobileMeInput(locale: locale));

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      context.pop();
      return;
    }

    if (error.contains('offline')) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.savedOffline)));
      context.pop();
      return;
    }

    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);
    final current = _selected ?? profileAsync.value?.locale ?? 'bn-BD';

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.languageTitle)),
      body: profileAsync.when(
        loading: ProfileFeedback.loading,
        error: (e, _) => ProfileFeedback.errorFromObject(
          context,
          failure: e,
          onRetry: () =>
              ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileFeedback.banner(context, _error ?? ''),
                RadioListTile<String>(
                  title: Text(l10n.languageBangla),
                  value: 'bn-BD',
                  groupValue: current,
                  onChanged: _loading ? null : (value) => _save(value!),
                ),
                RadioListTile<String>(
                  title: Text(l10n.languageEnglish),
                  value: 'en-US',
                  groupValue: current,
                  onChanged: _loading ? null : (value) => _save(value!),
                ),
                if (_loading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
