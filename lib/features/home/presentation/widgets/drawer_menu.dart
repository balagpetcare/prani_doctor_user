import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../routing/app_routes.dart';
import '../../../auth/presentation/auth_logout.dart';
import '../../../doctors/data/doctor_repository.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../profile/data/mobile_me_dto.dart';
import '../../../farm/presentation/farm_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../../profile/presentation/widgets/profile_hero_avatar.dart';

class HomeDrawerMenu extends ConsumerStatefulWidget {
  const HomeDrawerMenu({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeDrawerMenu> createState() => _HomeDrawerMenuState();
}

class _HomeDrawerMenuState extends ConsumerState<HomeDrawerMenu> {
  bool _farmExpanded = false;

  void _closeDrawer(BuildContext context) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _goToTab(BuildContext context, int branchIndex, String route) {
    _closeDrawer(context);
    widget.navigationShell.goBranch(branchIndex, initialLocation: true);
    context.go(route);
  }

  void _pushRoute(BuildContext context, String route) {
    _closeDrawer(context);
    context.push(route);
  }

  void _openServicesTab(BuildContext context, {bool emergencyOnly = false}) {
    _closeDrawer(context);
    if (emergencyOnly) {
      ref.read(doctorDiscoveryFiltersProvider.notifier).state =
          const DoctorDiscoveryFilters(emergencyOnly: true);
      ref.invalidate(doctorListProvider);
    }
    widget.navigationShell.goBranch(1, initialLocation: true);
    context.go(AppRoutes.services);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profileAsync = ref.watch(mobileMeProvider);
    final unread = ref
        .watch(unreadNotificationCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerHeader(
                    profileAsync: profileAsync,
                    l10n: l10n,
                    onEditProfile: () =>
                        _pushRoute(context, AppRoutes.settingsProfileEdit),
                  ),
                  const Divider(height: 1),
                  _DrawerTile(
                    icon: Icons.dashboard_outlined,
                    title: l10n.homeDrawerDashboard,
                    onTap: () => _goToTab(context, 0, AppRoutes.home),
                  ),
                  _DrawerTile(
                    icon: Icons.pets_outlined,
                    title: l10n.animalListTitle,
                    onTap: () => _pushRoute(context, AppRoutes.animals),
                  ),
                  _DrawerTile(
                    icon: Icons.agriculture_outlined,
                    title: l10n.t('ecosystemHubTitle'),
                    onTap: () => _pushRoute(context, AppRoutes.ecosystemHub),
                  ),
                  _DrawerTile(
                    icon: Icons.event_available_outlined,
                    title: l10n.dashboardUpcomingAppointments,
                    onTap: () => _goToTab(context, 2, AppRoutes.inbox),
                  ),
                  _DrawerTile(
                    icon: Icons.vaccines_outlined,
                    title: l10n.vaccineDashboardTitle,
                    onTap: () => _pushRoute(context, AppRoutes.vaccines),
                  ),
                  _DrawerTile(
                    icon: Icons.medical_services_outlined,
                    title: l10n.treatmentListTitle,
                    onTap: () => _pushRoute(context, AppRoutes.treatments),
                  ),
                  _DrawerTile(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.t('inventoryTitle'),
                    onTap: () => _pushRoute(context, AppRoutes.inventory),
                  ),
                  _DrawerTile(
                    icon: Icons.history_outlined,
                    title: l10n.homeHealthHistoryAction,
                    onTap: () => _pushRoute(context, AppRoutes.healthHistory),
                  ),
                  _DrawerTile(
                    icon: Icons.psychology_outlined,
                    title: l10n.dashboardAskAi,
                    onTap: () => _pushRoute(context, AppRoutes.ai),
                  ),
                  _DrawerTile(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.homeDrawerOrders,
                    onTap: () => _pushRoute(context, AppRoutes.orders),
                  ),
                  _DrawerTile(
                    icon: Icons.storefront_outlined,
                    title: l10n.homeMarketplaceTitle,
                    onTap: () => _pushRoute(context, AppRoutes.marketplace),
                  ),
                  _DrawerTile(
                    icon: Icons.groups_outlined,
                    title: l10n.homeCommunityTitle,
                    onTap: () => _pushRoute(context, AppRoutes.community),
                  ),
                  _DrawerTile(
                    icon: Icons.assessment_outlined,
                    title: l10n.financeReportsTitle,
                    onTap: () => _pushRoute(context, AppRoutes.financeReports),
                  ),
                  _DrawerTile(
                    icon: Icons.payments_outlined,
                    title: l10n.homeDrawerPayments,
                    onTap: () => _pushRoute(context, AppRoutes.finance),
                  ),
                  _DrawerTile(
                    icon: Icons.support_agent_outlined,
                    title: l10n.dashboardSupportTitle,
                    onTap: () => _pushRoute(context, AppRoutes.support),
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    title: l10n.navSettings,
                    onTap: () => _goToTab(context, 3, AppRoutes.settings),
                  ),
                  const Divider(),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _farmExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: ListTile(
                      leading: const Icon(Icons.agriculture_outlined),
                      title: Text(l10n.drawerFarmSection),
                      trailing: const Icon(Icons.expand_more),
                      onTap: () => setState(() => _farmExpanded = true),
                    ),
                    secondChild: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.agriculture_outlined),
                          title: Text(l10n.drawerFarmSection),
                          trailing: IconButton(
                            icon: const Icon(Icons.expand_less),
                            onPressed: () =>
                                setState(() => _farmExpanded = false),
                          ),
                        ),
                        ListTile(
                          title: Text(l10n.farmListTitle),
                          onTap: () => _pushRoute(context, AppRoutes.farms),
                        ),
                        ListTile(
                          title: Text(l10n.farmCreateTitle),
                          onTap: () =>
                              _pushRoute(context, AppRoutes.farmCreate),
                        ),
                        ListTile(
                          title: Text(l10n.feedEntryTitle),
                          onTap: () => _pushRoute(context, AppRoutes.feeds),
                        ),
                        ListTile(
                          title: Text(l10n.t('inventoryFeedStock')),
                          onTap: () {
                            final farmId = ref
                                .read(activeFarmIdProvider)
                                .valueOrNull;
                            if (farmId != null && farmId.isNotEmpty) {
                              _pushRoute(context, AppRoutes.inventoryFeed);
                            } else {
                              _pushRoute(context, AppRoutes.inventory);
                            }
                          },
                        ),
                        ListTile(
                          title: Text(l10n.t('inventoryMedicineStock')),
                          onTap: () {
                            final farmId = ref
                                .read(activeFarmIdProvider)
                                .valueOrNull;
                            if (farmId != null && farmId.isNotEmpty) {
                              _pushRoute(context, AppRoutes.inventoryMedicine);
                            } else {
                              _pushRoute(context, AppRoutes.inventory);
                            }
                          },
                        ),
                        ListTile(
                          title: Text(l10n.milkEntryTitle),
                          onTap: () => _pushRoute(context, AppRoutes.milk),
                        ),
                        ListTile(
                          title: Text(l10n.batchListTitle),
                          onTap: () => _pushRoute(context, AppRoutes.batches),
                        ),
                        ListTile(
                          title: Text(l10n.drawerFatteningSection),
                          onTap: () {
                            final farmId = ref
                                .read(activeFarmIdProvider)
                                .valueOrNull;
                            if (farmId != null && farmId.isNotEmpty) {
                              _pushRoute(
                                context,
                                AppRoutes.farmFattening(farmId),
                              );
                            } else {
                              _pushRoute(context, AppRoutes.farms);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.person_search_outlined,
                    title: l10n.findDoctors,
                    onTap: () => _openServicesTab(context),
                  ),
                  _DrawerTile(
                    icon: Icons.emergency_outlined,
                    title: l10n.filterEmergency,
                    onTap: () => _openServicesTab(context, emergencyOnly: true),
                  ),
                  ListTile(
                    leading: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.inbox_outlined),
                    ),
                    title: Text(l10n.navInbox),
                    onTap: () => _goToTab(context, 2, AppRoutes.inbox),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                l10n.signOut,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () async {
                _closeDrawer(context);
                final confirmed = await NavigationService.showLogoutDialog(
                  context,
                );
                if (confirmed && context.mounted) {
                  await performAuthLogout(ref);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.profileAsync,
    required this.l10n,
    required this.onEditProfile,
  });

  final AsyncValue<MobileMeDto?> profileAsync;
  final AppLocalizations l10n;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
      child: profileAsync.when(
        loading: () => Align(
          alignment: Alignment.bottomLeft,
          child: Text(l10n.drawerTitle, style: theme.textTheme.titleLarge),
        ),
        error: (_, _) => Align(
          alignment: Alignment.bottomLeft,
          child: Text(l10n.drawerTitle, style: theme.textTheme.titleLarge),
        ),
        data: (profile) {
          if (profile == null) {
            return Align(
              alignment: Alignment.bottomLeft,
              child: Text(l10n.drawerTitle, style: theme.textTheme.titleLarge),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  ProfileHeroAvatar(
                    displayName: profile.name.isNotEmpty
                        ? profile.name
                        : l10n.profileEmpty,
                    photoUrl: profile.profilePhotoUrl,
                    thumbUrl: profile.profilePhotoThumbUrl,
                    radius: 28,
                    onTap: onEditProfile,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name.isNotEmpty
                              ? profile.name
                              : l10n.profileEmpty,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile.phone.isNotEmpty)
                          Text(
                            profile.phone,
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.editProfile),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          );
        },
      ),
    );
  }
}
