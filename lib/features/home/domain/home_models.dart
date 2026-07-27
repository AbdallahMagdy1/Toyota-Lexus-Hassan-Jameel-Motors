import 'package:equatable/equatable.dart';

/// Wire models for GET /api/app/home — one aggregate payload, camelCase,
/// mirroring the website DTOs (SliderVehicleDto, OnlineVehicleDto, OfferDto,
/// EpartItemDto, UsedCarListItemDto).

String? _s(dynamic v) => v?.toString();
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

final class HomeOffer extends Equatable {
  const HomeOffer({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.excerptAr,
    this.excerptEn,
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

  int? get daysLeft {
    if (endDate == null) return totalDays;
    final left = endDate!.difference(DateTime.now()).inDays;
    return left < 0 ? 0 : left;
  }

  factory HomeOffer.fromJson(Map<String, dynamic> j) => HomeOffer(
        id: _i(j['id']) ?? 0,
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        excerptAr: _s(j['excerptAr']),
        excerptEn: _s(j['excerptEn']),
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

final class SliderVehicle extends Equatable {
  const SliderVehicle({
    this.slug,
    this.year,
    this.brandEn = '',
    this.groupEn = '',
    this.groupAr = '',
    this.minPrice,
    this.imageEn,
    this.imageAr,
    this.hp,
    this.cylinders,
    this.seatsNumber,
    this.petrol,
    this.descriptionEn,
    this.descriptionAr,
    this.groupDescEn,
    this.groupDescAr,
    this.category,
    this.type,
    this.brandId,
    this.carGroupId,
    this.sn,
    this.showPrice = true,
    this.hybrid = false,
    this.newCar = false,
    this.buyOnline = false,
  });

  final String? slug;
  final String? year;
  final String brandEn;
  final String groupEn;
  final String groupAr;
  final double? minPrice;
  final String? imageEn;
  final String? imageAr;
  final double? hp;
  final int? cylinders;
  final int? seatsNumber;
  final String? petrol;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? groupDescEn; // marketing copy — detail lookup only
  final String? groupDescAr;
  final String? category; // SEDAN / COUPES / SUV / MVP / COMMERCIAL
  final String? type; // ProductTypeID — feeds protection-by-model
  final String? brandId;
  final String? carGroupId;
  final String? sn; // stock VIN — present on the online-detail lookup only
  final bool showPrice;
  final bool hybrid;
  final bool newCar;
  final bool buyOnline;

  String name(String lang) => lang == 'ar' && groupAr.isNotEmpty ? groupAr : groupEn;
  String? image(String lang) => (lang == 'ar' ? imageAr : imageEn) ?? imageEn ?? imageAr;

  /// Marketing description (the website vehicle page's intro paragraph).
  String description(String lang) =>
      ((lang == 'ar' ? groupDescAr : groupDescEn) ??
              groupDescEn ??
              (lang == 'ar' ? descriptionAr : descriptionEn) ??
              descriptionEn ??
              '')
          .trim();

  factory SliderVehicle.fromJson(Map<String, dynamic> j) => SliderVehicle(
        slug: _s(j['slug']),
        year: _s(j['year']),
        brandEn: _s(j['brandEn']) ?? '',
        groupEn: _s(j['groupEn']) ?? '',
        groupAr: _s(j['groupAr']) ?? '',
        minPrice: _d(j['minPrice']),
        imageEn: _s(j['imageEn']),
        imageAr: _s(j['imageAr']),
        hp: _d(j['hp']),
        cylinders: _i(j['cylinders']),
        seatsNumber: _i(j['seatsNumber']),
        petrol: _s(j['petrol']),
        descriptionEn: _s(j['descriptionEn']),
        descriptionAr: _s(j['descriptionAr']),
        groupDescEn: _s(j['groupDescEn']),
        groupDescAr: _s(j['groupDescAr']),
        category: _s(j['category']),
        type: _s(j['type']),
        brandId: _s(j['brandId']),
        carGroupId: _s(j['carGroupId']),
        sn: _s(j['sn']),
        showPrice: j['showPric'] == true,
        hybrid: j['hybird'] == true,
        newCar: j['newCar'] == true,
        buyOnline: j['buyOnline'] == true,
      );

  @override
  List<Object?> get props => [slug, groupEn, year];
}

/// Exterior color swatch on an online car (OnlineColorSwatchDto).
final class CarColor extends Equatable {
  const CarColor({this.colorId, this.nameEn, this.nameAr, this.image});

  final String? colorId; // "085/40" = exterior/interior
  final String? nameEn; // "SONIC QUARTZ /HAZEL FILM"
  final String? nameAr;
  final String? image;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  /// Exterior code — the website dedupes swatches by this.
  String get exteriorCode => (colorId ?? '').split('/').first;

  factory CarColor.fromJson(Map<String, dynamic> j) => CarColor(
      colorId: _s(j['colorId']),
      nameEn: _s(j['nameEn']),
      nameAr: _s(j['nameAr']),
      image: _s(j['image']));

  @override
  List<Object?> get props => [colorId];
}

final class OnlineVehicle extends Equatable {
  const OnlineVehicle({
    this.slug,
    this.year,
    this.brandEn,
    this.brandAr,
    this.groupEn,
    this.groupAr,
    this.shortDescriptionEn,
    this.shortDescriptionAr,
    this.minPrice,
    this.miniDownPayment,
    this.image,
    this.showPrice = true,
    this.productId,
    this.brandId,
    this.carGroupId,
    this.type,
    this.carCategoryId,
    this.hybrid = false,
    this.colors = const [],
  });

  final String? slug;
  final String? year;
  final String? brandEn;
  final String? brandAr;
  final String? groupEn;
  final String? groupAr;
  final String? shortDescriptionEn;
  final String? shortDescriptionAr;
  final double? minPrice;
  final double? miniDownPayment;
  final String? image;
  final bool showPrice;
  final String? productId;
  final String? brandId;
  final String? carGroupId;
  final String? type; // productTypeID
  final String? carCategoryId;
  final bool hybrid;
  final List<CarColor> colors;

  String name(String lang) =>
      (lang == 'ar' ? groupAr : groupEn) ?? groupEn ?? groupAr ?? '';
  String subtitle(String lang) =>
      (lang == 'ar' ? shortDescriptionAr : shortDescriptionEn) ??
      shortDescriptionEn ??
      shortDescriptionAr ??
      '';

  /// Swatches deduped by exterior code, like the website's ColorPicker.
  List<CarColor> get uniqueColors {
    final seen = <String>{};
    final out = <CarColor>[];
    for (final c in colors) {
      if (c.exteriorCode.isNotEmpty && seen.add(c.exteriorCode)) out.add(c);
    }
    return out;
  }

  factory OnlineVehicle.fromJson(Map<String, dynamic> j) => OnlineVehicle(
        slug: _s(j['slug']),
        year: _s(j['year']),
        brandEn: _s(j['brandEn']),
        brandAr: _s(j['brandAr']),
        groupEn: _s(j['groupEn']),
        groupAr: _s(j['groupAr']),
        shortDescriptionEn: _s(j['shortDescriptionEn']),
        shortDescriptionAr: _s(j['shortDescriptionAr']),
        minPrice: _d(j['minPrice']),
        miniDownPayment: _d(j['miniDownPayment']),
        image: _s(j['image']),
        showPrice: j['showPric'] == true,
        productId: _s(j['productId']),
        brandId: _s(j['brandId']),
        carGroupId: _s(j['carGroupId']),
        type: _s(j['type']),
        carCategoryId: _s(j['carCategoryId']),
        hybrid: j['hybird'] == true,
        colors: (j['colors'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CarColor.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [slug];
}

final class PartCategory extends Equatable {
  const PartCategory({this.id, this.parentId, this.nameAr, this.nameEn});

  final String? id;
  final String? parentId; // set on sub-categories (links to the main category)
  final String? nameAr;
  final String? nameEn;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory PartCategory.fromJson(Map<String, dynamic> j) => PartCategory(
      id: _s(j['id']),
      parentId: _s(j['parentId']),
      nameAr: _s(j['nameAr']),
      nameEn: _s(j['nameEn']));

  @override
  List<Object?> get props => [id, parentId];
}

/// Maintenance group (Camry, LS…) — one row per (group, year), same as the
/// website's protection car picker.
final class ProtectionGroup extends Equatable {
  const ProtectionGroup({this.id, this.brandId, this.year, this.nameAr, this.nameEn});

  final String? id;
  final String? brandId;
  final String? year;
  final String? nameAr;
  final String? nameEn;

  // Label = name only (no year) — the website's protection picker de-dupes
  // groups by name and never shows the year in the group dropdown.
  String label(String lang) =>
      ((lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '').trim();

  factory ProtectionGroup.fromJson(Map<String, dynamic> j) => ProtectionGroup(
      id: _s(j['id']),
      brandId: _s(j['brandId']),
      year: _s(j['year']),
      nameAr: _s(j['nameAr']),
      nameEn: _s(j['nameEn']));

  @override
  List<Object?> get props => [id, year];
}

/// Trim/model inside a group — Id is the productTypeID that drives the
/// protection catalog lookup.
final class ProtectionModel extends Equatable {
  const ProtectionModel({this.id, this.groupId, this.year, this.nameAr, this.nameEn});

  final String? id;
  final String? groupId;
  final String? year;
  final String? nameAr;
  final String? nameEn;

  String name(String lang) =>
      ((lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '').trim();

  factory ProtectionModel.fromJson(Map<String, dynamic> j) => ProtectionModel(
      id: _s(j['id']),
      groupId: _s(j['groupId']),
      year: _s(j['year']),
      nameAr: _s(j['nameAr']),
      nameEn: _s(j['nameEn']));

  @override
  List<Object?> get props => [id, groupId, year];
}

final class SparePart extends Equatable {
  const SparePart({
    this.guid,
    this.productNo,
    this.descriptionAr,
    this.descriptionEn,
    this.salesPrice,
    this.salesPriceDiscount,
    this.image,
    this.totalQty,
  });

  final String? guid;
  final String? productNo;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? salesPrice;
  final double? salesPriceDiscount;
  final String? image;
  final double? totalQty;

  String name(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ?? descriptionEn ?? descriptionAr ?? '';

  factory SparePart.fromJson(Map<String, dynamic> j) => SparePart(
        guid: _s(j['guid']),
        productNo: _s(j['productNo']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        salesPrice: _d(j['salesPrice']),
        salesPriceDiscount: _d(j['salesPriceDiscount']),
        image: _s(j['image']),
        totalQty: _d(j['totalQty']),
      );

  @override
  List<Object?> get props => [guid];
}

final class UsedCar extends Equatable {
  const UsedCar({
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

  String get displayName =>
      [carName, modelName].whereType<String>().where((s) => s.isNotEmpty).join(' ');

  factory UsedCar.fromJson(Map<String, dynamic> j) => UsedCar(
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

final class ProtectionService extends Equatable {
  const ProtectionService({
    this.id,
    this.nameAr,
    this.nameEn,
    this.price,
    this.tier = 0,
  });

  final String? id;
  final String? nameAr;
  final String? nameEn;
  final double? price;
  final int tier; // 4=Diamond, 3=Platinum, 2=Gold, 1=Silver

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory ProtectionService.fromJson(Map<String, dynamic> j) => ProtectionService(
        id: _s(j['id']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        price: _d(j['price']),
        tier: _i(j['tier']) ?? 0,
      );

  @override
  List<Object?> get props => [id];
}

/// The full aggregate — everything the home page renders.
final class HomeFeed extends Equatable {
  const HomeFeed({
    this.vehicleOffers = const [],
    this.maintenanceOffers = const [],
    this.onlineVehicles = const [],
    this.vehicles = const [],
    this.usedCars = const [],
    this.partsCategories = const [],
    this.partsSubCategories = const [],
    this.spareParts = const [],
    this.protectionGroups = const [],
    this.protectionModels = const [],
  });

  final List<HomeOffer> vehicleOffers;
  final List<HomeOffer> maintenanceOffers;
  final List<OnlineVehicle> onlineVehicles;
  final List<SliderVehicle> vehicles;
  final List<UsedCar> usedCars;
  final List<PartCategory> partsCategories;
  final List<PartCategory> partsSubCategories;
  final List<SparePart> spareParts;
  final List<ProtectionGroup> protectionGroups;
  final List<ProtectionModel> protectionModels;

  List<PartCategory> subCategoriesOf(String? categoryId) => categoryId == null
      ? const []
      : partsSubCategories.where((s) => s.parentId == categoryId).toList();

  /// Protection group options — a 1:1 port of the website ProtectionBar's
  /// groupOptions: current lineup only (year >= 2025 when numeric), de-duped
  /// by lowercase name.
  List<ProtectionGroup> get protectionGroupOptions {
    final seen = <String>{};
    final out = <ProtectionGroup>[];
    for (final g in protectionGroups) {
      final y = int.tryParse(g.year ?? '');
      if (y != null && y < 2025) continue;
      final k = ((g.nameEn ?? g.nameAr) ?? '').toLowerCase().trim();
      if (k.isNotEmpty && seen.add(k)) out.add(g);
    }
    return out;
  }

  /// Website ProtectionBar's modelOptions: all trims of the group, keep only
  /// the newest model year, de-duped by productTypeID.
  List<ProtectionModel> modelsOf(ProtectionGroup? g) {
    if (g == null) return const [];
    final all = protectionModels.where((m) => m.groupId == g.id).toList();
    if (all.isEmpty) return const [];
    var newest = 0;
    for (final m in all) {
      final y = int.tryParse(m.year ?? '') ?? 0;
      if (y > newest) newest = y;
    }
    final seen = <String>{};
    final out = <ProtectionModel>[];
    for (final m in all) {
      if ((int.tryParse(m.year ?? '') ?? 0) != newest) continue;
      final id = m.id ?? '';
      if (id.isNotEmpty && seen.add(id)) out.add(m);
    }
    return out;
  }

  List<String> get vehicleCategories {
    final cats = <String>[];
    for (final v in vehicles) {
      final c = v.category;
      if (c != null && c.isNotEmpty && !cats.contains(c)) cats.add(c);
    }
    return cats;
  }

  factory HomeFeed.fromJson(Map<String, dynamic> j) {
    List<T> parse<T>(dynamic node, T Function(Map<String, dynamic>) f) =>
        (node as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    final offers = j['offers'] as Map<String, dynamic>? ?? {};
    return HomeFeed(
      vehicleOffers: parse(offers['vehicleAndFinance'], HomeOffer.fromJson),
      maintenanceOffers: parse(offers['maintenanceAndParts'], HomeOffer.fromJson),
      onlineVehicles: parse(j['onlineVehicles'], OnlineVehicle.fromJson),
      vehicles: parse(j['vehicles'], SliderVehicle.fromJson),
      usedCars: parse(j['usedCars'], UsedCar.fromJson),
      partsCategories: parse(j['partsCategories'], PartCategory.fromJson),
      partsSubCategories: parse(j['partsSubCategories'], PartCategory.fromJson),
      spareParts: parse(j['spareParts'], SparePart.fromJson),
      protectionGroups: parse(j['protectionGroups'], ProtectionGroup.fromJson),
      protectionModels: parse(j['protectionModels'], ProtectionModel.fromJson),
    );
  }

  @override
  List<Object?> get props =>
      [vehicleOffers, maintenanceOffers, onlineVehicles, vehicles, usedCars, spareParts];
}
