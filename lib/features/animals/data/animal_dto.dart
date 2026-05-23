import '../../../core/util/safe_numeric.dart';

enum AnimalFilter { all, active, inactive, livestock, pets }

enum AnimalSort { nameAsc, nameDesc, recentFirst, typeAsc }

class AnimalProfile {
  const AnimalProfile({
    required this.id,
    required this.customerId,
    required this.name,
    required this.species,
    required this.category,
    this.animalType,
    this.breed,
    this.weightKg,
    this.dateOfBirth,
    this.ageYears,
    this.ageMonths,
    this.sex,
    this.gender,
    this.microchipOrTag,
    this.notes,
    this.photoUrl,
    this.pregnancyStatus,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.fromCache = false,
  });

  final String id;
  final String customerId;
  final String name;
  final String species;
  final String category;
  final String? animalType;
  final String? breed;
  final String? weightKg;
  final DateTime? dateOfBirth;
  final int? ageYears;
  final int? ageMonths;
  final String? sex;
  final String? gender;
  final String? microchipOrTag;
  final String? notes;
  final String? photoUrl;
  final String? pregnancyStatus;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool fromCache;

  String get displayTag => microchipOrTag ?? '';

  /// Primary animal image — separate from user profile avatar.
  String? get primaryImageUrl => photoUrl;

  AnimalProfile copyWith({
    String? name,
    String? breed,
    String? weightKg,
    String? microchipOrTag,
    String? notes,
    String? photoUrl,
    bool? active,
    bool? fromCache,
  }) {
    return AnimalProfile(
      id: id,
      customerId: customerId,
      name: name ?? this.name,
      species: species,
      category: category,
      animalType: animalType,
      breed: breed ?? this.breed,
      weightKg: weightKg ?? this.weightKg,
      dateOfBirth: dateOfBirth,
      ageYears: ageYears,
      ageMonths: ageMonths,
      sex: sex,
      gender: gender,
      microchipOrTag: microchipOrTag ?? this.microchipOrTag,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      pregnancyStatus: pregnancyStatus,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory AnimalProfile.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return AnimalProfile(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      name: json['name'] as String? ?? json['tag'] as String? ?? 'Animal',
      species: json['species'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      animalType: json['animalType'] as String?,
      breed: json['breed'] as String?,
      weightKg: json['weightKg']?.toString(),
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.tryParse(json['dateOfBirth'] as String),
      ageYears: safeNullableInt(json['ageYears']),
      ageMonths: safeNullableInt(json['ageMonths']),
      sex: json['sex'] as String?,
      gender: json['gender'] as String?,
      microchipOrTag: json['microchipOrTag'] as String?,
      notes: json['notes'] as String?,
      photoUrl: json['photoUrl'] as String?,
      pregnancyStatus: json['pregnancyStatus'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'name': name,
    'species': species,
    'category': category,
    if (animalType != null) 'animalType': animalType,
    if (breed != null) 'breed': breed,
    if (weightKg != null) 'weightKg': weightKg,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    if (ageYears != null) 'ageYears': ageYears,
    if (ageMonths != null) 'ageMonths': ageMonths,
    if (sex != null) 'sex': sex,
    if (gender != null) 'gender': gender,
    if (microchipOrTag != null) 'microchipOrTag': microchipOrTag,
    if (notes != null) 'notes': notes,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (pregnancyStatus != null) 'pregnancyStatus': pregnancyStatus,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class AnimalPageResult {
  const AnimalPageResult({
    required this.animals,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.activeCount = 0,
    this.inactiveCount = 0,
    this.livestockCount = 0,
    this.fromCache = false,
  });

  final List<AnimalProfile> animals;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int activeCount;
  final int inactiveCount;
  final int livestockCount;
  final bool fromCache;

  AnimalPageResult copyWith({
    bool? fromCache,
    int? activeCount,
    int? inactiveCount,
    int? livestockCount,
  }) {
    return AnimalPageResult(
      animals: animals,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
      activeCount: activeCount ?? this.activeCount,
      inactiveCount: inactiveCount ?? this.inactiveCount,
      livestockCount: livestockCount ?? this.livestockCount,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class AnimalDetail {
  const AnimalDetail({
    required this.animal,
    required this.timeline,
    required this.history,
    this.fromCache = false,
  });

  final AnimalProfile animal;
  final List<AnimalTimelineEvent> timeline;
  final List<AnimalHistoryEntry> history;
  final bool fromCache;
}

class AnimalTimelineEvent {
  const AnimalTimelineEvent({
    required this.title,
    required this.subtitle,
    required this.at,
  });

  final String title;
  final String subtitle;
  final DateTime at;
}

class AnimalHistoryEntry {
  const AnimalHistoryEntry({
    required this.id,
    required this.title,
    required this.status,
    required this.at,
  });

  final String id;
  final String title;
  final String status;
  final DateTime? at;
}

class AnimalInput {
  const AnimalInput({
    required this.animalType,
    this.name,
    this.tag,
    this.breed,
    this.ageYears,
    this.dateOfBirth,
    this.gender,
    this.notes,
    this.photoUrl,
    this.weightKg,
  });

  final String animalType;
  final String? name;
  final String? tag;
  final String? breed;
  final int? ageYears;
  final String? dateOfBirth;
  final String? gender;
  final String? notes;
  final String? photoUrl;
  final double? weightKg;

  Map<String, dynamic> toCreateJson() {
    return {
      'animalType': animalType,
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (tag != null && tag!.trim().isNotEmpty) 'tag': tag!.trim(),
      if (breed != null && breed!.trim().isNotEmpty) 'breed': breed!.trim(),
      if (ageYears != null) 'ageYears': ageYears,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      if (photoUrl != null && photoUrl!.trim().isNotEmpty)
        'photoUrl': photoUrl!.trim(),
      if (weightKg != null) 'weightKg': weightKg,
    };
  }

  Map<String, dynamic> toPatchJson() {
    return {
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (tag != null) 'tag': tag!.trim().isEmpty ? null : tag!.trim(),
      if (breed != null) 'breed': breed!.trim().isEmpty ? null : breed!.trim(),
      if (ageYears != null) 'ageYears': ageYears,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (notes != null) 'notes': notes!.trim().isEmpty ? null : notes!.trim(),
      if (photoUrl != null)
        'photoUrl': photoUrl!.trim().isEmpty ? null : photoUrl!.trim(),
      if (weightKg != null) 'weightKg': weightKg,
      'animalType': animalType,
    };
  }

  Map<String, dynamic> toDraftJson() => {
    'animalType': animalType,
    'name': name,
    'tag': tag,
    'breed': breed,
    'ageYears': ageYears,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'notes': notes,
    'photoUrl': photoUrl,
    'weightKg': weightKg,
  };

  factory AnimalInput.fromDraftJson(Map<String, dynamic> json) {
    return AnimalInput(
      animalType: json['animalType'] as String? ?? 'GOAT',
      name: json['name'] as String?,
      tag: json['tag'] as String?,
      breed: json['breed'] as String?,
      ageYears: safeNullableInt(json['ageYears']),
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      notes: json['notes'] as String?,
      photoUrl: json['photoUrl'] as String?,
      weightKg: safeNullableDouble(json['weightKg']),
    );
  }
}
