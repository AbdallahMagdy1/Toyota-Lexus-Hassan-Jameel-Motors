import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

/// A bank + its calculator settings (FinanceBankDto — rates are percentages,
/// e.g. 8.00 means 8%).
final class FinanceBank extends Equatable {
  const FinanceBank({
    this.guid,
    this.offerId,
    this.priceListTypeId,
    this.bankId,
    this.nameAr,
    this.nameEn,
    this.logo,
    this.advancedPaymentRate = 0,
    this.managementFees = 0,
    this.lastPaymentRate = 0,
    this.financeRate = 0,
    this.financePeriod = 60,
    this.maxFinancePeriod = 60,
    this.defaultFinancePeriod = 60,
    this.minSalary = 0,
  });

  final String? guid;
  final int? offerId;
  final String? priceListTypeId;
  final String? bankId;
  final String? nameAr;
  final String? nameEn;
  final String? logo;
  final double advancedPaymentRate;
  final double managementFees;
  final double lastPaymentRate;
  final double financeRate;
  final int financePeriod;
  final int maxFinancePeriod;
  final int defaultFinancePeriod;
  final double minSalary;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory FinanceBank.fromJson(Map<String, dynamic> j) => FinanceBank(
        guid: _s(j['guid']),
        offerId: _i(j['offerId']),
        priceListTypeId: _s(j['priceListTypeId']),
        bankId: _s(j['bankId']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        logo: _s(j['logo']),
        advancedPaymentRate: _d(j['advancedPaymentRate']) ?? 0,
        managementFees: _d(j['managementFees']) ?? 0,
        lastPaymentRate: _d(j['lastPaymentRate']) ?? 0,
        financeRate: _d(j['financeRate']) ?? 0,
        financePeriod: _i(j['financePeriod']) ?? 60,
        maxFinancePeriod: _i(j['maxFinancePeriod']) ?? 60,
        defaultFinancePeriod: _i(j['defaultFinancePeriod']) ?? 60,
        minSalary: _d(j['minSalary']) ?? 0,
      );

  @override
  List<Object?> get props => [guid, priceListTypeId];
}

/// One car in a bank's priced lineup (FinanceVehicleDto).
final class FinanceVehicle extends Equatable {
  const FinanceVehicle({
    this.slug,
    this.productId,
    this.year,
    this.brandAr,
    this.brandEn,
    this.brandId,
    this.groupAr,
    this.groupEn,
    this.carGroupId,
    this.descriptionAr,
    this.descriptionEn,
    this.type,
    this.minPrice,
    this.image,
    this.category,
    this.hybird = false,
  });

  final String? slug;
  final String? productId;
  final String? year;
  final String? brandAr;
  final String? brandEn;
  final String? brandId;
  final String? groupAr;
  final String? groupEn;
  final String? carGroupId;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? type; // productTypeID
  final double? minPrice;
  final String? image;
  final String? category; // SEDAN / SUV / MVP / COUPES / COMMERCIAL
  final bool hybird;

  String group(String lang) =>
      (lang == 'ar' ? groupAr : groupEn) ?? groupEn ?? groupAr ?? '';
  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory FinanceVehicle.fromJson(Map<String, dynamic> j) => FinanceVehicle(
        slug: _s(j['slug']),
        productId: _s(j['productId']),
        year: _s(j['year']),
        brandAr: _s(j['brandAr']),
        brandEn: _s(j['brandEn']),
        brandId: _s(j['brandId']),
        groupAr: _s(j['groupAr']),
        groupEn: _s(j['groupEn']),
        carGroupId: _s(j['carGroupId']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        type: _s(j['type']),
        minPrice: _d(j['minPrice']),
        image: _s(j['image']),
        category: _s(j['category']),
        hybird: j['hybird'] == true,
      );

  @override
  List<Object?> get props => [slug, productId];
}

/// Customer account type (custGroups result set) — G4 individuals need an
/// identity number, G3 companies a commercial register.
final class FinanceCustGroup extends Equatable {
  const FinanceCustGroup({this.id, this.needIdentity = true, this.nameAr, this.nameEn});

  final String? id;
  final bool needIdentity;
  final String? nameAr;
  final String? nameEn;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory FinanceCustGroup.fromJson(Map<String, dynamic> j) => FinanceCustGroup(
        id: _s(j['id']),
        needIdentity: j['needIdentity'] == true,
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
      );

  @override
  List<Object?> get props => [id];
}

/// GET /api/app/finance/filters — only the sets the mobile page uses.
final class FinanceFilters extends Equatable {
  const FinanceFilters({this.groups = const [], this.custGroups = const []});

  final List<FinanceFilterGroup> groups;
  final List<FinanceCustGroup> custGroups;

  factory FinanceFilters.fromJson(Map<String, dynamic> j) {
    List<T> parse<T>(dynamic node, T Function(Map<String, dynamic>) f) =>
        (node as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    return FinanceFilters(
      groups: parse(j['groups'], FinanceFilterGroup.fromJson),
      custGroups: parse(j['custGroups'], FinanceCustGroup.fromJson),
    );
  }

  @override
  List<Object?> get props => [groups, custGroups];
}

final class FinanceFilterGroup extends Equatable {
  const FinanceFilterGroup({this.id, this.year, this.nameAr, this.nameEn, this.brandId});

  final String? id;
  final String? year;
  final String? nameAr;
  final String? nameEn;
  final String? brandId;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory FinanceFilterGroup.fromJson(Map<String, dynamic> j) =>
      FinanceFilterGroup(
        id: _s(j['id']),
        year: _s(j['year']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        brandId: _s(j['brandId']),
      );

  @override
  List<Object?> get props => [id, year];
}
