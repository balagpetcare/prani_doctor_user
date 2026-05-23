import 'package:flutter/material.dart';

import '../theme/home_theme_extension.dart';
import '../theme/home_tokens.dart';

bool _homeShimmerAnimates() =>
    WidgetsBinding.instance.runtimeType.toString() !=
    'TestWidgetsFlutterBinding';

/// Lightweight shimmer placeholder — GPU-friendly gradient slide.
class HomeShimmer extends StatefulWidget {
  const HomeShimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<HomeShimmer> createState() => _HomeShimmerState();
}

class _HomeShimmerState extends State<HomeShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (_homeShimmerAnimates()) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final homeTheme = HomeThemeExtension.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = (_controller.value * 2) - 1;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(slide - 1, 0),
              end: Alignment(slide + 1, 0),
              colors: [
                homeTheme.shimmerBase,
                homeTheme.shimmerHighlight,
                homeTheme.shimmerBase,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class HomeShimmerBox extends StatelessWidget {
  const HomeShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = HomeTokens.radiusMd,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final homeTheme = HomeThemeExtension.of(context);
    return HomeShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: homeTheme.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class HomeSectionShimmer extends StatelessWidget {
  const HomeSectionShimmer({super.key, this.lines = 2, this.lineHeight = 14});

  final int lines;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: HomeTokens.pageHorizontal(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeShimmerBox(height: lineHeight, borderRadius: HomeTokens.radiusSm),
          for (var i = 0; i < lines - 1; i++) ...[
            const SizedBox(height: HomeTokens.space8),
            HomeShimmerBox(
              height: lineHeight,
              width: i == lines - 2 ? 160 : double.infinity,
              borderRadius: HomeTokens.radiusSm,
            ),
          ],
        ],
      ),
    );
  }
}
