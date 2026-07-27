import 'package:equatable/equatable.dart';

import '../../onboarding/domain/onboarding_slide.dart';

String? _s(dynamic v) => v?.toString();
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

/// Browse-cars category card (App_Vehicles_GetCategories) — bilingual in
/// one row so language switching is instant.
final class VehicleCategory extends Equatable {
  const VehicleCategory({
    required this.categoryId,
    this.descAr,
    this.descEn,
    this.groupsCount = 0,
    this.carsCount = 0,
    this.imageEn,
    this.imageAr,
  });

  final int categoryId;
  final String? descAr;
  final String? descEn;
  final int groupsCount;
  final int carsCount;
  final String? imageEn;
  final String? imageAr;

  String name(String lang) => (lang == 'ar' ? descAr : descEn) ?? descEn ?? descAr ?? '';
  String? image(String lang) => (lang == 'ar' ? imageAr : imageEn) ?? imageEn ?? imageAr;

  factory VehicleCategory.fromJson(Map<String, dynamic> j) => VehicleCategory(
        categoryId: _i(j['categoryId']) ?? 0,
        descAr: _s(j['descAr']),
        descEn: _s(j['descEn']),
        groupsCount: _i(j['groupsCount']) ?? 0,
        carsCount: _i(j['carsCount']) ?? 0,
        imageEn: _s(j['imageEn']),
        imageAr: _s(j['imageAr']),
      );

  @override
  List<Object?> get props => [categoryId];
}

/// Guest-home offer (App_Offers_GetHome) — bilingual in one row.
final class AppOffer extends Equatable {
  const AppOffer({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.excerptAr,
    this.excerptEn,
    this.slugAr,
    this.slugEn,
    this.typeNameAr,
    this.typeNameEn,
    this.endDate,
    this.totalDays,
    this.imageAr,
    this.imageEn,
  });

  final int id;
  final String? titleAr;
  final String? titleEn;
  final String? excerptAr;
  final String? excerptEn;
  final String? slugAr;
  final String? slugEn;
  final String? typeNameAr;
  final String? typeNameEn;
  final DateTime? endDate;
  final int? totalDays;
  final String? imageAr;
  final String? imageEn;

  String title(String lang) => (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String excerpt(String lang) =>
      (lang == 'ar' ? excerptAr : excerptEn) ?? excerptEn ?? excerptAr ?? '';
  String typeName(String lang) =>
      (lang == 'ar' ? typeNameAr : typeNameEn) ?? typeNameEn ?? typeNameAr ?? '';
  String? image(String lang) => (lang == 'ar' ? imageAr : imageEn) ?? imageEn ?? imageAr;
  String? get slug => slugEn ?? slugAr;

  int? get daysLeft {
    if (endDate == null) return totalDays;
    final left = endDate!.difference(DateTime.now()).inDays;
    return left < 0 ? 0 : left;
  }

  factory AppOffer.fromJson(Map<String, dynamic> j) => AppOffer(
        id: _i(j['id']) ?? 0,
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        excerptAr: _s(j['excerptAr']),
        excerptEn: _s(j['excerptEn']),
        slugAr: _s(j['slugAr']),
        slugEn: _s(j['slugEn']),
        typeNameAr: _s(j['typeNameAr']),
        typeNameEn: _s(j['typeNameEn']),
        endDate: j['endDate'] == null ? null : DateTime.tryParse('${j['endDate']}'),
        totalDays: _i(j['totalDays']),
        imageAr: _s(j['imageAr']),
        imageEn: _s(j['imageEn']),
      );

  @override
  List<Object?> get props => [id];
}

/// GET /api/app/guest-home — the whole guest home in one payload.
final class GuestHome extends Equatable {
  const GuestHome({
    this.hero = const [],
    this.categories = const [],
    this.vehicleOffers = const [],
    this.maintenanceOffers = const [],
  });

  final List<OnboardingSlide> hero;
  final List<VehicleCategory> categories;
  final List<AppOffer> vehicleOffers;
  final List<AppOffer> maintenanceOffers;

  factory GuestHome.fromJson(Map<String, dynamic> j) {
    List<T> parse<T>(dynamic node, T Function(Map<String, dynamic>) f) =>
        (node as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    return GuestHome(
      hero: parse(j['hero'], OnboardingSlide.fromJson),
      categories: parse(j['categories'], VehicleCategory.fromJson),
      vehicleOffers: parse(j['vehicleOffers'], AppOffer.fromJson),
      maintenanceOffers: parse(j['maintenanceOffers'], AppOffer.fromJson),
    );
  }

  @override
  List<Object?> get props => [hero, categories, vehicleOffers, maintenanceOffers];
}
