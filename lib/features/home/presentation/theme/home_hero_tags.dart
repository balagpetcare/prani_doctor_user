import '../../../profile/presentation/profile_hero_tags.dart';

/// Stable hero tags for home → detail transitions.
abstract final class HomeHeroTags {
  HomeHeroTags._();

  static const profileAvatar = ProfileHeroTags.avatar;

  static String animalPhoto(String animalId) => 'home_animal_photo_$animalId';
}
