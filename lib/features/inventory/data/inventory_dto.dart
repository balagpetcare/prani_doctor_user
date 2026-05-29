import '../../feed/data/feed_dto.dart';

enum InventoryType { feed, medicine }

extension InventoryTypeApi on InventoryType {
  String get apiValue => name.toUpperCase();

  static InventoryType fromApi(String value) {
    return InventoryType.values.firstWhere(
      (t) => t.apiValue == value.toUpperCase(),
      orElse: () => InventoryType.feed,
    );
  }
}

enum MedicineUnit {
  tablet,
  capsule,
  ml,
  liter,
  vial,
  sachet,
  tube,
  other,
}

extension MedicineUnitApi on MedicineUnit {
  String get apiValue {
    switch (this) {
      case MedicineUnit.tablet:
        return 'TABLET';
      case MedicineUnit.capsule:
        return 'CAPSULE';
      case MedicineUnit.ml:
        return 'ML';
      case MedicineUnit.liter:
        return 'LITER';
      case MedicineUnit.vial:
        return 'VIAL';
      case MedicineUnit.sachet:
        return 'SACHET';
      case MedicineUnit.tube:
        return 'TUBE';
      case MedicineUnit.other:
        return 'OTHER';
    }
  }

  static MedicineUnit fromApi(String value) {
    return MedicineUnit.values.firstWhere(
      (u) => u.apiValue == value.toUpperCase(),
      orElse: () => MedicineUnit.other,
    );
  }

  String get label {
    switch (this) {
      case MedicineUnit.tablet:
        return 'Tablet';
      case MedicineUnit.capsule:
        return 'Capsule';
      case MedicineUnit.ml:
        return 'ml';
      case MedicineUnit.liter:
        return 'Liter';
      case MedicineUnit.vial:
        return 'Vial';
      case MedicineUnit.sachet:
        return 'Sachet';
      case MedicineUnit.tube:
        return 'Tube';
      case MedicineUnit.other:
        return 'Other';
    }
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.customerId,
    required this.farmRef,
    required this.inventoryType,
    required this.displayName,
    this.feedType,
    this.feedUnit,
    this.medicineUnit,
    this.lowStockThreshold,
    required this.allowNegativeStock,
    required this.isActive,
    this.notes,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.quantityAvailable,
    required this.isLowStock,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final String customerId;
  final String farmRef;
  final InventoryType inventoryType;
  final String displayName;
  final FeedType? feedType;
  final FeedUnit? feedUnit;
  final MedicineUnit? medicineUnit;
  final double? lowStockThreshold;
  final bool allowNegativeStock;
  final bool isActive;
  final String? notes;
  final double quantityOnHand;
  final double quantityReserved;
  final double quantityAvailable;
  final bool isLowStock;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  String get unitLabel =>
      feedUnit?.apiValue ?? medicineUnit?.label ?? '';

  factory InventoryItem.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
    bool pendingSync = false,
  }) {
    return InventoryItem(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      farmRef: json['farmRef'] as String? ?? '',
      inventoryType: InventoryTypeApi.fromApi(
        json['inventoryType'] as String? ?? 'FEED',
      ),
      displayName: json['displayName'] as String? ?? '',
      feedType: json['feedType'] != null
          ? FeedTypeApi.fromApi(json['feedType'] as String)
          : null,
      feedUnit: json['feedUnit'] != null
          ? FeedUnitApi.fromApi(json['feedUnit'] as String)
          : null,
      medicineUnit: json['medicineUnit'] != null
          ? MedicineUnitApi.fromApi(json['medicineUnit'] as String)
          : null,
      lowStockThreshold: json['lowStockThreshold'] == null
          ? null
          : double.tryParse(json['lowStockThreshold'].toString()),
      allowNegativeStock: json['allowNegativeStock'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
      quantityOnHand:
          double.tryParse(json['quantityOnHand']?.toString() ?? '') ?? 0,
      quantityReserved:
          double.tryParse(json['quantityReserved']?.toString() ?? '') ?? 0,
      quantityAvailable:
          double.tryParse(json['quantityAvailable']?.toString() ?? '') ?? 0,
      isLowStock: json['isLowStock'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      pendingSync: pendingSync,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'farmRef': farmRef,
    'inventoryType': inventoryType.apiValue,
    'displayName': displayName,
    if (feedType != null) 'feedType': feedType!.apiValue,
    if (feedUnit != null) 'feedUnit': feedUnit!.apiValue,
    if (medicineUnit != null) 'medicineUnit': medicineUnit!.apiValue,
    if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
    'allowNegativeStock': allowNegativeStock,
    'isActive': isActive,
    if (notes != null) 'notes': notes,
    'quantityOnHand': quantityOnHand,
    'quantityReserved': quantityReserved,
    'quantityAvailable': quantityAvailable,
    'isLowStock': isLowStock,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pendingSync': pendingSync,
  };
}

class InventorySummary {
  const InventorySummary({
    required this.farmRef,
    required this.feedActiveItems,
    required this.feedLowStockCount,
    required this.medicineActiveItems,
    required this.medicineLowStockCount,
    this.fromCache = false,
  });

  final String farmRef;
  final int feedActiveItems;
  final int feedLowStockCount;
  final int medicineActiveItems;
  final int medicineLowStockCount;
  final bool fromCache;

  int get totalLowStock => feedLowStockCount + medicineLowStockCount;

  factory InventorySummary.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final feed = json['feed'] as Map<String, dynamic>? ?? {};
    final medicine = json['medicine'] as Map<String, dynamic>? ?? {};
    return InventorySummary(
      farmRef: json['farmRef'] as String? ?? '',
      feedActiveItems: feed['activeItems'] as int? ?? 0,
      feedLowStockCount: feed['lowStockCount'] as int? ?? 0,
      medicineActiveItems: medicine['activeItems'] as int? ?? 0,
      medicineLowStockCount: medicine['lowStockCount'] as int? ?? 0,
      fromCache: fromCache,
    );
  }
}

class LowStockAlert {
  const LowStockAlert({
    required this.inventoryItemId,
    required this.displayName,
    required this.inventoryType,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    required this.suggestedAction,
    required this.message,
  });

  final String inventoryItemId;
  final String displayName;
  final InventoryType inventoryType;
  final double quantityOnHand;
  final double lowStockThreshold;
  final String suggestedAction;
  final String message;

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    return LowStockAlert(
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      inventoryType: InventoryTypeApi.fromApi(
        json['inventoryType'] as String? ?? 'FEED',
      ),
      quantityOnHand:
          double.tryParse(json['quantityOnHand']?.toString() ?? '') ?? 0,
      lowStockThreshold:
          double.tryParse(json['lowStockThreshold']?.toString() ?? '') ?? 0,
      suggestedAction: json['suggestedAction'] as String? ?? 'PURCHASE',
      message: json['message'] as String? ?? '',
    );
  }
}

class InventoryListResult {
  const InventoryListResult({
    required this.items,
    required this.lowStockAlerts,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
    this.fromCache = false,
    this.pendingSyncCount = 0,
  });

  final List<InventoryItem> items;
  final List<LowStockAlert> lowStockAlerts;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
  final bool fromCache;
  final int pendingSyncCount;
}

class InventoryTransaction {
  const InventoryTransaction({
    required this.id,
    required this.inventoryItemId,
    required this.farmRef,
    required this.inventoryType,
    required this.transactionType,
    required this.quantityDelta,
    required this.unitSnapshot,
    required this.sourceType,
    this.sourceId,
    this.reason,
    required this.recordedAt,
    required this.createdAt,
  });

  final String id;
  final String inventoryItemId;
  final String farmRef;
  final InventoryType inventoryType;
  final String transactionType;
  final double quantityDelta;
  final String unitSnapshot;
  final String sourceType;
  final String? sourceId;
  final String? reason;
  final DateTime recordedAt;
  final DateTime createdAt;

  bool get isConsumption =>
      transactionType == 'CONSUMPTION' || quantityDelta < 0;

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'] as String,
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      farmRef: json['farmRef'] as String? ?? '',
      inventoryType: InventoryTypeApi.fromApi(
        json['inventoryType'] as String? ?? 'FEED',
      ),
      transactionType: json['transactionType'] as String? ?? '',
      quantityDelta:
          double.tryParse(json['quantityDelta']?.toString() ?? '') ?? 0,
      unitSnapshot: json['unitSnapshot'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'MANUAL',
      sourceId: json['sourceId'] as String?,
      reason: json['reason'] as String?,
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class InventoryFeedCatalogBatchItem {
  const InventoryFeedCatalogBatchItem({
    required this.feedId,
    this.openingQuantity,
    this.lowStockLevel,
  });

  final String feedId;
  final double? openingQuantity;
  final double? lowStockLevel;

  Map<String, dynamic> toJson() => {
    'feedId': feedId,
    'openingQuantity': openingQuantity,
    'lowStockLevel': lowStockLevel,
  };
}

class InventoryAddBatchInput {
  const InventoryAddBatchInput({
    required this.farmRef,
    required this.items,
    this.notes,
    this.idempotencyKey,
  });

  final String farmRef;
  final List<InventoryFeedCatalogBatchItem> items;
  final String? notes;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() => {
    'farmRef': farmRef,
    'inventoryType': InventoryType.feed.apiValue,
    'operation': 'CREATE_ITEM',
    'items': items.map((i) => i.toJson()).toList(),
    if (notes != null) 'notes': notes,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
  };
}

class InventoryAddInput {
  const InventoryAddInput({
    required this.farmRef,
    required this.inventoryType,
    required this.operation,
    this.inventoryItemId,
    this.displayName,
    this.feedCatalogId,
    this.feedType,
    this.feedUnit,
    this.medicineUnit,
    this.quantity,
    this.lowStockThreshold,
    this.notes,
    this.reason,
    this.idempotencyKey,
  });

  final String farmRef;
  final InventoryType inventoryType;
  final String operation;
  final String? inventoryItemId;
  final String? displayName;
  final String? feedCatalogId;
  final FeedType? feedType;
  final FeedUnit? feedUnit;
  final MedicineUnit? medicineUnit;
  final double? quantity;
  final double? lowStockThreshold;
  final String? notes;
  final String? reason;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() => {
    'farmRef': farmRef,
    'inventoryType': inventoryType.apiValue,
    'operation': operation,
    if (inventoryItemId != null) 'inventoryItemId': inventoryItemId,
    if (displayName != null) 'displayName': displayName,
    if (feedCatalogId != null) 'feedCatalogId': feedCatalogId,
    if (feedType != null) 'feedType': feedType!.apiValue,
    if (feedUnit != null) 'feedUnit': feedUnit!.apiValue,
    if (medicineUnit != null) 'medicineUnit': medicineUnit!.apiValue,
    if (quantity != null) 'quantity': quantity,
    if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
    if (notes != null) 'notes': notes,
    if (reason != null) 'reason': reason,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
  };
}

class InventoryConsumeInput {
  const InventoryConsumeInput({
    required this.farmRef,
    required this.inventoryType,
    required this.inventoryItemId,
    required this.quantity,
    required this.sourceType,
    this.sourceId,
    this.reason,
    this.useReserved,
    this.idempotencyKey,
  });

  final String farmRef;
  final InventoryType inventoryType;
  final String inventoryItemId;
  final double quantity;
  final String sourceType;
  final String? sourceId;
  final String? reason;
  final bool? useReserved;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() => {
    'farmRef': farmRef,
    'inventoryType': inventoryType.apiValue,
    'inventoryItemId': inventoryItemId,
    'quantity': quantity,
    'sourceType': sourceType,
    if (sourceId != null) 'sourceId': sourceId,
    if (reason != null) 'reason': reason,
    if (useReserved != null) 'useReserved': useReserved,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
  };
}
