import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

/// One filter row (EpartFilterDto) — categories use id + parentId to form
/// the 3-level tree: main → sub(parentId=main) → subSub(parentId=sub).
final class PartsFilterItem extends Equatable {
  const PartsFilterItem({this.id, this.parentId, this.nameAr, this.nameEn, this.image});

  final String? id;
  final String? parentId;
  final String? nameAr;
  final String? nameEn;
  final String? image;

  String name(String lang) =>
      ((lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '').trim();

  factory PartsFilterItem.fromJson(Map<String, dynamic> j) => PartsFilterItem(
        id: _s(j['id']),
        parentId: _s(j['parentId']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        image: _s(j['image']),
      );

  @override
  List<Object?> get props => [id, parentId];
}

final class PartsFilters extends Equatable {
  const PartsFilters({
    this.mainCategories = const [],
    this.subCategories = const [],
    this.years = const [],
  });

  final List<PartsFilterItem> mainCategories;
  final List<PartsFilterItem> subCategories;
  final List<PartsFilterItem> years;

  List<PartsFilterItem> subsOf(String? mainId) => mainId == null
      ? const []
      : subCategories.where((c) => c.parentId == mainId).toList();

  factory PartsFilters.fromJson(Map<String, dynamic> j) {
    List<PartsFilterItem> parse(dynamic node) =>
        (node as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PartsFilterItem.fromJson)
            .toList();
    return PartsFilters(
      mainCategories: parse(j['mainCategories']),
      subCategories: parse(j['subCategories']),
      years: parse(j['years']),
    );
  }

  @override
  List<Object?> get props => [mainCategories, subCategories, years];
}

/// One part card (EpartItemDto).
final class PartItem extends Equatable {
  const PartItem({
    this.guid,
    this.productId,
    this.productNo,
    this.descriptionAr,
    this.descriptionEn,
    this.salesPrice,
    this.salesPriceDiscount,
    this.totalQty,
    this.image,
  });

  final String? guid;
  final String? productId;
  final String? productNo;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? salesPrice;
  final double? salesPriceDiscount;
  final double? totalQty;
  final String? image;

  String name(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  bool get inStock => (totalQty ?? 0) > 0;
  bool get hasDiscount =>
      (salesPriceDiscount ?? 0) > 0 &&
      (salesPriceDiscount ?? 0) < (salesPrice ?? 0);

  /// The price the customer pays.
  double? get effectivePrice => hasDiscount ? salesPriceDiscount : salesPrice;

  factory PartItem.fromJson(Map<String, dynamic> j) => PartItem(
        guid: _s(j['guid']),
        productId: _s(j['productId']),
        productNo: _s(j['productNo']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        salesPrice: _d(j['salesPrice']),
        salesPriceDiscount: _d(j['salesPriceDiscount']),
        totalQty: _d(j['totalQty']),
        image: _s(j['image']),
      );

  @override
  List<Object?> get props => [guid];
}

/// Dashboard "Parts Banners" hero slide (PartsBannerDto).
final class PartsBanner extends Equatable {
  const PartsBanner({
    this.guid,
    this.mediaType,
    this.mediaUrl,
    this.posterUrl,
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.discountType,
    this.discountValue,
    this.couponCode,
    this.endsAt,
  });

  final String? guid;
  final String? mediaType; // image | video
  final String? mediaUrl;
  final String? posterUrl;
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? discountType; // P | AT | AP | D
  final double? discountValue;
  final String? couponCode;
  final DateTime? endsAt;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String subtitle(String lang) =>
      (lang == 'ar' ? subtitleAr : subtitleEn) ?? subtitleEn ?? subtitleAr ?? '';

  /// The website's discountBadge(): P→"{v}% OFF", AT/AP→amount off, D→bundle.
  String? badge(String lang) {
    final v = discountValue ?? 0;
    return switch (discountType) {
      'P' => lang == 'ar' ? 'خصم ${v.round()}%' : '${v.round()}% OFF',
      'AT' || 'AP' =>
        lang == 'ar' ? 'خصم ${v.round()}' : '${v.round()} OFF',
      'D' => lang == 'ar' ? 'اشترِ واحصل' : 'BUY & GET',
      _ => (couponCode ?? '').isNotEmpty ? '🎟 $couponCode' : null,
    };
  }

  String? get imageUrl => mediaType == 'video' ? posterUrl : mediaUrl;

  factory PartsBanner.fromJson(Map<String, dynamic> j) => PartsBanner(
        guid: _s(j['guid']),
        mediaType: _s(j['mediaType']),
        mediaUrl: _s(j['mediaUrl']),
        posterUrl: _s(j['posterUrl']),
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        subtitleAr: _s(j['subtitleAr']),
        subtitleEn: _s(j['subtitleEn']),
        discountType: _s(j['discountType']),
        discountValue: _d(j['discountValue']),
        couponCode: _s(j['couponCode']),
        endsAt: j['endsAt'] == null ? null : DateTime.tryParse('${j['endsAt']}'),
      );

  @override
  List<Object?> get props => [guid];
}

final class PartsSearchResult extends Equatable {
  const PartsSearchResult({this.items = const [], this.totalCount = 0});

  final List<PartItem> items;
  final int totalCount;

  factory PartsSearchResult.fromJson(Map<String, dynamic> j) =>
      PartsSearchResult(
        items: (j['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PartItem.fromJson)
            .toList(),
        totalCount: _i(j['totalCount']) ?? 0,
      );

  @override
  List<Object?> get props => [items, totalCount];
}

/// Dashboard-managed parts-page hero (App Onboarding placement 'parts_hero').
final class PartsHero extends Equatable {
  const PartsHero({
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.mediaType,
    this.mediaUrl,
  });

  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? mediaType; // image | video
  final String? mediaUrl;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String subtitle(String lang) =>
      (lang == 'ar' ? subtitleAr : subtitleEn) ?? subtitleEn ?? subtitleAr ?? '';

  factory PartsHero.fromJson(Map<String, dynamic> j) => PartsHero(
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        subtitleAr: _s(j['subtitleAr']),
        subtitleEn: _s(j['subtitleEn']),
        mediaType: _s(j['mediaType']),
        mediaUrl: _s(j['mediaUrl']),
      );

  @override
  List<Object?> get props =>
      [titleAr, titleEn, subtitleAr, subtitleEn, mediaType, mediaUrl];
}
