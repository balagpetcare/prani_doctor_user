import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ecosystem/presentation/active_farm_ref_provider.dart';
import 'farm_health_dashboard_page.dart';
import 'smart_recommendations_page.dart';

class FarmHealthDashboardScope extends ConsumerWidget {
  const FarmHealthDashboardScope({super.key, this.farmRef});

  final String? farmRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFarm = farmRef ?? ref.watch(activeFarmRefProvider);
    if (activeFarm == null || activeFarm.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('খামার স্বাস্থ্য')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('অনুগ্রহ করে প্রথমে একটি খামার নির্বাচন করুন।'),
          ),
        ),
      );
    }
    return FarmHealthDashboardPage(farmRef: activeFarm);
  }
}

class SmartRecommendationsScope extends ConsumerWidget {
  const SmartRecommendationsScope({super.key, this.farmRef});

  final String? farmRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFarm = farmRef ?? ref.watch(activeFarmRefProvider);
    return SmartRecommendationsPage(farmRef: activeFarm);
  }
}
