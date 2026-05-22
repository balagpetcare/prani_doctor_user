import 'package:flutter/material.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Bone(height: 72, color: color),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _Bone(height: 88, color: color)),
            const SizedBox(width: 12),
            Expanded(child: _Bone(height: 88, color: color)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Bone(height: 88, color: color)),
            const SizedBox(width: 12),
            Expanded(child: _Bone(height: 88, color: color)),
          ],
        ),
        const SizedBox(height: 24),
        _Bone(height: 120, color: color),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
