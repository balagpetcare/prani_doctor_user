import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/brand_assets.dart';
import '../../../../core/branding/brand_image.dart';import '../../../../routing/app_routes.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BrandImage(
              asset: BrandAssets.homeHero,
              fit: BoxFit.cover,
              width: double.infinity,
              fallbackIcon: Icons.landscape_outlined,
            ),          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: FilledButton(
              onPressed: () => context.go(AppRoutes.services),
              child: const Text('Find a vet'),
            ),
          ),
        ],
      ),
    );
  }
}
