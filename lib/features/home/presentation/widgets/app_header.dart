import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/branding/brand_assets.dart';
import '../../../../core/branding/brand_image.dart';
import '../../../../routing/app_routes.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../../profile/presentation/widgets/profile_hero_avatar.dart';
import '../../data/dashboard_context_dto.dart';
import '../home_analytics.dart';
import '../theme/home_tokens.dart';

class HomeAppHeader extends ConsumerWidget {
  const HomeAppHeader({super.key, required this.contextData});

  final DashboardContext contextData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);
    final unread = ref
        .watch(unreadNotificationCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);

    final fallbackUser = contextData.user;
    final profile = profileAsync.valueOrNull;
    final displayName = profile?.name.isNotEmpty == true
        ? profile!.name
        : fallbackUser.name;
    final avatarUrl = profile?.profileImageUrl ?? fallbackUser.avatarUrl;

    return SliverSafeArea(
      top: true,
      bottom: false,
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            elevation: HomeTokens.elevationNone,
            scrolledUnderElevation: HomeTokens.elevationLow,
            toolbarHeight: kToolbarHeight,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              tooltip: l10n.drawerTitle,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Semantics(
              label: l10n.navHome,
              child: BrandImage.logo(
                asset: BrandAssets.primaryLogoPath,
                height: 32,
              ),
            ),
            centerTitle: true,
            actions: [
              Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: IconButton(
                  onPressed: () {
                    HomeAnalytics.navigate(AppRoutes.inbox);
                    context.go(AppRoutes.inbox);
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: l10n.dashboardNotifications,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: HomeTokens.space8,
                ),
                child: ProfileHeroAvatar(
                  displayName: displayName,
                  photoUrl: avatarUrl,
                  thumbUrl: profile?.profilePhotoThumbUrl,
                  radius: 18,
                  semanticLabel: displayName,
                  onTap: () {
                    HomeAnalytics.navigate(AppRoutes.settingsProfile);
                    context.go(AppRoutes.settingsProfile);
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                HomeTokens.space16,
                HomeTokens.space4,
                HomeTokens.space16,
                HomeTokens.space8,
              ),
              child: _HomeSearchBar(
                placeholder: l10n.homeSearchPlaceholder,
                onTap: () {
                  HomeAnalytics.navigate(AppRoutes.search);
                  context.push(AppRoutes.search);
                },
                onVoiceTap: () {
                  HomeAnalytics.navigate('${AppRoutes.search}?voice=1');
                  context.push('${AppRoutes.search}?voice=1');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({
    required this.placeholder,
    required this.onTap,
    required this.onVoiceTap,
  });

  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: placeholder,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(HomeTokens.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeTokens.space12,
              vertical: HomeTokens.space12,
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: theme.colorScheme.outline),
                const SizedBox(width: HomeTokens.space8),
                Expanded(
                  child: Text(
                    placeholder,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onVoiceTap,
                  icon: const Icon(Icons.mic_outlined),
                  tooltip: 'Voice search',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
