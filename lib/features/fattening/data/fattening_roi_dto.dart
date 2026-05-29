class FatteningBatchRoi {
  const FatteningBatchRoi({
    required this.batchId,
    required this.purchase,
    required this.feed,
    required this.treatment,
    required this.totalCostBdt,
    required this.projectedSaleBdt,
    required this.profitBdt,
    this.profitMarginPct,
    this.settings,
    this.fromCache = false,
  });

  final String batchId;
  final RoiCostLine purchase;
  final RoiCostLine feed;
  final RoiCostLine treatment;
  final double totalCostBdt;
  final double projectedSaleBdt;
  final double profitBdt;
  final double? profitMarginPct;
  final FatteningRoiSettings? settings;
  final bool fromCache;

  double get projectedSaleAmount => projectedSaleBdt;

  factory FatteningBatchRoi.fromJson(Map<String, dynamic> json) {
    final raw = json['roi'] as Map<String, dynamic>? ?? json;
    return FatteningBatchRoi(
      batchId: raw['batchId'] as String,
      purchase: RoiCostLine.fromJson(
        raw['purchase'] as Map<String, dynamic>? ?? {},
      ),
      feed: RoiCostLine.fromJson(raw['feed'] as Map<String, dynamic>? ?? {}),
      treatment: RoiCostLine.fromJson(
        raw['treatment'] as Map<String, dynamic>? ?? {},
      ),
      totalCostBdt: _n(raw['totalCostBdt']),
      projectedSaleBdt: _n(
        (raw['projectedSale'] as Map<String, dynamic>?)?['amountBdt'],
      ),
      profitBdt: _n(raw['profitBdt']),
      profitMarginPct: raw['profitMarginPct'] == null
          ? null
          : _n(raw['profitMarginPct']),
      settings: raw['settings'] is Map<String, dynamic>
          ? FatteningRoiSettings.fromJson(
              raw['settings'] as Map<String, dynamic>,
            )
          : null,
      fromCache: json['fromCache'] as bool? ?? raw['fromCache'] as bool? ?? false,
    );
  }

  static double _n(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}

class RoiCostLine {
  const RoiCostLine({
    required this.amountBdt,
    this.recordCount = 0,
    this.manualAmountBdt,
    this.financeAmountBdt,
  });

  final double amountBdt;
  final int recordCount;
  final double? manualAmountBdt;
  final double? financeAmountBdt;

  factory RoiCostLine.fromJson(Map<String, dynamic> json) {
    return RoiCostLine(
      amountBdt: FatteningBatchRoi._n(json['amountBdt']),
      recordCount: json['recordCount'] as int? ?? 0,
      manualAmountBdt: json['manualAmountBdt'] == null
          ? null
          : FatteningBatchRoi._n(json['manualAmountBdt']),
      financeAmountBdt: json['financeAmountBdt'] == null
          ? null
          : FatteningBatchRoi._n(json['financeAmountBdt']),
    );
  }
}

class FatteningRoiSettings {
  const FatteningRoiSettings({
    this.purchaseCostBdt,
    this.projectedSaleBdt,
    this.notes,
  });

  final double? purchaseCostBdt;
  final double? projectedSaleBdt;
  final String? notes;

  factory FatteningRoiSettings.fromJson(Map<String, dynamic> json) {
    double? opt(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return FatteningRoiSettings(
      purchaseCostBdt: opt(json['purchaseCostBdt']),
      projectedSaleBdt: opt(json['projectedSaleBdt']),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toUpsertJson() => {
    if (purchaseCostBdt != null) 'purchaseCostBdt': purchaseCostBdt,
    if (projectedSaleBdt != null) 'projectedSaleBdt': projectedSaleBdt,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}
