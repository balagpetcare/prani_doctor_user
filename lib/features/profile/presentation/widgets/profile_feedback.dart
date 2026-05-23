import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/error/http_error_mapper.dart';
import 'profile_edit_skeleton.dart';

class ProfileFeedback {
  ProfileFeedback._();

  static Widget loading() => const Center(child: CircularProgressIndicator());

  static Widget editSkeleton() {
    return const ProfileEditSkeleton();
  }

  static Widget error(BuildContext context, {required VoidCallback onRetry}) {
    return errorFromObject(context, failure: null, onRetry: onRetry);
  }

  static Widget errorFromObject(
    BuildContext context, {
    required Object? failure,
    required VoidCallback onRetry,
  }) {
    if (kDebugMode && failure != null) {
      HttpErrorMapper.logDeveloper(failure, tag: 'PROFILE');
    }
    final l10n = AppLocalizations.of(context)!;
    final title = failure != null
        ? HttpErrorMapper.profileErrorTitle(failure)
        : HttpErrorMapper.profileLoadTitle;
    final subtitle = failure != null
        ? HttpErrorMapper.profileErrorMessage(failure)
        : HttpErrorMapper.genericSubtitle;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.bootRetry)),
          ],
        ),
      ),
    );
  }

  static Widget empty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Text(l10n.profileEmpty));
  }

  static Widget banner(BuildContext context, String message) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 40,
    this.onTap,
  });

  final String? photoUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
      child: photoUrl == null || photoUrl!.isEmpty ? Text(initials) : null,
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
