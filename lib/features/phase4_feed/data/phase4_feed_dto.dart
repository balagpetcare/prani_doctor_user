class Phase4FeedItem {
  const Phase4FeedItem({
    required this.id,
    required this.code,
    required this.category,
    required this.nameBn,
    required this.nameEn,
    required this.defaultUnit,
    this.approxPriceBdt,
    required this.moistureType,
    required this.isSeasonal,
    required this.isActive,
    this.nutrition,
    this.fromCache = false,
  });

  final String id;
  final String code;
  final String category;
  final String nameBn;
  final String nameEn;
  final String defaultUnit;
  final double? approxPriceBdt;
  final String moistureType;
  final bool isSeasonal;
  final bool isActive;
  final Phase4FeedNutrition? nutrition;
  final bool fromCache;

  String displayName({required bool preferBn}) =>
      preferBn && nameBn.isNotEmpty ? nameBn : (nameEn.isNotEmpty ? nameEn : code);

  factory Phase4FeedItem.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final nutritionRaw = json['nutrition'];
    return Phase4FeedItem(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      nameBn: json['nameBn'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      defaultUnit: json['defaultUnit'] as String? ?? 'KG',
      approxPriceBdt: (json['approxPriceBdt'] as num?)?.toDouble(),
      moistureType: json['moistureType'] as String? ?? 'DRY',
      isSeasonal: json['isSeasonal'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      nutrition: nutritionRaw is Map<String, dynamic>
          ? Phase4FeedNutrition.fromJson(nutritionRaw)
          : null,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'category': category,
    'nameBn': nameBn,
    'nameEn': nameEn,
    'defaultUnit': defaultUnit,
    'approxPriceBdt': approxPriceBdt,
    'moistureType': moistureType,
    'isSeasonal': isSeasonal,
    'isActive': isActive,
    if (nutrition != null) 'nutrition': nutrition!.toJson(),
  };
}

class Phase4FeedNutrition {
  const Phase4FeedNutrition({
    this.cpPercent,
    this.tdnPercent,
    this.dmPercent,
  });

  final double? cpPercent;
  final double? tdnPercent;
  final double? dmPercent;

  factory Phase4FeedNutrition.fromJson(Map<String, dynamic> json) =>
      Phase4FeedNutrition(
        cpPercent: (json['cpPercent'] as num?)?.toDouble(),
        tdnPercent: (json['tdnPercent'] as num?)?.toDouble(),
        dmPercent: (json['dmPercent'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'cpPercent': cpPercent,
    'tdnPercent': tdnPercent,
    'dmPercent': dmPercent,
  };
}

class Phase4FeedPageResult<T> {
  const Phase4FeedPageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
    this.fromCache = false,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  final bool fromCache;
}

class Phase4FeedInventoryItem {
  const Phase4FeedInventoryItem({
    required this.id,
    required this.farmRef,
    required this.displayName,
    required this.unit,
    required this.quantityOnHand,
    this.lowStockThreshold,
    required this.isLowStock,
    this.feedItemId,
    this.feedItemNameBn,
    this.feedItemNameEn,
    this.notes,
    this.fromCache = false,
  });

  final String id;
  final String farmRef;
  final String displayName;
  final String unit;
  final double quantityOnHand;
  final double? lowStockThreshold;
  final bool isLowStock;
  final String? feedItemId;
  final String? feedItemNameBn;
  final String? feedItemNameEn;
  final String? notes;
  final bool fromCache;

  factory Phase4FeedInventoryItem.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final feedItem = json['feedItem'] as Map<String, dynamic>?;
    return Phase4FeedInventoryItem(
      id: json['id'] as String,
      farmRef: json['farmRef'] as String,
      displayName: json['displayName'] as String? ?? '',
      unit: json['unit'] as String? ?? 'KG',
      quantityOnHand: (json['quantityOnHand'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble(),
      isLowStock: json['isLowStock'] as bool? ?? false,
      feedItemId: json['feedItemId'] as String? ?? feedItem?['id'] as String?,
      feedItemNameBn: feedItem?['nameBn'] as String?,
      feedItemNameEn: feedItem?['nameEn'] as String?,
      notes: json['notes'] as String?,
      fromCache: fromCache,
    );
  }
}

class Phase4FeedPurchaseInput {
  const Phase4FeedPurchaseInput({
    required this.farmRef,
    required this.feedInventoryId,
    required this.quantity,
    required this.unit,
    required this.purchasedAt,
    this.feedItemId,
    this.unitCostBdt,
    this.totalCostBdt,
    this.supplierName,
    this.notes,
  });

  final String farmRef;
  final String feedInventoryId;
  final double quantity;
  final String unit;
  final String purchasedAt;
  final String? feedItemId;
  final double? unitCostBdt;
  final double? totalCostBdt;
  final String? supplierName;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'farmRef': farmRef,
    'feedInventoryId': feedInventoryId,
    'quantity': quantity,
    'unit': unit,
    'purchasedAt': purchasedAt,
    if (feedItemId != null) 'feedItemId': feedItemId,
    if (unitCostBdt != null) 'unitCostBdt': unitCostBdt,
    if (totalCostBdt != null) 'totalCostBdt': totalCostBdt,
    if (supplierName != null && supplierName!.trim().isNotEmpty)
      'supplierName': supplierName!.trim(),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };

  factory Phase4FeedPurchaseInput.fromJson(Map<String, dynamic> json) =>
      Phase4FeedPurchaseInput(
        farmRef: json['farmRef'] as String,
        feedInventoryId: json['feedInventoryId'] as String,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'KG',
        purchasedAt: json['purchasedAt'] as String? ?? '',
        feedItemId: json['feedItemId'] as String?,
        unitCostBdt: (json['unitCostBdt'] as num?)?.toDouble(),
        totalCostBdt: (json['totalCostBdt'] as num?)?.toDouble(),
        supplierName: json['supplierName'] as String?,
        notes: json['notes'] as String?,
      );
}

class Phase4FeedConsumptionInput {
  const Phase4FeedConsumptionInput({
    required this.farmRef,
    required this.amount,
    required this.unit,
    required this.recordedDate,
    this.livestockId,
    this.feedInventoryId,
    this.feedItemId,
    this.costBdt,
    this.deductStock = false,
    this.notes,
  });

  final String farmRef;
  final double amount;
  final String unit;
  final String recordedDate;
  final String? livestockId;
  final String? feedInventoryId;
  final String? feedItemId;
  final double? costBdt;
  final bool deductStock;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'farmRef': farmRef,
    'amount': amount,
    'unit': unit,
    'recordedDate': recordedDate,
    'deductStock': deductStock,
    if (livestockId != null && livestockId!.isNotEmpty)
      'livestockId': livestockId,
    if (feedInventoryId != null && feedInventoryId!.isNotEmpty)
      'feedInventoryId': feedInventoryId,
    if (feedItemId != null && feedItemId!.isNotEmpty) 'feedItemId': feedItemId,
    if (costBdt != null) 'costBdt': costBdt,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };

  factory Phase4FeedConsumptionInput.fromJson(Map<String, dynamic> json) =>
      Phase4FeedConsumptionInput(
        farmRef: json['farmRef'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'KG',
        recordedDate: json['recordedDate'] as String? ?? '',
        livestockId: json['livestockId'] as String?,
        feedInventoryId: json['feedInventoryId'] as String?,
        feedItemId: json['feedItemId'] as String?,
        costBdt: (json['costBdt'] as num?)?.toDouble(),
        deductStock: json['deductStock'] as bool? ?? false,
        notes: json['notes'] as String?,
      );
}

class Phase4FeedConsumptionRecord {
  const Phase4FeedConsumptionRecord({
    required this.id,
    required this.farmRef,
    required this.amount,
    required this.unit,
    required this.recordedDate,
    this.livestockId,
    this.feedInventoryId,
    this.costBdt,
    this.notes,
  });

  final String id;
  final String farmRef;
  final double amount;
  final String unit;
  final String recordedDate;
  final String? livestockId;
  final String? feedInventoryId;
  final double? costBdt;
  final String? notes;

  factory Phase4FeedConsumptionRecord.fromJson(Map<String, dynamic> json) =>
      Phase4FeedConsumptionRecord(
        id: json['id'] as String,
        farmRef: json['farmRef'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'KG',
        recordedDate: json['recordedDate'] as String? ?? '',
        livestockId: json['livestockId'] as String?,
        feedInventoryId: json['feedInventoryId'] as String?,
        costBdt: (json['costBdt'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}

class Phase4LowStockAlert {
  const Phase4LowStockAlert({
    required this.feedInventoryId,
    required this.displayName,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    required this.unit,
    required this.message,
  });

  final String feedInventoryId;
  final String displayName;
  final double quantityOnHand;
  final double lowStockThreshold;
  final String unit;
  final String message;

  factory Phase4LowStockAlert.fromJson(Map<String, dynamic> json) =>
      Phase4LowStockAlert(
        feedInventoryId: json['feedInventoryId'] as String,
        displayName: json['displayName'] as String? ?? '',
        quantityOnHand: (json['quantityOnHand'] as num?)?.toDouble() ?? 0,
        lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'KG',
        message: json['message'] as String? ?? '',
      );
}
