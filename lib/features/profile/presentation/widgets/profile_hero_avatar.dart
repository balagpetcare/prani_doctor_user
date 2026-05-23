import 'package:flutter/material.dart';

import '../profile_hero_tags.dart';
import 'profile_media_image.dart';

/// Shared profile avatar with optional Hero flight and cached image fallback.
class ProfileHeroAvatar extends StatelessWidget {
  const ProfileHeroAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.thumbUrl,
    this.radius = 18,
    this.onTap,
    this.enableHero = true,
    this.semanticLabel,
  });

  final String displayName;
  final String? photoUrl;
  final String? thumbUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool enableHero;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: ProfileMediaImage(
            url: photoUrl,
            thumbUrl: thumbUrl,
            fallbackText: displayName,
          ),
        ),
      ),
    );

    if (enableHero) {
      avatar = Hero(
        tag: ProfileHeroTags.avatar,
        child: Material(type: MaterialType.transparency, child: avatar),
      );
    }

    if (onTap != null) {
      avatar = Semantics(
        button: true,
        label: semanticLabel ?? displayName,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: avatar,
        ),
      );
    } else if (semanticLabel != null) {
      avatar = Semantics(label: semanticLabel, child: avatar);
    }

    return avatar;
  }
}
