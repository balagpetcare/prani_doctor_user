class LivestockProfile {
  const LivestockProfile({
    required this.id,
    required this.farmRef,
    required this.name,
    required this.species,
    required this.speciesLabelBn,
    required this.speciesLabelEn,
    required this.gender,
    required this.purpose,
    required this.lifecycleStatus,
    required this.healthStatus,
    this.customSpeciesLabel,
    this.breedId,
    this.breedName,
    this.dateOfBirth,
    this.weightKg,
    this.lastWeightAt,
    this.earTagNumber,
    this.qrCodePayload,
    this.pregnancyStatus,
    this.lactationNumber,
    this.lastCalvingDate,
    this.photoUrl,
    this.purchaseDate,
    this.purchasePriceBdt,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.images = const [],
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final String farmRef;
  final String name;
  final String species;
  final String speciesLabelBn;
  final String speciesLabelEn;
  final String? customSpeciesLabel;
  final String? breedId;
  final String? breedName;
  final String gender;
  final String purpose;
  final String lifecycleStatus;
  final String healthStatus;
  final String? dateOfBirth;
  final double? weightKg;
  final String? lastWeightAt;
  final String? earTagNumber;
  final String? qrCodePayload;
  final String? pregnancyStatus;
  final int? lactationNumber;
  final String? lastCalvingDate;
  final String? photoUrl;
  final String? purchaseDate;
  final double? purchasePriceBdt;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final List<LivestockImage> images;
  final bool pendingSync;
  final bool fromCache;

  bool get isActive => lifecycleStatus == 'ACTIVE';

  String get displaySpecies => speciesLabelBn.isNotEmpty
      ? speciesLabelBn
      : (customSpeciesLabel ?? species);

  factory LivestockProfile.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
    bool pendingSync = false,
  }) {
    final imagesRaw = json['images'] as List<dynamic>? ?? const [];
    return LivestockProfile(
      id: json['id'] as String,
      farmRef: json['farmRef'] as String,
      name: json['name'] as String,
      species: json['species'] as String? ?? 'OTHER',
      speciesLabelBn: json['speciesLabelBn'] as String? ?? '',
      speciesLabelEn: json['speciesLabelEn'] as String? ?? '',
      customSpeciesLabel: json['customSpeciesLabel'] as String?,
      breedId: json['breedId'] as String?,
      breedName: json['breedName'] as String?,
      gender: json['gender'] as String? ?? 'UNKNOWN',
      purpose: json['purpose'] as String? ?? 'MIXED',
      lifecycleStatus: json['lifecycleStatus'] as String? ?? 'ACTIVE',
      healthStatus: json['healthStatus'] as String? ?? 'HEALTHY',
      dateOfBirth: json['dateOfBirth'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      lastWeightAt: json['lastWeightAt'] as String?,
      earTagNumber: json['earTagNumber'] as String?,
      qrCodePayload: json['qrCodePayload'] as String?,
      pregnancyStatus: json['pregnancyStatus'] as String?,
      lactationNumber: json['lactationNumber'] as int?,
      lastCalvingDate: json['lastCalvingDate'] as String?,
      photoUrl: json['photoUrl'] as String?,
      purchaseDate: json['purchaseDate'] as String?,
      purchasePriceBdt: (json['purchasePriceBdt'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      images: imagesRaw
          .whereType<Map<String, dynamic>>()
          .map(LivestockImage.fromJson)
          .toList(),
      pendingSync: pendingSync,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmRef': farmRef,
    'name': name,
    'species': species,
    'speciesLabelBn': speciesLabelBn,
    'speciesLabelEn': speciesLabelEn,
    'customSpeciesLabel': customSpeciesLabel,
    'breedId': breedId,
    'breedName': breedName,
    'gender': gender,
    'purpose': purpose,
    'lifecycleStatus': lifecycleStatus,
    'healthStatus': healthStatus,
    'dateOfBirth': dateOfBirth,
    'weightKg': weightKg,
    'lastWeightAt': lastWeightAt,
    'earTagNumber': earTagNumber,
    'qrCodePayload': qrCodePayload,
    'pregnancyStatus': pregnancyStatus,
    'lactationNumber': lactationNumber,
    'lastCalvingDate': lastCalvingDate,
    'photoUrl': photoUrl,
    'purchaseDate': purchaseDate,
    'purchasePriceBdt': purchasePriceBdt,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'images': images.map((i) => i.toJson()).toList(),
  };

  LivestockProfile copyWith({
    String? photoUrl,
    bool? pendingSync,
    bool? fromCache,
    List<LivestockImage>? images,
  }) {
    return LivestockProfile(
      id: id,
      farmRef: farmRef,
      name: name,
      species: species,
      speciesLabelBn: speciesLabelBn,
      speciesLabelEn: speciesLabelEn,
      customSpeciesLabel: customSpeciesLabel,
      breedId: breedId,
      breedName: breedName,
      gender: gender,
      purpose: purpose,
      lifecycleStatus: lifecycleStatus,
      healthStatus: healthStatus,
      dateOfBirth: dateOfBirth,
      weightKg: weightKg,
      lastWeightAt: lastWeightAt,
      earTagNumber: earTagNumber,
      qrCodePayload: qrCodePayload,
      pregnancyStatus: pregnancyStatus,
      lactationNumber: lactationNumber,
      lastCalvingDate: lastCalvingDate,
      photoUrl: photoUrl ?? this.photoUrl,
      purchaseDate: purchaseDate,
      purchasePriceBdt: purchasePriceBdt,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      images: images ?? this.images,
      pendingSync: pendingSync ?? this.pendingSync,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class LivestockImage {
  const LivestockImage({
    required this.id,
    required this.url,
    this.caption,
  });

  final String id;
  final String url;
  final String? caption;

  factory LivestockImage.fromJson(Map<String, dynamic> json) => LivestockImage(
    id: json['id'] as String,
    url: json['url'] as String,
    caption: json['caption'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'caption': caption,
  };
}

class LivestockPageResult {
  const LivestockPageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
    this.fromCache = false,
  });

  final List<LivestockProfile> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  final bool fromCache;
}

class LivestockInput {
  const LivestockInput({
    required this.farmRef,
    required this.name,
    required this.species,
    required this.gender,
    this.customSpeciesLabel,
    this.breedName,
    this.purpose = 'MIXED',
    this.healthStatus = 'HEALTHY',
    this.dateOfBirth,
    this.weightKg,
    this.earTagNumber,
    this.notes,
    this.photoUrl,
  });

  final String farmRef;
  final String name;
  final String species;
  final String gender;
  final String? customSpeciesLabel;
  final String? breedName;
  final String purpose;
  final String healthStatus;
  final String? dateOfBirth;
  final double? weightKg;
  final String? earTagNumber;
  final String? notes;
  final String? photoUrl;

  Map<String, dynamic> toJson() => {
    'farmRef': farmRef,
    'name': name.trim(),
    'species': species,
    'gender': gender,
    if (customSpeciesLabel != null && customSpeciesLabel!.trim().isNotEmpty)
      'customSpeciesLabel': customSpeciesLabel!.trim(),
    if (breedName != null && breedName!.trim().isNotEmpty)
      'breedName': breedName!.trim(),
    'purpose': purpose,
    'healthStatus': healthStatus,
    if (dateOfBirth != null && dateOfBirth!.isNotEmpty)
      'dateOfBirth': dateOfBirth,
    if (weightKg != null) 'weightKg': weightKg,
    if (earTagNumber != null && earTagNumber!.trim().isNotEmpty)
      'earTagNumber': earTagNumber!.trim(),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    if (photoUrl != null && photoUrl!.trim().isNotEmpty)
      'photoUrl': photoUrl!.trim(),
  };

  factory LivestockInput.fromJson(Map<String, dynamic> json) => LivestockInput(
    farmRef: json['farmRef'] as String,
    name: json['name'] as String? ?? '',
    species: json['species'] as String? ?? 'COW',
    gender: json['gender'] as String? ?? 'FEMALE',
    customSpeciesLabel: json['customSpeciesLabel'] as String?,
    breedName: json['breedName'] as String?,
    purpose: json['purpose'] as String? ?? 'MIXED',
    healthStatus: json['healthStatus'] as String? ?? 'HEALTHY',
    dateOfBirth: json['dateOfBirth'] as String?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    earTagNumber: json['earTagNumber'] as String?,
    notes: json['notes'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );
}

class LivestockTimelineItem {
  const LivestockTimelineItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
  });

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String occurredAt;
}

class LivestockHealthRecord {
  const LivestockHealthRecord({
    required this.id,
    required this.title,
    required this.recordType,
    required this.recordedDate,
    this.diagnosis,
  });

  final String id;
  final String title;
  final String recordType;
  final String recordedDate;
  final String? diagnosis;

  factory LivestockHealthRecord.fromJson(Map<String, dynamic> json) =>
      LivestockHealthRecord(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        recordType: json['recordType'] as String? ?? 'OTHER',
        recordedDate: json['recordedDate'] as String? ?? '',
        diagnosis: json['diagnosis'] as String?,
      );
}

class LivestockVaccinationRecord {
  const LivestockVaccinationRecord({
    required this.id,
    required this.vaccineName,
    required this.scheduledDate,
    required this.status,
  });

  final String id;
  final String vaccineName;
  final String scheduledDate;
  final String status;

  factory LivestockVaccinationRecord.fromJson(Map<String, dynamic> json) =>
      LivestockVaccinationRecord(
        id: json['id'] as String,
        vaccineName: json['vaccineName'] as String? ?? '',
        scheduledDate: json['scheduledDate'] as String? ?? '',
        status: json['status'] as String? ?? 'SCHEDULED',
      );
}

enum LivestockFilter { all, active, inactive }

enum LivestockSort { recentFirst, nameAsc }
