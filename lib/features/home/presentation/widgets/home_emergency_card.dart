import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/branding/brand_assets.dart';
import '../../../../core/branding/brand_image.dart';import '../../../app_config/presentation/app_config_provider.dart';

class HomeEmergencyCard extends ConsumerWidget {
  const HomeEmergencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final phone = config?.emergencyPhone;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: phone != null && phone.isNotEmpty
            ? () => launchUrl(Uri.parse('tel:$phone'))
            : null,
        child: Row(
          children: [
            BrandImage(
              asset: BrandAssets.homeEmergency,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              fallbackIcon: Icons.emergency_outlined,
            ),            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency vet', style: Theme.of(context).textTheme.titleMedium),
                    if (phone != null && phone.isNotEmpty)
                      Text(phone, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            if (phone != null && phone.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.phone_in_talk_outlined),
              ),
          ],
        ),
      ),
    );
  }
}
