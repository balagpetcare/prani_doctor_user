import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../../animals/data/animal_dto.dart';
import '../../../animals/presentation/animal_providers.dart';
import '../providers/home_section_providers.dart';
import '../theme/home_hero_tags.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';

class HomeAnimalCarousel extends ConsumerStatefulWidget {
  const HomeAnimalCarousel({super.key});

  @override
  ConsumerState<HomeAnimalCarousel> createState() => _HomeAnimalCarouselState();
}

class _HomeAnimalCarouselState extends ConsumerState<HomeAnimalCarousel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 120) {
      ref.read(animalListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final animalsAsync = ref.watch(homeAnimalsPreviewProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.animalListTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeSectionHeader(
              title: l10n.animalListTitle,
              actionLabel: l10n.homeViewAll,
              onAction: () => context.go(AppRoutes.animals),
            ),
            animalsAsync.when(
              loading: () => const HomeSectionLoading(height: 148),
              error: (_, _) => Padding(
                padding: HomeTokens.pageHorizontal(context),
                child: HomeErrorRetry(
                  message: l10n.dashboardSectionOffline,
                  offline: true,
                  onRetry: () => ref
                      .read(animalListProvider.notifier)
                      .reload(forceRefresh: true),
                ),
              ),
              data: (state) {
                if (state.animals.isEmpty) {
                  return HomeEmptyState(
                    message: l10n.homeNoAnimalsYet,
                    icon: Icons.pets_outlined,
                    actionLabel: l10n.dashboardAddAnimal,
                    onAction: () => context.push(AppRoutes.animalCreate),
                  );
                }
                return HomeHorizontalList(
                  controller: _scrollController,
                  itemCount: state.animals.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.animals.length) {
                      return const SizedBox(
                        width: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return _AnimalPreviewCard(animal: state.animals[index]);
                  },
                );
              },
            ),
            const SizedBox(height: HomeTokens.space8),
          ],
        ),
      ),
    );
  }
}

class _AnimalPreviewCard extends StatelessWidget {
  const _AnimalPreviewCard({required this.animal});

  final AnimalProfile animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 132,
      child: HomeSurfaceCard(
        onTap: () => context.push(AppRoutes.animalDetail(animal.id)),
        semanticLabel: animal.name,
        padding: const EdgeInsets.all(HomeTokens.space12 - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
                child: Hero(
                  tag: HomeHeroTags.animalPhoto(animal.id),
                  child: Material(
                    type: MaterialType.transparency,
                    child: HomeCachedImage(
                      key: ValueKey(
                        'animal_image_${animal.id}_${animal.primaryImageUrl ?? ''}',
                      ),
                      url: animal.primaryImageUrl,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.pets,
                      fallbackText: animal.name,
                      semanticLabel: animal.name,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: HomeTokens.space8),
            Text(
              animal.name,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              animal.species,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
