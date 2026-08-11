import 'package:equatable/equatable.dart';

String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

int? _i(dynamic v) => v == null ? null : int.tryParse(v.toString());

/// The FULL user record — GET /api/user/{guid} (website UserDto shape).
/// [raw] keeps the wire JSON so the session store can be refreshed without
/// losing fields the lean session model doesn't carry.
final class ProfileUser extends Equatable {
  const ProfileUser({
    required this.guid,
    required this.userId,
    this.genderId,
    this.firstNameAr,
    this.middleNameAr,
    this.lastNameAr,
    this.firstNameEn,
    this.middleNameEn,
    this.lastNameEn,
    this.email,
    this.phone,
    this.identity,
    this.tradeNo,
    this.address,
    this.countryId,
    this.cityId,
    this.custGroupId,
    this.custId,
    this.raw = const {},
  });

  final String guid;
  final int userId;
  final int? genderId;
  final String? firstNameAr;
  final String? middleNameAr;
  final String? lastNameAr;
  final String? firstNameEn;
  final String? middleNameEn;
  final String? lastNameEn;
  final String? email;
  final String? phone;
  final String? identity;
  final String? tradeNo; // CR
  final String? address;
  final String? countryId;
  final String? cityId;
  final String? custGroupId;
  final String? custId;
  final Map<String, dynamic> raw;

  String displayName(String lang) {
    final first =
        (lang == 'ar' ? firstNameAr : firstNameEn) ?? firstNameEn ?? firstNameAr;
    final last =
        (lang == 'ar' ? lastNameAr : lastNameEn) ?? lastNameEn ?? lastNameAr;
    return [first, last].whereType<String>().join(' ').trim();
  }

  factory ProfileUser.fromJson(Map<String, dynamic> j) => ProfileUser(
        guid: _s(j['guid']) ?? '',
        userId: _i(j['userId']) ?? 0,
        genderId: _i(j['genderId']),
        firstNameAr: _s(j['firstNameAr']),
        middleNameAr: _s(j['middleNameAr']),
        lastNameAr: _s(j['lastNameAr']),
        firstNameEn: _s(j['firstNameEn']),
        middleNameEn: _s(j['middleNameEn']),
        lastNameEn: _s(j['lastNameEn']),
        email: _s(j['email']),
        phone: _s(j['phone']),
        identity: _s(j['identity']),
        tradeNo: _s(j['tradeNo']),
        address: _s(j['address']),
        countryId: _s(j['countryId']),
        cityId: _s(j['cityId']),
        custGroupId: _s(j['custGroupId']),
        custId: _s(j['custId']),
        raw: j,
      );

  @override
  List<Object?> get props => [
        guid,
        userId,
        genderId,
        firstNameAr,
        middleNameAr,
        lastNameAr,
        firstNameEn,
        middleNameEn,
        lastNameEn,
        email,
        phone,
        identity,
        tradeNo,
        address,
        countryId,
        cityId,
        custGroupId,
      ];
}

/// One dropdown option — countries / cities / genders
/// (Site_User_GetSettings result sets).
final class LookupItem extends Equatable {
  const LookupItem({this.id, this.countryId, this.nameAr, this.nameEn});

  final String? id;
  final String? countryId; // set on cities: the parent country
  final String? nameAr;
  final String? nameEn;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory LookupItem.fromJson(Map<String, dynamic> j) => LookupItem(
        id: _s(j['id']),
        countryId: _s(j['countryId']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
      );

  @override
  List<Object?> get props => [id, countryId];
}

/// The 3 lookup sets used by the "my data" form.
final class ProfileSettings extends Equatable {
  const ProfileSettings({
    this.countries = const [],
    this.cities = const [],
    this.genders = const [],
  });

  final List<LookupItem> countries;
  final List<LookupItem> cities;
  final List<LookupItem> genders;

  List<LookupItem> citiesOf(String? countryId) => countryId == null
      ? const []
      : cities.where((c) => c.countryId == countryId).toList();

  factory ProfileSettings.fromJson(Map<String, dynamic> j) {
    List<LookupItem> list(String key) => ((j[key] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LookupItem.fromJson)
        .toList();
    return ProfileSettings(
      countries: list('countries'),
      cities: list('cities'),
      genders: list('genders'),
    );
  }

  @override
  List<Object?> get props => [countries, cities, genders];
}

/// صفة الحساب — individual / company … (needIdentity decides the field).
final class AccountType extends Equatable {
  const AccountType({
    this.id,
    this.descriptionAr,
    this.descriptionEn,
    this.needIdentity = false,
  });

  final String? id;
  final String? descriptionAr;
  final String? descriptionEn;
  final bool needIdentity;

  String name(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory AccountType.fromJson(Map<String, dynamic> j) => AccountType(
        id: _s(j['id']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        needIdentity: j['needIdentity'] == true,
      );

  @override
  List<Object?> get props => [id];
}

/// One row of the server notification history (Web_Notify).
final class ServerNotification extends Equatable {
  const ServerNotification({
    this.notifyId,
    this.titleAr,
    this.titleEn,
    this.contentAr,
    this.contentEn,
    this.descriptionAr,
    this.descriptionEn,
    this.alertType,
    this.createdDate,
  });

  final int? notifyId;
  final String? titleAr;
  final String? titleEn;
  final String? contentAr;
  final String? contentEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? alertType;
  final DateTime? createdDate;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';

  String body(String lang) =>
      (lang == 'ar' ? contentAr : contentEn) ??
      contentEn ??
      contentAr ??
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory ServerNotification.fromJson(Map<String, dynamic> j) =>
      ServerNotification(
        notifyId: _i(j['notifyId']),
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        contentAr: _s(j['contentAr']),
        contentEn: _s(j['contentEn']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        alertType: _s(j['alertType']),
        createdDate: DateTime.tryParse(j['createdDate']?.toString() ?? ''),
      );

  @override
  List<Object?> get props => [notifyId, createdDate];
}
