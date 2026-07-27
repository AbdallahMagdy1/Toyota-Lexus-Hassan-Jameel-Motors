import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

/// Site group row from /maintenance/settings (MaintenanceGroupDto).
final class MaintGroup extends Equatable {
  const MaintGroup({this.id, this.brandId, this.year, this.nameAr, this.nameEn});

  final String? id;
  final String? brandId;
  final String? year;
  final String? nameAr;
  final String? nameEn;

  String name(String lang) =>
      ((lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '').trim();

  factory MaintGroup.fromJson(Map<String, dynamic> j) => MaintGroup(
        id: _s(j['id']),
        brandId: _s(j['brandId']),
        year: _s(j['year']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
      );

  @override
  List<Object?> get props => [id, year];
}

/// Trim/model row (MaintenanceProductModelDto) — id is the productTypeID the
/// protection catalog resolves on; carCategory is the join key the website
/// prefers when deduping.
final class MaintModel extends Equatable {
  const MaintModel({
    this.id,
    this.groupId,
    this.year,
    this.modelCode,
    this.nameAr,
    this.nameEn,
    this.vehicleType,
    this.carCategory,
  });

  final String? id;
  final String? groupId;
  final String? year;
  final String? modelCode;
  final String? nameAr;
  final String? nameEn;
  final String? vehicleType;
  final String? carCategory;

  String name(String lang) =>
      ((lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '').trim();

  factory MaintModel.fromJson(Map<String, dynamic> j) => MaintModel(
        id: _s(j['id']),
        groupId: _s(j['groupId']),
        year: _s(j['year']),
        modelCode: _s(j['modelCode']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        vehicleType: _s(j['vehicleType']),
        carCategory: _s(j['carCategory']),
      );

  @override
  List<Object?> get props => [id, groupId, year];
}

/// A protection/polishing package (ProtectionServiceDto). Tier: 4=Diamond,
/// 3=Platinum, 2=Gold, 1=Silver, 0=plain service row.
final class ProtectionPackage extends Equatable {
  const ProtectionPackage({
    this.id,
    this.guid,
    this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.price,
    this.tier = 0,
  });

  final String? id;
  final String? guid;
  final String? nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? price;
  final int tier;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';
  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory ProtectionPackage.fromJson(Map<String, dynamic> j) =>
      ProtectionPackage(
        id: _s(j['id']),
        guid: _s(j['guid']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        price: _d(j['price']),
        tier: _i(j['tier']) ?? 0,
      );

  @override
  List<Object?> get props => [id, guid];
}

/// GET /maintenance/protection-by-model result.
final class ProtectionResult extends Equatable {
  const ProtectionResult({this.resolvedBucket, this.services = const []});

  final String? resolvedBucket;
  final List<ProtectionPackage> services;

  factory ProtectionResult.fromJson(Map<String, dynamic> j) =>
      ProtectionResult(
        resolvedBucket: _s(j['resolvedBucket']),
        services: (j['services'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ProtectionPackage.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [resolvedBucket, services];
}

final class MaintBranch extends Equatable {
  const MaintBranch({this.id, this.nameAr, this.nameEn, this.cityAr, this.cityEn});

  final String? id;
  final String? nameAr;
  final String? nameEn;
  final String? cityAr;
  final String? cityEn;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory MaintBranch.fromJson(Map<String, dynamic> j) => MaintBranch(
        id: _s(j['id']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        cityAr: _s(j['cityAr']),
        cityEn: _s(j['cityEn']),
      );

  @override
  List<Object?> get props => [id];
}
