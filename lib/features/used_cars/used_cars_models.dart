import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
int? _i(dynamic v) => v == null ? null : int.tryParse('$v');
double? _d(dynamic v) => v == null ? null : double.tryParse('$v');

/// One approved listing card (used-cars/list).
final class UsedCarItem extends Equatable {
  const UsedCarItem({
    required this.guid,
    this.brand,
    this.carName,
    this.modelName,
    this.carYear,
    this.price,
    this.mileage,
    this.coverImage,
    this.inspectionBadge,
  });

  final String guid;
  final String? brand;
  final String? carName;
  final String? modelName;
  final int? carYear;
  final double? price;
  final int? mileage;
  final String? coverImage;
  final String? inspectionBadge;

  bool get hjInspected => (inspectionBadge ?? '').isNotEmpty;

  String title() =>
      [brand, carName, modelName].where((s) => (s ?? '').isNotEmpty).join(' ');

  factory UsedCarItem.fromJson(Map<String, dynamic> j) => UsedCarItem(
        guid: _s(j['guid']) ?? '',
        brand: _s(j['brand']),
        carName: _s(j['carName']),
        modelName: _s(j['modelName']),
        carYear: _i(j['carYear']),
        price: _d(j['price']),
        mileage: _i(j['mileage']),
        coverImage: _s(j['coverImage']),
        inspectionBadge: _s(j['inspectionBadge']),
      );

  @override
  List<Object?> get props => [guid];
}

final class UsedCarFeature extends Equatable {
  const UsedCarFeature({this.ar, this.en});
  final String? ar;
  final String? en;

  String name(String lang) => (lang == 'ar' ? ar : en) ?? en ?? ar ?? '';

  factory UsedCarFeature.fromJson(Map<String, dynamic> j) =>
      UsedCarFeature(ar: _s(j['ar']), en: _s(j['en']));

  @override
  List<Object?> get props => [ar, en];
}

final class UsedCarInspItem extends Equatable {
  const UsedCarInspItem({this.nameAr, this.nameEn, this.status = 'ok', this.note});
  final String? nameAr;
  final String? nameEn;
  final String status; // ok | bad
  final String? note;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';
  bool get ok => status.toLowerCase() != 'bad';

  factory UsedCarInspItem.fromJson(Map<String, dynamic> j) => UsedCarInspItem(
        nameAr: _s(j['nameAr']) ?? _s(j['name']),
        nameEn: _s(j['nameEn']) ?? _s(j['name']),
        status: _s(j['status']) ?? 'ok',
        note: _s(j['note']),
      );

  @override
  List<Object?> get props => [nameAr, nameEn, status];
}

final class UsedCarInspCategory extends Equatable {
  const UsedCarInspCategory(
      {this.nameAr, this.nameEn, this.badCount = 0, this.items = const []});
  final String? nameAr;
  final String? nameEn;
  final int badCount;
  final List<UsedCarInspItem> items;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory UsedCarInspCategory.fromJson(Map<String, dynamic> j) =>
      UsedCarInspCategory(
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        badCount: _i(j['badCount']) ?? 0,
        items: ((j['items'] as List<dynamic>?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(UsedCarInspItem.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [nameAr, nameEn, items];
}

/// Full listing detail — the website's used-cars/[guid] page.
final class UsedCarDetail extends Equatable {
  const UsedCarDetail({
    required this.guid,
    this.brand,
    this.carName,
    this.modelName,
    this.carYear,
    this.price,
    this.mileage,
    this.notes,
    this.fuelType,
    this.condition,
    this.driveType,
    this.seats,
    this.doors,
    this.exteriorColor,
    this.interiorColor,
    this.origin,
    this.gearbox,
    this.licenseDuration,
    this.inspectionBadge,
    this.ownerPhone,
    this.images = const [],
    this.featuresSafety = const [],
    this.featuresComfort = const [],
    this.featuresTech = const [],
    this.featuresExterior = const [],
    this.inspection = const [],
  });

  final String guid;
  final String? brand;
  final String? carName;
  final String? modelName;
  final int? carYear;
  final double? price;
  final int? mileage;
  final String? notes;
  final String? fuelType;
  final String? condition;
  final String? driveType;
  final int? seats;
  final int? doors;
  final String? exteriorColor;
  final String? interiorColor;
  final String? origin;
  final String? gearbox;
  final String? licenseDuration;
  final String? inspectionBadge;
  final String? ownerPhone;
  final List<String> images;
  final List<UsedCarFeature> featuresSafety;
  final List<UsedCarFeature> featuresComfort;
  final List<UsedCarFeature> featuresTech;
  final List<UsedCarFeature> featuresExterior;
  final List<UsedCarInspCategory> inspection;

  bool get hjInspected => (inspectionBadge ?? '').isNotEmpty;

  String title() =>
      [brand, carName, modelName].where((s) => (s ?? '').isNotEmpty).join(' ');

  factory UsedCarDetail.fromJson(Map<String, dynamic> j) {
    List<UsedCarFeature> feats(String key) =>
        ((j[key] as List<dynamic>?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(UsedCarFeature.fromJson)
            .toList();
    return UsedCarDetail(
      guid: _s(j['guid']) ?? '',
      brand: _s(j['brand']),
      carName: _s(j['carName']),
      modelName: _s(j['modelName']),
      carYear: _i(j['carYear']),
      price: _d(j['price']),
      mileage: _i(j['mileage']),
      notes: _s(j['notes']),
      fuelType: _s(j['fuelType']),
      condition: _s(j['condition']),
      driveType: _s(j['driveType']),
      seats: _i(j['seats']),
      doors: _i(j['doors']),
      exteriorColor: _s(j['exteriorColor']),
      interiorColor: _s(j['interiorColor']),
      origin: _s(j['origin']),
      gearbox: _s(j['gearbox']),
      licenseDuration: _s(j['licenseDuration']),
      inspectionBadge: _s(j['inspectionBadge']),
      ownerPhone: _s(j['ownerPhone']),
      images: ((j['images'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map((m) => _s(m['url']) ?? '')
          .where((u) => u.isNotEmpty)
          .toList(),
      featuresSafety: feats('featuresSafety'),
      featuresComfort: feats('featuresComfort'),
      featuresTech: feats('featuresTech'),
      featuresExterior: feats('featuresExterior'),
      inspection: ((j['inspection'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(UsedCarInspCategory.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [guid];
}
