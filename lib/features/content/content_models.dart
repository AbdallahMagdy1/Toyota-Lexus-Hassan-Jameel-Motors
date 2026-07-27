import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse('$v');

/// News item — wire-identical to the website's NewsItemDto (bilingual rows).
final class NewsItem extends Equatable {
  const NewsItem({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.excerptAr,
    this.excerptEn,
    this.contentAr,
    this.contentEn,
    this.slugAr,
    this.slugEn,
    this.image,
    this.createdDate,
    this.brandId,
  });

  final int id;
  final String? titleAr;
  final String? titleEn;
  final String? excerptAr;
  final String? excerptEn;
  final String? contentAr;
  final String? contentEn;
  final String? slugAr;
  final String? slugEn;
  final String? image;
  final DateTime? createdDate;
  final int? brandId; // 1 Toyota / 2 Lexus / 3 both

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String excerpt(String lang) =>
      (lang == 'ar' ? excerptAr : excerptEn) ?? excerptEn ?? excerptAr ?? '';
  String content(String lang) =>
      (lang == 'ar' ? contentAr : contentEn) ?? contentEn ?? contentAr ?? '';
  String? get slug => slugEn ?? slugAr;

  bool visibleForBrand(String wantedDbId) =>
      brandId == null || brandId == 3 || '$brandId' == wantedDbId;

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        id: _i(j['id']) ?? 0,
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        excerptAr: _s(j['excerptAr']),
        excerptEn: _s(j['excerptEn']),
        contentAr: _s(j['contentAr']),
        contentEn: _s(j['contentEn']),
        slugAr: _s(j['slugAr']),
        slugEn: _s(j['slugEn']),
        image: _s(j['image']),
        createdDate: _dt(j['createdDate']),
        brandId: _i(j['brandId']),
      );

  @override
  List<Object?> get props => [id];
}

/// Contact branch — coordinates come from InvSites (never hardcoded).
final class ContactBranch extends Equatable {
  const ContactBranch({this.branchId, this.nameAr, this.nameEn, this.latitude, this.longitude});

  final String? branchId;
  final String? nameAr;
  final String? nameEn;
  final String? latitude;
  final String? longitude;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  /// Google-maps link (website embeds the same q= URL). Falls back to the
  /// Eastern-Province center the website uses when a site has no lat/lng.
  Uri mapsUri() {
    final lat = (latitude ?? '').trim();
    final lng = (longitude ?? '').trim();
    final q = lat.isNotEmpty && lng.isNotEmpty ? '$lat,$lng' : '26.35,50.05';
    return Uri.parse('https://maps.google.com/maps?q=$q');
  }

  factory ContactBranch.fromJson(Map<String, dynamic> j) => ContactBranch(
        branchId: _s(j['branchId']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        latitude: _s(j['latitude']),
        longitude: _s(j['longitude']),
      );

  @override
  List<Object?> get props => [branchId];
}

final class ContactInfoRow extends Equatable {
  const ContactInfoRow({
    this.branchId,
    this.contactTitleAr,
    this.contactTitleEn,
    this.contactValueAr,
    this.contactValueEn,
    this.order,
  });

  final String? branchId;
  final String? contactTitleAr;
  final String? contactTitleEn;
  final String? contactValueAr;
  final String? contactValueEn;
  final int? order;

  String title(String lang) =>
      (lang == 'ar' ? contactTitleAr : contactTitleEn) ??
      contactTitleEn ??
      contactTitleAr ??
      '';
  String value(String lang) =>
      (lang == 'ar' ? contactValueAr : contactValueEn) ??
      contactValueEn ??
      contactValueAr ??
      '';

  factory ContactInfoRow.fromJson(Map<String, dynamic> j) => ContactInfoRow(
        branchId: _s(j['branchId']),
        contactTitleAr: _s(j['contactTitleAr']),
        contactTitleEn: _s(j['contactTitleEn']),
        contactValueAr: _s(j['contactValueAr']),
        contactValueEn: _s(j['contactValueEn']),
        order: _i(j['order']),
      );

  @override
  List<Object?> get props => [branchId, contactTitleEn, contactValueEn];
}

final class ContactSubject extends Equatable {
  const ContactSubject({required this.id, this.descriptionAr, this.descriptionEn});

  final int id;
  final String? descriptionAr;
  final String? descriptionEn;

  String name(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory ContactSubject.fromJson(Map<String, dynamic> j) => ContactSubject(
        id: _i(j['id']) ?? 0,
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
      );

  @override
  List<Object?> get props => [id];
}

final class ContactPage extends Equatable {
  const ContactPage({
    this.branches = const [],
    this.info = const [],
    this.subjects = const [],
  });

  final List<ContactBranch> branches;
  final List<ContactInfoRow> info;
  final List<ContactSubject> subjects;

  List<ContactInfoRow> infoFor(String? branchId) => (info
      .where((r) =>
          (r.branchId ?? '').isEmpty || r.branchId == branchId)
      .toList()
    ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0)));

  factory ContactPage.fromJson(Map<String, dynamic> j) {
    List<T> parse<T>(dynamic node, T Function(Map<String, dynamic>) f) =>
        (node as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    return ContactPage(
      branches: parse(j['branches'], ContactBranch.fromJson),
      info: parse(j['info'], ContactInfoRow.fromJson),
      subjects: parse(j['subjects'], ContactSubject.fromJson),
    );
  }

  @override
  List<Object?> get props => [branches, info, subjects];
}
