import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/branding/brand_assets.dart';
import '../../../../core/branding/brand_image.dart';
import '../../../../routing/app_routes.dart';
import '../../../doctors/data/provider_dto.dart';
import '../home_analytics.dart';
import '../providers/home_section_providers.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';
import 'home_shimmer.dart';

class HomeDoctorSection extends ConsumerWidget {
  const HomeDoctorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final doctorsAsync = ref.watch(homeDoctorsPreviewProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.findDoctors,
        child: doctorsAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(title: l10n.findDoctors),
              const SizedBox(height: 132, child: HomeSectionShimmer(lines: 2)),
            ],
          ),
          error: (_, _) => Column(
            children: [
              HomeSectionHeader(title: l10n.findDoctors),
              Padding(
                padding: HomeTokens.pageHorizontal(context),
                child: HomeErrorRetry(
                  message: l10n.dashboardSectionError,
                  onRetry: () {
                    HomeAnalytics.sectionRetry('doctors');
                    ref.invalidate(homeDoctorsPreviewProvider);
                  },
                ),
              ),
            ],
          ),
          data: (doctors) {
            if (doctors.isEmpty) {
              return Column(
                children: [
                  HomeSectionHeader(
                    title: l10n.findDoctors,
                    actionLabel: l10n.homeBookDoctor,
                    onAction: () => context.go(AppRoutes.services),
                  ),
                  Padding(
                    padding: HomeTokens.pageHorizontal(context),
                    child: HomeSurfaceCard(
                      onTap: () => context.go(AppRoutes.services),
                      semanticLabel: l10n.homeNoDoctorsNearby,
                      child: Row(
                        children: [
                          const BrandImage(
                            asset: BrandAssets.homeEmptyDoctors,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.person_search_outlined,
                          ),
                          const SizedBox(width: HomeTokens.space12),
                          Expanded(child: Text(l10n.homeNoDoctorsNearby)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: HomeTokens.space8),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeSectionHeader(
                  title: l10n.findDoctors,
                  actionLabel: l10n.homeViewAll,
                  onAction: () => context.go(AppRoutes.services),
                ),
                HomeHorizontalList(
                  height: 132,
                  itemCount: doctors.length,
                  itemBuilder: (context, index) =>
                      _DoctorPreviewCard(doctor: doctors[index]),
                ),
                const SizedBox(height: HomeTokens.space8),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DoctorPreviewCard extends StatelessWidget {
  const _DoctorPreviewCard({required this.doctor});

  final ProviderDoctorListItemDto doctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: HomeSurfaceCard(
        onTap: () => context.push(AppRoutes.doctorDetail(doctor.id)),
        semanticLabel: doctor.name,
        padding: const EdgeInsets.all(HomeTokens.space12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
              child: HomeCachedImage(
                url: doctor.profilePhotoUrl,
                width: 56,
                height: 56,
                fallbackIcon: Icons.person,
                fallbackText: doctor.name,
                semanticLabel: doctor.name,
              ),
            ),
            const SizedBox(width: HomeTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    doctor.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    doctor.serviceType,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (doctor.fee != null)
                    Text(
                      doctor.fee!,
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
