import 'package:flutter/material.dart';

/// Placeholder layout while profile data loads on the edit screen.
class ProfileEditSkeleton extends StatelessWidget {
  const ProfileEditSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar({double? width, double height = 14}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 220, color: base),
          Transform.translate(
            offset: const Offset(0, -48),
            child: Center(
              child: CircleAvatar(radius: 48, backgroundColor: base),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar(width: 160, height: 18),
                const SizedBox(height: 24),
                for (var i = 0; i < 5; i++) ...[
                  bar(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
