import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

/// Trim row (VehicleTrimDto) — powers Specs + Comparison.
final class VehicleTrim extends Equatable {
  const VehicleTrim({
    this.slug,
    this.trimName,
    this.descriptionEn,
    this.descriptionAr,
    this.minPrice,
    this.hp,
    this.cylinders,
    this.seatsNumber,
    this.petrol,
    this.hybrid = false,
  });

  final String? slug;
  final String? trimName;
  final String? descriptionEn;
  final String? descriptionAr;
  final double? minPrice;
  final double? hp;
  final int? cylinders;
  final int? seatsNumber;
  final String? petrol;
  final bool hybrid;

  String name(String lang) =>
      (trimName?.trim().isNotEmpty == true
          ? trimName!
          : (lang == 'ar' ? descriptionAr : descriptionEn) ?? descriptionEn ?? '')
          .trim();

  factory VehicleTrim.fromJson(Map<String, dynamic> j) => VehicleTrim(
        slug: _s(j['slug']),
        trimName: _s(j['trimName']),
        descriptionEn: _s(j['descriptionEn']),
        descriptionAr: _s(j['descriptionAr']),
        minPrice: _d(j['minPrice']),
        hp: _d(j['hp']),
        cylinders: _i(j['cylinders']),
        seatsNumber: _i(j['seatsNumber']),
        petrol: _s(j['petrol']),
        hybrid: j['hybird'] == true,
      );

  @override
  List<Object?> get props => [slug, trimName];
}

/// Exterior/interior color (VehicleColorDto).
final class VehicleColor extends Equatable {
  const VehicleColor({
    required this.colorId,
    this.nameEn,
    this.nameAr,
    this.exteriorImage,
    this.exteriorCode,
  });

  final String colorId;
  final String? nameEn;
  final String? nameAr;
  final String? exteriorImage; // swatch dot
  final String? exteriorCode;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory VehicleColor.fromJson(Map<String, dynamic> j) => VehicleColor(
        colorId: _s(j['colorId']) ?? '',
        nameEn: _s(j['nameEn']),
        nameAr: _s(j['nameAr']),
        exteriorImage: _s(j['exteriorImage']),
        exteriorCode: _s(j['exteriorCode']),
      );

  @override
  List<Object?> get props => [colorId];
}

/// Car image per color code (VehicleColorImageDto).
final class VehicleColorImage extends Equatable {
  const VehicleColorImage({this.imageUrl, this.colorCode, this.fieldName});

  final String? imageUrl;
  final String? colorCode;
  final String? fieldName;

  factory VehicleColorImage.fromJson(Map<String, dynamic> j) => VehicleColorImage(
        imageUrl: _s(j['imageUrl']),
        colorCode: _s(j['colorCode']),
        fieldName: _s(j['fieldName']),
      );

  @override
  List<Object?> get props => [imageUrl, colorCode];
}

final class VehicleFeature extends Equatable {
  const VehicleFeature({this.titleEn, this.titleAr, this.descriptionEn, this.descriptionAr, this.image});

  final String? titleEn;
  final String? titleAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? image;

  String title(String lang) => (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ?? descriptionEn ?? descriptionAr ?? '';

  factory VehicleFeature.fromJson(Map<String, dynamic> j) => VehicleFeature(
        titleEn: _s(j['titleEn']),
        titleAr: _s(j['titleAr']),
        descriptionEn: _s(j['descriptionEn']),
        descriptionAr: _s(j['descriptionAr']),
        image: _s(j['image']),
      );

  @override
  List<Object?> get props => [titleEn, image];
}

final class VehicleGalleryItem extends Equatable {
  const VehicleGalleryItem({this.image, this.type});

  final String? image;
  final String? type;

  factory VehicleGalleryItem.fromJson(Map<String, dynamic> j) =>
      VehicleGalleryItem(image: _s(j['image']), type: _s(j['type']));

  @override
  List<Object?> get props => [image];
}

/// One equipment row (trim × section × description) — powers Comparison.
final class EquipmentRow extends Equatable {
  const EquipmentRow({
    this.trimSlug,
    this.trimName,
    this.sectionEn,
    this.sectionAr,
    this.descriptionEn,
    this.descriptionAr,
    this.noteEn,
    this.noteAr,
  });

  final String? trimSlug;
  final String? trimName;
  final String? sectionEn;
  final String? sectionAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? noteEn;
  final String? noteAr;

  String section(String lang) =>
      (lang == 'ar' ? sectionAr : sectionEn) ?? sectionEn ?? sectionAr ?? '';
  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ?? descriptionEn ?? descriptionAr ?? '';
  String note(String lang) =>
      (lang == 'ar' ? noteAr : noteEn) ?? noteEn ?? noteAr ?? '';

  factory EquipmentRow.fromJson(Map<String, dynamic> j) => EquipmentRow(
        trimSlug: _s(j['trimSlug']),
        trimName: _s(j['trimName']),
        sectionEn: _s(j['sectionEn']),
        sectionAr: _s(j['sectionAr']),
        descriptionEn: _s(j['descriptionEn']),
        descriptionAr: _s(j['descriptionAr']),
        noteEn: _s(j['noteEn']),
        noteAr: _s(j['noteAr']),
      );

  @override
  List<Object?> get props => [trimSlug, sectionEn, descriptionEn];
}
