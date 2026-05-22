import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../../core/branding/brand_assets.dart';
import '../../../../core/branding/brand_image.dart';
import '../../../../core/branding/brand_theme.dart';
/// Animated Flutter splash shown after native splash while boot runs.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.statusMessage,
    this.onAnimationComplete,
  });

  final String? statusMessage;
  final VoidCallback? onAnimationComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _minDuration = Duration(milliseconds: 1500);

  late final AnimationController _logoController;
  late final AnimationController _illustrationController;
  late final AnimationController _titleController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _illustrationOpacity;
  late final Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoOpacity = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _illustrationOpacity =
        CurvedAnimation(parent: _illustrationController, curve: Curves.easeInOut);
    _titleOpacity = CurvedAnimation(parent: _titleController, curve: Curves.easeIn);

    _runSequence();
  }

  Future<void> _runSequence() async {
    final started = DateTime.now();
    await _logoController.forward();
    if (!mounted) return;
    await _illustrationController.forward();
    if (!mounted) return;
    await _titleController.forward();
    if (!mounted) return;

    final elapsed = DateTime.now().difference(started);
    final minWait = _minDuration - elapsed;
    if (minWait > Duration.zero) {
      await Future<void>.delayed(minWait);
    }

    if (mounted) widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _illustrationController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BrandTheme.splashBackground(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _logoOpacity,
                child: BrandImage.logo(
                  asset: BrandAssets.primaryLogo,
                  height: 96,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 4,
                child: FadeTransition(
                  opacity: _illustrationOpacity,
                  child: BrandImage(
                    asset: BrandAssets.splashIllustration,
                    fit: BoxFit.contain,
                    hideOnError: true,
                  ),
                ),              ),
              FadeTransition(
                opacity: _titleOpacity,
                child: Text(
                  BrandAssets.splashTitleBn,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: BrandColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.statusMessage != null) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.statusMessage!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
