import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/brand_assets.dart';
import '../../../../core/branding/brand_image.dart';import '../../../../routing/app_routes.dart';

class HomePromoCard extends StatelessWidget {
  const HomePromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.vaccines),
        child: Row(
          children: [
            BrandImage(
              asset: BrandAssets.homePromoVaccination,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              fallbackIcon: Icons.vaccines_outlined,
            ),            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vaccination reminders', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Track schedules and never miss a dose',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
