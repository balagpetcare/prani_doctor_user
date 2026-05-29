import 'package:flutter/material.dart';

import '../../data/recommendation_dto.dart';

class RationItemTile extends StatelessWidget {
  const RationItemTile({super.key, required this.item});

  final RecommendationItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(item.nameBn),
        subtitle: Text('${item.amountKg.toStringAsFixed(2)} kg'),
        trailing: Text('৳${item.costBdt.toStringAsFixed(0)}'),
      ),
    );
  }
}
