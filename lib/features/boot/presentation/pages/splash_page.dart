import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../../core/branding/brand_assets.dart';

/// Full-bleed farm splash (cloned from pranidoctor_mobile) while boot runs.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.statusMessage, this.onAnimationComplete});

  final String? statusMessage;
  final VoidCallback? onAnimationComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _imageFailed = false;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSplash());
  }

  Future<void> _finishSplash() async {
    await Future<void>.delayed(
      const Duration(milliseconds: BrandAssets.splashMinDisplayMs),
    );
    if (mounted) widget.onAnimationComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: !_imageFailed
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final mq = MediaQuery.of(context);
                      final dpr = mq.devicePixelRatio;
                      final cacheWidth = (constraints.maxWidth * dpr)
                          .round()
                          .clamp(360, BrandAssets.splashDecodeMaxWidthPx);
                      final cacheHeight = (constraints.maxHeight * dpr)
                          .round()
                          .clamp(640, BrandAssets.splashDecodeMaxHeightPx);

                      return Image.asset(
                        BrandAssets.splashFarm,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                        cacheWidth: cacheWidth,
                        cacheHeight: cacheHeight,
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _imageFailed = true);
                          });
                          return ColoredBox(
                            color: scheme.surfaceContainerHighest,
                          );
                        },
                      );
                    },
                  )
                : ColoredBox(color: scheme.surfaceContainerHighest),
          ),
          if (widget.statusMessage != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: SafeArea(
                top: false,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.statusMessage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
