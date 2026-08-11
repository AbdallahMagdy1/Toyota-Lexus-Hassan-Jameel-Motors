import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

/// A vehicle line a coupon supports (brand/group + year window + thumb) —
/// wire-identical to the website's CouponBanner.vehicles rows.
final class CouponVehicle extends Equatable {
  const CouponVehicle({
    this.brandAr,
    this.brandEn,
    this.groupAr,
    this.groupEn,
    this.fromYear,
    this.toYear,
    this.image,
  });

  final String? brandAr;
  final String? brandEn;
  final String? groupAr;
  final String? groupEn;
  final int? fromYear;
  final int? toYear;
  final String? image;

  String brand(String lang) =>
      (lang == 'ar' ? brandAr : brandEn) ?? brandEn ?? brandAr ?? '';
  String group(String lang) =>
      (lang == 'ar' ? groupAr : groupEn) ?? groupEn ?? groupAr ?? '';

  /// '2022–2024', collapsed to a single year when both ends match.
  String get yearRange {
    if (fromYear == null && toYear == null) return '';
    if (fromYear != null && toYear != null && toYear != fromYear) {
      return '$fromYear–$toYear';
    }
    return '${fromYear ?? toYear}';
  }

  factory CouponVehicle.fromJson(Map<String, dynamic> j) => CouponVehicle(
        brandAr: _s(j['brandAr']),
        brandEn: _s(j['brandEn']),
        groupAr: _s(j['groupAr']),
        groupEn: _s(j['groupEn']),
        fromYear: _i(j['fromYear']),
        toYear: _i(j['toYear']),
        image: _s(j['image']),
      );

  @override
  List<Object?> get props => [brandEn, groupEn, fromYear, toYear];
}

/// One home-banner coupon (GET /api/app/coupons/home-banners) — the active
/// coupons an admin flagged "show on home", bilingual in one row.
final class CouponBanner extends Equatable {
  const CouponBanner({
    required this.couponId,
    this.guid,
    this.code,
    this.couponType,
    this.discountType,
    this.discountValue,
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.detailsAr,
    this.detailsEn,
    this.bannerImageUrl,
    this.vehicles = const [],
  });

  final int couponId;
  final String? guid;
  final String? code;
  final String? couponType; // SP | MN | PR
  final String? discountType; // P | AT | AP
  final double? discountValue;
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? detailsAr;
  final String? detailsEn;
  final String? bannerImageUrl; // absolute
  final List<CouponVehicle> vehicles;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String subtitle(String lang) =>
      (lang == 'ar' ? subtitleAr : subtitleEn) ?? subtitleEn ?? subtitleAr ?? '';
  String details(String lang) =>
      (lang == 'ar' ? detailsAr : detailsEn) ?? detailsEn ?? detailsAr ?? '';

  /// The website's list filter: skip rows with no title and no code.
  bool get renderable =>
      (titleAr ?? '').isNotEmpty ||
      (titleEn ?? '').isNotEmpty ||
      (code ?? '').isNotEmpty;

  factory CouponBanner.fromJson(Map<String, dynamic> j) => CouponBanner(
        couponId: _i(j['couponId']) ?? 0,
        guid: _s(j['guid']),
        code: _s(j['code']),
        couponType: _s(j['couponType']),
        discountType: _s(j['discountType']),
        discountValue: _d(j['discountValue']),
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        subtitleAr: _s(j['subtitleAr']),
        subtitleEn: _s(j['subtitleEn']),
        detailsAr: _s(j['detailsAr']),
        detailsEn: _s(j['detailsEn']),
        bannerImageUrl: _s(j['bannerImageUrl']),
        vehicles: (j['vehicles'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CouponVehicle.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [couponId];
}

/// Server verdict for a coupon code. The discount is ALWAYS server-computed —
/// the client only displays it (capped at the payable total) and forwards the
/// code at pay time when [valid] is true.
final class CouponResult extends Equatable {
  const CouponResult({
    this.available = false,
    this.valid = false,
    this.couponId,
    this.code,
    this.discountType,
    this.discountAmount = 0,
    this.discountRate = 0,
    this.eligibleSubtotal = 0,
    this.reason,
    this.message,
  });

  /// Quiet fallback for network failures / null bodies — never blocks payment.
  static const CouponResult invalid = CouponResult();

  final bool available;
  final bool valid;
  final int? couponId;
  final String? code;
  final String? discountType; // P | AT | AP
  final double discountAmount;
  final double discountRate;
  final double eligibleSubtotal;
  final String? reason;
  final String? message;

  /// reason == 'unavailable' → treat as invalid quietly (no red error).
  bool get unavailable => reason == 'unavailable';

  factory CouponResult.fromJson(Map<String, dynamic> j) => CouponResult(
        available: j['available'] == true,
        valid: j['valid'] == true,
        couponId: _i(j['couponId']),
        code: _s(j['code']),
        discountType: _s(j['discountType']),
        discountAmount: _d(j['discountAmount']) ?? 0,
        discountRate: _d(j['discountRate']) ?? 0,
        eligibleSubtotal: _d(j['eligibleSubtotal']) ?? 0,
        reason: _s(j['reason']),
        message: _s(j['message']),
      );

  @override
  List<Object?> get props =>
      [available, valid, couponId, code, discountAmount, reason];
}
