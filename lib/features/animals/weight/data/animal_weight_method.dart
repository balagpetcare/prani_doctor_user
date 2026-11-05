enum AnimalWeightMethod { tape, scale, aiCamera }

extension AnimalWeightMethodX on AnimalWeightMethod {
  String get apiValue {
    switch (this) {
      case AnimalWeightMethod.tape:
        return 'TAPE';
      case AnimalWeightMethod.scale:
        return 'SCALE';
      case AnimalWeightMethod.aiCamera:
        return 'AI_CAMERA';
    }
  }

  static AnimalWeightMethod? fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'TAPE':
        return AnimalWeightMethod.tape;
      case 'SCALE':
        return AnimalWeightMethod.scale;
      case 'AI_CAMERA':
        return AnimalWeightMethod.aiCamera;
      default:
        return null;
    }
  }

  static bool supportsTape(String animalType) {
    return animalType.toUpperCase() != 'POULTRY';
  }
}
