import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/brand_assets.dart';
import '../../../core/branding/brand_theme.dart';
import '../../../routing/app_routes.dart';
import '../../auth/data/auth_preferences.dart';
import 'onboarding_providers.dart';

/// First-run intro slides (cloned from pranidoctor_mobile onboarding UI).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  List<OnboardingSlideAsset> get _slides => BrandAssets.onboardingSlides;

  Future<void> _complete() async {
    await ref.read(authPreferencesProvider).setOnboardingCompleted(true);
    ref.invalidate(onboardingCompletedProvider);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _goPrevious() {
    if (_page <= 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNext() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _complete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: BrandColors.onboardingBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) {
              if (!mounted) return;
              setState(() => _page = i);
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _OnboardingImagePage(
                imageAsset: slide.image,
                semanticLabel: slide.semanticLabel,
              );
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.22),
                      BrandColors.onboardingBackground.withValues(alpha: 0.88),
                      BrandColors.onboardingBackground.withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.35, 0.58, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: pad.left + 20,
            right: pad.right + 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _OnboardingTextContent(
                        key: ValueKey<int>(_page),
                        title: _slides[_page].titleBn,
                        body: _slides[_page].bodyBn,
                        textTheme: textTheme,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 8,
                          width: i == _page ? 22 : 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: i == _page
                                ? scheme.primary
                                : BrandColors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _page > 0
                                ? TextButton(
                                    onPressed: _goPrevious,
                                    style: TextButton.styleFrom(
                                      foregroundColor: BrandColors.white
                                          .withValues(alpha: 0.92),
                                    ),
                                    child: const Text('পিছনে'),
                                  )
                                : const SizedBox(height: 48),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _goNext,
                              child: Text(
                                _page < _slides.length - 1
                                    ? 'পরের ধাপ'
                                    : 'শুরু করুন',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingImagePage extends StatelessWidget {
  const _OnboardingImagePage({
    required this.imageAsset,
    required this.semanticLabel,
  });

  final String imageAsset;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: 9,
            height: 16,
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingTextContent extends StatelessWidget {
  const _OnboardingTextContent({
    super.key,
    required this.title,
    required this.body,
    required this.textTheme,
  });

  final String title;
  final String body;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              color: BrandColors.white,
              fontWeight: FontWeight.w800,
              height: 1.18,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: BrandColors.white.withValues(alpha: 0.92),
              height: 1.45,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
