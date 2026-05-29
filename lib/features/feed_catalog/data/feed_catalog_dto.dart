import '../../feed/data/feed_dto.dart';



class FeedCatalogItem {

  const FeedCatalogItem({

    required this.id,

    required this.code,

    required this.nameBn,

    required this.nameEn,

    required this.category,

    required this.defaultUnit,

    required this.legacyFeedType,

    this.approxPriceBdt,

    this.availabilityScore,

    required this.sortOrder,

    this.aliases = const [],

    this.nutrientTags = const [],

    this.isPopular = false,

  });



  final String id;

  final String code;

  final String nameBn;

  final String nameEn;

  final String category;

  final FeedUnit defaultUnit;

  final FeedType legacyFeedType;

  final double? approxPriceBdt;

  final int? availabilityScore;

  final int sortOrder;

  final List<String> aliases;

  final List<String> nutrientTags;

  final bool isPopular;



  bool matchesQuery(String query) {

    final q = query.trim();

    if (q.isEmpty) return true;

    final lower = q.toLowerCase();

    if (nameBn.contains(q)) return true;

    if (nameEn.toLowerCase().contains(lower)) return true;

    if (code.toLowerCase().contains(lower)) return true;

    return aliases.any(

      (a) => a.contains(q) || a.toLowerCase().contains(lower),

    );

  }



  factory FeedCatalogItem.fromJson(Map<String, dynamic> json) {

    return FeedCatalogItem(

      id: json['id'] as String? ?? json['code'] as String? ?? '',

      code: json['code'] as String? ?? '',

      nameBn: json['nameBn'] as String? ?? '',

      nameEn: json['nameEn'] as String? ?? '',

      category: json['category'] as String? ?? 'CUSTOM',

      defaultUnit: FeedUnitApi.fromApi(json['defaultUnit'] as String? ?? 'KG'),

      legacyFeedType: FeedTypeApi.fromApi(

        json['legacyFeedType'] as String? ?? 'OTHER',

      ),

      approxPriceBdt: json['approxPriceBdt'] == null

          ? null

          : double.tryParse(json['approxPriceBdt'].toString()),

      availabilityScore: json['availabilityScore'] as int?,

      sortOrder: json['sortOrder'] as int? ?? 0,

      aliases: (json['aliases'] as List<dynamic>? ?? [])

          .whereType<String>()

          .toList(),

      nutrientTags: (json['nutrientTags'] as List<dynamic>? ?? [])

          .whereType<String>()

          .toList(),

      isPopular: json['isPopular'] as bool? ?? false,

    );

  }



  Map<String, dynamic> toJson() => {

    'id': id,

    'code': code,

    'nameBn': nameBn,

    'nameEn': nameEn,

    'category': category,

    'defaultUnit': defaultUnit.apiValue,

    'legacyFeedType': legacyFeedType.apiValue,

    if (approxPriceBdt != null) 'approxPriceBdt': approxPriceBdt,

    if (availabilityScore != null) 'availabilityScore': availabilityScore,

    'sortOrder': sortOrder,

    'aliases': aliases,

    'nutrientTags': nutrientTags,

    'isPopular': isPopular,

  };

}

