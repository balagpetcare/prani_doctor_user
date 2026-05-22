import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/brand_assets.dart';
import '../../../core/branding/brand_image.dart';
import '../../../core/branding/brand_theme.dart';import '../../../routing/app_routes.dart';
import '../../auth/data/auth_preferences.dart';
import 'onboarding_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  List<OnboardingSlideAsset> get _slides => BrandAssets.onboardingSlides;

  bool get _isLast => _index >= _slides.length - 1;

  Future<void> _complete() async {
    await ref.read(authPreferencesProvider).setOnboardingCompleted(true);
    ref.invalidate(onboardingCompletedProvider);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_isLast) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _complete,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BrandImage(
                              asset: slide.image,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.agriculture_outlined,
                            ),                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide.titleBn,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: BrandColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitleBn,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: _index == i ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _index == i
                              ? BrandColors.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_isLast ? 'শুরু করুন' : 'Next'),
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
