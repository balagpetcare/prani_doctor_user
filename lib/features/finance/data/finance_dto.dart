enum ExpenseCategory { feed, medicine, labor, equipment, transport, other }

enum IncomeSource { milkSales, animalSales, subsidy, service, other }

extension ExpenseCategoryApi on ExpenseCategory {
  String get apiValue => switch (this) {
    ExpenseCategory.feed => 'FEED',
    ExpenseCategory.medicine => 'MEDICINE',
    ExpenseCategory.labor => 'LABOR',
    ExpenseCategory.equipment => 'EQUIPMENT',
    ExpenseCategory.transport => 'TRANSPORT',
    ExpenseCategory.other => 'OTHER',
  };

  static ExpenseCategory fromApi(String value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.apiValue == value.toUpperCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

extension IncomeSourceApi on IncomeSource {
  String get apiValue => switch (this) {
    IncomeSource.milkSales => 'MILK_SALES',
    IncomeSource.animalSales => 'ANIMAL_SALES',
    IncomeSource.subsidy => 'SUBSIDY',
    IncomeSource.service => 'SERVICE',
    IncomeSource.other => 'OTHER',
  };

  static IncomeSource fromApi(String value) {
    return IncomeSource.values.firstWhere(
      (s) => s.apiValue == value.toUpperCase(),
      orElse: () => IncomeSource.other,
    );
  }
}

class FinanceRecord {
  const FinanceRecord({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amountBdt,
    required this.recordedDate,
    this.category,
    this.source,
    this.farmRef,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final String customerId;
  final String type;
  final double amountBdt;
  final DateTime recordedDate;
  final ExpenseCategory? category;
  final IncomeSource? source;
  final String? farmRef;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  bool get isExpense => type.toUpperCase() == 'EXPENSE';

  FinanceRecord copyWith({
    double? amountBdt,
    ExpenseCategory? category,
    IncomeSource? source,
    String? farmRef,
    DateTime? recordedDate,
    String? notes,
    bool? pendingSync,
    bool? fromCache,
    DateTime? updatedAt,
  }) {
    return FinanceRecord(
      id: id,
      customerId: customerId,
      type: type,
      amountBdt: amountBdt ?? this.amountBdt,
      recordedDate: recordedDate ?? this.recordedDate,
      category: category ?? this.category,
      source: source ?? this.source,
      farmRef: farmRef ?? this.farmRef,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory FinanceRecord.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
    bool pendingSync = false,
  }) {
    return FinanceRecord(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      type: json['type'] as String? ?? 'EXPENSE',
      amountBdt: double.tryParse(json['amountBdt']?.toString() ?? '') ?? 0,
      recordedDate:
          DateTime.tryParse(json['recordedDate'] as String? ?? '') ??
          DateTime.now(),
      category: json['category'] == null
          ? null
          : ExpenseCategoryApi.fromApi(json['category'] as String),
      source: json['source'] == null
          ? null
          : IncomeSourceApi.fromApi(json['source'] as String),
      farmRef: json['farmRef'] as String?,
      notes: json['notes'] as String?,
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
    'type': type,
    'amountBdt': amountBdt.toStringAsFixed(2),
    'recordedDate': _dateOnly(recordedDate),
    if (category != null) 'category': category!.apiValue,
    if (source != null) 'source': source!.apiValue,
    if (farmRef != null) 'farmRef': farmRef,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pendingSync': pendingSync,
  };
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ExpenseInput {
  const ExpenseInput({
    this.farmRef,
    required this.category,
    required this.amountBdt,
    required this.recordedDate,
    this.notes,
  });

  final String? farmRef;
  final ExpenseCategory category;
  final double amountBdt;
  final DateTime recordedDate;
  final String? notes;

  Map<String, dynamic> toCreateJson() => {
    if (farmRef != null && farmRef!.isNotEmpty) 'farmRef': farmRef,
    'category': category.apiValue,
    'amountBdt': amountBdt,
    'recordedDate': _dateOnly(recordedDate),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };

  Map<String, dynamic> toPatchJson() => toCreateJson();

  Map<String, dynamic> toDraftJson() => {
    'farmRef': farmRef,
    'category': category.apiValue,
    'amountBdt': amountBdt,
    'recordedDate': _dateOnly(recordedDate),
    'notes': notes,
  };

  factory ExpenseInput.fromDraftJson(Map<String, dynamic> json) {
    return ExpenseInput(
      farmRef: json['farmRef'] as String?,
      category: ExpenseCategoryApi.fromApi(
        json['category'] as String? ?? 'OTHER',
      ),
      amountBdt: (json['amountBdt'] as num?)?.toDouble() ?? 0,
      recordedDate:
          DateTime.tryParse(json['recordedDate'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}

class IncomeInput {
  const IncomeInput({
    this.farmRef,
    required this.source,
    required this.amountBdt,
    required this.recordedDate,
    this.notes,
  });

  final String? farmRef;
  final IncomeSource source;
  final double amountBdt;
  final DateTime recordedDate;
  final String? notes;

  Map<String, dynamic> toCreateJson() => {
    if (farmRef != null && farmRef!.isNotEmpty) 'farmRef': farmRef,
    'source': source.apiValue,
    'amountBdt': amountBdt,
    'recordedDate': _dateOnly(recordedDate),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };

  Map<String, dynamic> toPatchJson() => toCreateJson();

  Map<String, dynamic> toDraftJson() => {
    'farmRef': farmRef,
    'source': source.apiValue,
    'amountBdt': amountBdt,
    'recordedDate': _dateOnly(recordedDate),
    'notes': notes,
  };

  factory IncomeInput.fromDraftJson(Map<String, dynamic> json) {
    return IncomeInput(
      farmRef: json['farmRef'] as String?,
      source: IncomeSourceApi.fromApi(json['source'] as String? ?? 'OTHER'),
      amountBdt: (json['amountBdt'] as num?)?.toDouble() ?? 0,
      recordedDate:
          DateTime.tryParse(json['recordedDate'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}

class FinancePageResult {
  const FinancePageResult({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.fromCache = false,
    this.pendingSyncCount = 0,
  });

  final List<FinanceRecord> records;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool fromCache;
  final int pendingSyncCount;

  FinancePageResult copyWith({
    List<FinanceRecord>? records,
    bool? fromCache,
    int? pendingSyncCount,
  }) {
    return FinancePageResult(
      records: records ?? this.records,
      total: total,
      page: page,
      limit: limit,
      hasMore: hasMore,
      fromCache: fromCache ?? this.fromCache,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}

class FinancePreviousPeriod {
  const FinancePreviousPeriod({
    required this.from,
    required this.to,
    required this.totalIncomeBdt,
    required this.totalExpenseBdt,
    required this.profitBdt,
  });

  final String from;
  final String to;
  final double totalIncomeBdt;
  final double totalExpenseBdt;
  final double profitBdt;

  factory FinancePreviousPeriod.fromJson(Map<String, dynamic> json) {
    return FinancePreviousPeriod(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      totalIncomeBdt: (json['totalIncomeBdt'] as num?)?.toDouble() ?? 0,
      totalExpenseBdt: (json['totalExpenseBdt'] as num?)?.toDouble() ?? 0,
      profitBdt: (json['profitBdt'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FinanceProfitData {
  const FinanceProfitData({
    required this.from,
    required this.to,
    required this.totalIncomeBdt,
    required this.totalExpenseBdt,
    required this.profitBdt,
    required this.previousPeriod,
    this.profitChangePercent,
    this.fromCache = false,
  });

  final String from;
  final String to;
  final double totalIncomeBdt;
  final double totalExpenseBdt;
  final double profitBdt;
  final FinancePreviousPeriod previousPeriod;
  final double? profitChangePercent;
  final bool fromCache;

  factory FinanceProfitData.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return FinanceProfitData(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      totalIncomeBdt: (json['totalIncomeBdt'] as num?)?.toDouble() ?? 0,
      totalExpenseBdt: (json['totalExpenseBdt'] as num?)?.toDouble() ?? 0,
      profitBdt: (json['profitBdt'] as num?)?.toDouble() ?? 0,
      previousPeriod: FinancePreviousPeriod.fromJson(
        json['previousPeriod'] as Map<String, dynamic>? ?? {},
      ),
      profitChangePercent: json['profitChangePercent'] == null
          ? null
          : (json['profitChangePercent'] as num?)?.toDouble(),
      fromCache: fromCache,
    );
  }
}

class FinanceTrendPoint {
  const FinanceTrendPoint({required this.date, required this.amountBdt});

  final String date;
  final double amountBdt;

  factory FinanceTrendPoint.fromJson(Map<String, dynamic> json) {
    return FinanceTrendPoint(
      date: json['date'] as String? ?? '',
      amountBdt: (json['amountBdt'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FinanceChartsData {
  const FinanceChartsData({
    required this.from,
    required this.to,
    required this.incomeTrend,
    required this.expenseTrend,
    required this.profitTrend,
    this.fromCache = false,
  });

  final String from;
  final String to;
  final List<FinanceTrendPoint> incomeTrend;
  final List<FinanceTrendPoint> expenseTrend;
  final List<FinanceTrendPoint> profitTrend;
  final bool fromCache;

  factory FinanceChartsData.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    List<FinanceTrendPoint> mapTrend(String key) {
      return (json[key] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FinanceTrendPoint.fromJson)
          .toList();
    }

    return FinanceChartsData(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      incomeTrend: mapTrend('incomeTrend'),
      expenseTrend: mapTrend('expenseTrend'),
      profitTrend: mapTrend('profitTrend'),
      fromCache: fromCache,
    );
  }
}

class FinanceAggregateBucket {
  const FinanceAggregateBucket({
    required this.label,
    required this.totalBdt,
    required this.count,
  });

  final String label;
  final double totalBdt;
  final int count;

  factory FinanceAggregateBucket.fromJson(
    Map<String, dynamic> json, {
    required String labelKey,
  }) {
    return FinanceAggregateBucket(
      label: json[labelKey] as String? ?? '',
      totalBdt: (json['totalBdt'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}

class FinanceExportHooks {
  const FinanceExportHooks({
    required this.csvPath,
    required this.pdfPath,
    required this.note,
  });

  final String csvPath;
  final String pdfPath;
  final String note;

  factory FinanceExportHooks.fromJson(Map<String, dynamic> json) {
    return FinanceExportHooks(
      csvPath: json['csvPath'] as String? ?? '',
      pdfPath: json['pdfPath'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class FinanceReportsData {
  const FinanceReportsData({
    required this.from,
    required this.to,
    required this.totalIncomeBdt,
    required this.totalExpenseBdt,
    required this.profitBdt,
    required this.expenseByCategory,
    required this.incomeBySource,
    required this.export,
    this.fromCache = false,
  });

  final String from;
  final String to;
  final double totalIncomeBdt;
  final double totalExpenseBdt;
  final double profitBdt;
  final List<FinanceAggregateBucket> expenseByCategory;
  final List<FinanceAggregateBucket> incomeBySource;
  final FinanceExportHooks export;
  final bool fromCache;

  factory FinanceReportsData.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return FinanceReportsData(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      totalIncomeBdt: (json['totalIncomeBdt'] as num?)?.toDouble() ?? 0,
      totalExpenseBdt: (json['totalExpenseBdt'] as num?)?.toDouble() ?? 0,
      profitBdt: (json['profitBdt'] as num?)?.toDouble() ?? 0,
      expenseByCategory: (json['expenseByCategory'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => FinanceAggregateBucket.fromJson(e, labelKey: 'category'))
          .toList(),
      incomeBySource: (json['incomeBySource'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => FinanceAggregateBucket.fromJson(e, labelKey: 'source'))
          .toList(),
      export: FinanceExportHooks.fromJson(
        json['export'] as Map<String, dynamic>? ?? {},
      ),
      fromCache: fromCache,
    );
  }
}
