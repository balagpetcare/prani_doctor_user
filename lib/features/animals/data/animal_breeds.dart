/// Static breed catalog keyed by animal type until a mobile breeds API exists.
abstract final class AnimalBreeds {
  AnimalBreeds._();

  static const breedsByType = <String, List<String>>{
    'GOAT': ['Black Bengal', 'Jamunapari', 'Boer', 'Local', 'Crossbred'],
    'CATTLE': ['Local', 'Sahiwal', 'Jersey', 'Holstein', 'Red Chittagong'],
    'POULTRY': ['Sonali', 'Broiler', 'Layer', 'Desi', 'Rhode Island Red'],
    'DOG': ['Local', 'German Shepherd', 'Labrador', 'Mixed'],
    'CAT': ['Local', 'Persian', 'Mixed'],
    'OTHER': ['Local', 'Mixed', 'Unknown'],
  };

  static List<String> forType(String animalType) {
    final key = animalType.toUpperCase();
    return breedsByType[key] ?? breedsByType['OTHER']!;
  }
}
