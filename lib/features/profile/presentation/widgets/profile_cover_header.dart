import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/mobile_me_dto.dart';
import 'profile_hero_avatar.dart';
import 'profile_media_image.dart';

class ProfileCoverHeader extends StatelessWidget {
  const ProfileCoverHeader({
    super.key,
    required this.profile,
    required this.l10n,
    required this.onEditAvatar,
    required this.onEditCover,
    required this.onSettings,
  });

  final MobileMeDto profile;
  final AppLocalizations l10n;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditCover;
  final VoidCallback onSettings;

  static const coverHeight = 240.0;

  String? get _location {
    final area = profile.area?.trim();
    if (area != null && area.isNotEmpty) return area;
    return profile.address?.villageName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = profile.coverImageUrl;

    return SizedBox(
      height: coverHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            ProfileMediaImage(
              url: profile.coverPhotoUrl,
              thumbUrl: profile.coverPhotoThumbUrl,
              fallbackText: profile.name,
              placeholderIcon: Icons.landscape_outlined,
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiaryContainer,
                  ],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderAction(
                  icon: Icons.edit_outlined,
                  label: l10n.editProfile,
                  onTap: () => context.push(AppRoutes.settingsProfileEdit),
                ),
                const SizedBox(width: 4),
                _HeaderAction(
                  icon: Icons.image_outlined,
                  label: l10n.homeChangeCover,
                  onTap: onEditCover,
                ),
                const SizedBox(width: 4),
                _HeaderAction(
                  icon: Icons.settings_outlined,
                  label: l10n.navSettings,
                  onTap: onSettings,
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onEditAvatar,
                  child: ProfileHeroAvatar(
                    displayName: profile.name,
                    photoUrl: profile.profilePhotoUrl,
                    thumbUrl: profile.profilePhotoThumbUrl,
                    radius: 42,
                    onTap: onEditAvatar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_location != null && _location!.isNotEmpty)
                        Text(
                          _location!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        l10n.profileMemberSince,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
