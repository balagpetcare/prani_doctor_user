import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../../profile/data/mobile_me_dto.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../../profile/presentation/widgets/profile_hero_avatar.dart';
import '../../../profile/presentation/widgets/profile_media_image.dart';
import '../../data/dashboard_context_dto.dart';
import '../theme/home_tokens.dart';

class HomeUserHero extends ConsumerWidget {
  const HomeUserHero({super.key, required this.contextData});

  final DashboardContext contextData;

  String? _locationLabel(MobileMeDto? profile) {
    final fromProfile = profile?.area?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    final village = profile?.address?.villageName?.trim();
    if (village != null && village.isNotEmpty) return village;
    return contextData.farmSummary?.primaryVillageLabelBn;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profileAsync = ref.watch(mobileMeProvider);
    final fallback = contextData.user;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          HomeTokens.space16,
          HomeTokens.space8,
          HomeTokens.space16,
          0,
        ),
        child: profileAsync.when(
          loading: () => _HeroFrame(
            greeting: _greeting(l10n),
            name: fallback.name.isNotEmpty ? fallback.name : l10n.navHome,
            location: _locationLabel(null),
            coverUrl: null,
            avatarUrl: fallback.avatarUrl,
            avatarThumb: null,
            onProfileMenu: () => _openProfileMenu(context),
          ),
          error: (_, _) => _HeroFrame(
            greeting: _greeting(l10n),
            name: fallback.name.isNotEmpty ? fallback.name : l10n.navHome,
            location: _locationLabel(null),
            coverUrl: null,
            avatarUrl: fallback.avatarUrl,
            avatarThumb: null,
            onProfileMenu: () => _openProfileMenu(context),
          ),
          data: (profile) {
            final name = profile?.name.isNotEmpty == true
                ? profile!.name
                : (fallback.name.isNotEmpty ? fallback.name : l10n.navHome);
            return _HeroFrame(
              greeting: _greeting(l10n),
              name: name,
              location: _locationLabel(profile),
              coverUrl: profile?.coverImageUrl,
              avatarUrl: profile?.profilePhotoUrl ?? fallback.avatarUrl,
              avatarThumb: profile?.profilePhotoThumbUrl,
              onProfileMenu: () => _openProfileMenu(context),
            );
          },
        ),
      ),
    );
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorningBn;
    if (hour < 17) return l10n.homeGreetingAfternoonBn;
    return l10n.homeGreetingEveningBn;
  }

  void _openProfileMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editProfile),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.settingsProfileEdit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.homeChangeCover),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.settingsProfileEdit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.profileTitle),
              onTap: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.settingsProfile);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFrame extends StatelessWidget {
  const _HeroFrame({
    required this.greeting,
    required this.name,
    required this.location,
    required this.coverUrl,
    required this.avatarUrl,
    required this.avatarThumb,
    required this.onProfileMenu,
  });

  final String greeting;
  final String name;
  final String? location;
  final String? coverUrl;
  final String? avatarUrl;
  final String? avatarThumb;
  final VoidCallback onProfileMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(HomeTokens.radiusLg),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null && coverUrl!.isNotEmpty)
              ProfileMediaImage(
                url: coverUrl,
                thumbUrl: coverUrl,
                fallbackText: name,
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
                      theme.colorScheme.primaryContainer,
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
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(HomeTokens.space16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          greeting,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: HomeTokens.space4),
                        Text(
                          name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (location != null && location!.isNotEmpty) ...[
                          const SizedBox(height: HomeTokens.space4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: HomeTokens.space4),
                              Expanded(
                                child: Text(
                                  location!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: HomeTokens.space8),
                  Material(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(HomeTokens.radiusXl),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onProfileMenu,
                      child: Padding(
                        padding: const EdgeInsets.all(HomeTokens.space4),
                        child: ProfileHeroAvatar(
                          displayName: name,
                          photoUrl: avatarUrl,
                          thumbUrl: avatarThumb,
                          radius: 28,
                          onTap: onProfileMenu,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
