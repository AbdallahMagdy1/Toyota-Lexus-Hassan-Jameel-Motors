import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/coupon_models.dart';

/// Coupon cycle — same endpoints/DTOs as the website's coupon components.
/// (The job-card variant lives in JobCardRepository next to its siblings.)
final class CouponsRepository {
  CouponsRepository(this._api);

  final ApiClient _api;

  /// GET /api/app/coupons/home-banners?brand= — active "show on home"
  /// coupons for the brand (1 = Toyota, 2 = Lexus).
  Future<List<CouponBanner>> homeBanners({int? brand}) async {
    try {
      final res = await _api.get<List<dynamic>>(
        ApiPaths.couponHomeBanners,
        query: {'brand': ?brand},
      );
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CouponBanner.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// POST /api/app/coupons/validate-protection — server-computed verdict for
  /// a protection/maintenance basket. Failures come back as the quiet
  /// invalid result so payment is never blocked.
  Future<CouponResult> validateProtection({
    required String code,
    required String lang,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.couponValidateProtection,
        body: {'code': code, 'lang': lang, 'items': items},
      );
      return res.data == null
          ? CouponResult.invalid
          : CouponResult.fromJson(res.data!);
    } on DioException {
      return CouponResult.invalid;
    }
  }
}
