import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse('$v');

/// One offer row — wire-identical to the website's OfferDto
/// (GET /api/offers/all → offers[]). Bilingual in one row.
final class SiteOffer extends Equatable {
  const SiteOffer({
    required this.id,
    this.guid,
    this.titleAr,
    this.titleEn,
    this.excerptAr,
    this.excerptEn,
    this.slugAr,
    this.slugEn,
    this.typeId,
    this.typeNameAr,
    this.typeNameEn,
    this.startDate,
    this.endDate,
    this.totalDays,
    this.imageAr,
    this.imageEn,
    this.allowInstallments = false,
    this.brandList,
  });

  final int id;
  final String? guid;
  final String? titleAr;
  final String? titleEn;
  final String? excerptAr;
  final String? excerptEn;
  final String? slugAr;
  final String? slugEn;
  final int? typeId;
  final String? typeNameAr;
  final String? typeNameEn;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? totalDays;
  final String? imageAr;
  final String? imageEn;
  final bool allowInstallments;

  /// Comma-joined brand ids from siteOfferSupportedCars — empty = all brands.
  final String? brandList;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String excerpt(String lang) =>
      (lang == 'ar' ? excerptAr : excerptEn) ?? excerptEn ?? excerptAr ?? '';
  String typeName(String lang) =>
      (lang == 'ar' ? typeNameAr : typeNameEn) ?? typeNameEn ?? typeNameAr ?? '';
  String? image(String lang) =>
      (lang == 'ar' ? imageAr : imageEn) ?? imageEn ?? imageAr;
  String? get slug => slugEn ?? slugAr;

  /// The website's client-side visibility rule: an offer with no supported-car
  /// rows is cross-brand; otherwise its brandList must contain the wanted id.
  bool visibleForBrand(String? wantedDbId) {
    if (wantedDbId == null) return true;
    final ids = (brandList ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return ids.isEmpty || ids.contains(wantedDbId);
  }

  factory SiteOffer.fromJson(Map<String, dynamic> j) => SiteOffer(
        id: _i(j['id']) ?? 0,
        guid: _s(j['guid']),
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        excerptAr: _s(j['excerptAr']),
        excerptEn: _s(j['excerptEn']),
        slugAr: _s(j['slugAr']),
        slugEn: _s(j['slugEn']),
        typeId: _i(j['typeId']),
        typeNameAr: _s(j['typeNameAr']),
        typeNameEn: _s(j['typeNameEn']),
        startDate: _dt(j['startDate']),
        endDate: _dt(j['endDate']),
        totalDays: _i(j['totalDays']),
        imageAr: _s(j['imageAr']),
        imageEn: _s(j['imageEn']),
        allowInstallments: j['allowInstallments'] == true,
        brandList: _s(j['brandList']),
      );

  @override
  List<Object?> get props => [id];
}

/// Offer type catalog row (drives section order, like the website).
final class OfferType extends Equatable {
  const OfferType({required this.id, this.nameAr, this.nameEn});

  final int id;
  final String? nameAr;
  final String? nameEn;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory OfferType.fromJson(Map<String, dynamic> j) =>
      OfferType(id: _i(j['id']) ?? 0, nameAr: _s(j['nameAr']), nameEn: _s(j['nameEn']));

  @override
  List<Object?> get props => [id];
}

final class OfferPackage extends Equatable {
  const OfferPackage({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.price,
  });

  final int id;
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? price;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ?? descriptionEn ?? descriptionAr ?? '';

  factory OfferPackage.fromJson(Map<String, dynamic> j) => OfferPackage(
        id: _i(j['id']) ?? 0,
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        price: _d(j['price']),
      );

  @override
  List<Object?> get props => [id];
}

final class OfferVehicle extends Equatable {
  const OfferVehicle({
    this.nameAr,
    this.nameEn,
    this.brandId,
    this.groupEn,
    this.groupId,
    this.year,
    this.slug,
    this.fromYear,
    this.toYear,
    this.packageId,
    this.productTypeId,
    this.image,
  });

  final String? nameAr;
  final String? nameEn;
  final String? brandId;
  final String? groupEn;
  final String? groupId;
  final String? year;
  final String? slug;
  final int? fromYear;
  final int? toYear;
  final int? packageId;
  final String? productTypeId;
  final String? image;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory OfferVehicle.fromJson(Map<String, dynamic> j) => OfferVehicle(
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        brandId: _s(j['brandId']),
        groupEn: _s(j['groupEn']),
        groupId: _s(j['groupId']),
        year: _s(j['year']),
        slug: _s(j['slug']),
        fromYear: _i(j['fromYear']),
        toYear: _i(j['toYear']),
        packageId: _i(j['packageId']),
        productTypeId: _s(j['productTypeId']),
        image: _s(j['image']),
      );

  @override
  List<Object?> get props => [slug, packageId, year];
}

/// Full offer detail (GET /api/app/offers/{slug}) — description, terms,
/// packages, supported vehicles and the bank finance block for finance offers.
final class OfferDetail extends Equatable {
  const OfferDetail({
    required this.offer,
    this.descriptionAr,
    this.descriptionEn,
    this.termsAr,
    this.termsEn,
    this.bannerAr,
    this.bannerEn,
    this.reservationOnly = false,
    this.bankGuid,
    this.bankNameAr,
    this.bankNameEn,
    this.bankLogo,
    this.financeRate,
    this.defaultFinancePeriod,
    this.maxFinancePeriod,
    this.packages = const [],
    this.supportedVehicles = const [],
  });

  final SiteOffer offer;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? termsAr;
  final String? termsEn;
  final String? bannerAr;
  final String? bannerEn;
  final bool reservationOnly;
  final String? bankGuid;
  final String? bankNameAr;
  final String? bankNameEn;
  final String? bankLogo;
  final double? financeRate;
  final int? defaultFinancePeriod;
  final int? maxFinancePeriod;
  final List<OfferPackage> packages;
  final List<OfferVehicle> supportedVehicles;

  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ?? descriptionEn ?? descriptionAr ?? '';
  String terms(String lang) =>
      (lang == 'ar' ? termsAr : termsEn) ?? termsEn ?? termsAr ?? '';
  String bankName(String lang) =>
      (lang == 'ar' ? bankNameAr : bankNameEn) ?? bankNameEn ?? bankNameAr ?? '';

  /// Hero candidates in the website's order: banner first, then card image.
  String? banner(String lang) => lang == 'ar'
      ? (bannerAr ?? offer.imageAr ?? bannerEn ?? offer.imageEn)
      : (bannerEn ?? offer.imageEn ?? bannerAr ?? offer.imageAr);

  bool get isVehicleOffer => offer.typeId == 2;
  bool get isMaintenanceOffer => offer.typeId == 3;
  bool get isFinanceOffer => isVehicleOffer && (bankGuid ?? '').isNotEmpty;

  factory OfferDetail.fromJson(Map<String, dynamic> j) => OfferDetail(
        offer: SiteOffer.fromJson(j),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        termsAr: _s(j['termsAr']),
        termsEn: _s(j['termsEn']),
        bannerAr: _s(j['bannerAr']),
        bannerEn: _s(j['bannerEn']),
        reservationOnly: j['reservationOnly'] == true,
        bankGuid: _s(j['bankGuid']),
        bankNameAr: _s(j['bankNameAr']),
        bankNameEn: _s(j['bankNameEn']),
        bankLogo: _s(j['bankLogo']),
        financeRate: _d(j['financeRate']),
        defaultFinancePeriod: _i(j['defaultFinancePeriod']),
        maxFinancePeriod: _i(j['maxFinancePeriod']),
        packages: (j['packages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OfferPackage.fromJson)
            .toList(),
        supportedVehicles: (j['supportedVehicles'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OfferVehicle.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [offer];
}
