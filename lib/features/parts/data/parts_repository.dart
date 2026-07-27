import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/parts_models.dart';

/// Spare-parts cycle — same endpoints/DTOs as the website's /parts page.
final class PartsRepository {
  PartsRepository(this._api);

  final ApiClient _api;

  Future<PartsFilters> filters() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.partsFilters);
      return res.data == null
          ? const PartsFilters()
          : PartsFilters.fromJson(res.data!);
    } on DioException {
      return const PartsFilters();
    }
  }

  /// Dashboard Parts Banners (brand: 1=Toyota, 2=Lexus).
  Future<List<PartsBanner>> banners(int brand) async {
    try {
      final res = await _api
          .get<List<dynamic>>(ApiPaths.partsBanners, query: {'brand': brand});
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PartsBanner.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// Dashboard-managed parts-page hero (App Onboarding placement
  /// 'parts_hero', brand-aware).
  Future<PartsHero?> hero(String brandKey) async {
    try {
      final res = await _api.get<List<dynamic>>(ApiPaths.onboarding,
          query: {'placement': 'parts_hero', 'brand': brandKey});
      final row =
          (res.data ?? []).whereType<Map<String, dynamic>>().firstOrNull;
      return row == null ? null : PartsHero.fromJson(row);
    } on DioException {
      return null;
    }
  }

  /// POST search — website payload (EpartSearchPayload). A null [sortBy]
  /// keeps the backend's relevance ranking (App_Parts_Search).
  Future<PartsSearchResult> search({
    String? freeText,
    String? cat,
    String? subCat,
    bool inStockOnly = false,
    int pageNumber = 1,
    int pageSize = 12,
    String? sortBy,
    String sortDir = 'DESC',
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.partsSearch,
        body: {
          'freeText': (freeText ?? '').trim().isEmpty ? null : freeText!.trim(),
          'cat': cat,
          'subCat': subCat,
          'isStock': inStockOnly,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          'sortBy': sortBy,
          'sortDir': sortDir,
        },
      );
      return res.data == null
          ? const PartsSearchResult()
          : PartsSearchResult.fromJson(res.data!);
    } on DioException {
      return const PartsSearchResult();
    }
  }

  /// Order-level coupon (Site coupon procs). Returns (valid, couponId,
  /// discountAmount, message) — the server computes the discount.
  Future<(bool, int?, double, String?)> validateCoupon(
      String code, List<Map<String, dynamic>> items, String lang) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/parts/coupon',
        body: {'code': code, 'items': items, 'lang': lang},
      );
      final d = res.data ?? const {};
      final valid = d['valid'] == true || d['found'] == true;
      return (
        valid,
        (d['couponId'] as num?)?.toInt(),
        ((d['discountAmount'] ?? d['amount']) as num?)?.toDouble() ?? 0,
        d['message']?.toString(),
      );
    } on DioException {
      return (false, null, 0.0, null);
    }
  }

  /// The website's exact checkout (Site_SpareParts_Payment): creates the
  /// sales order and returns the provider URL / Sadad number.
  Future<Map<String, dynamic>?> checkout(Map<String, dynamic> payload) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/parts/checkout',
        body: payload,
      );
      return res.data;
    } on DioException {
      return null;
    }
  }

  /// Confirm the order's payment after returning from the provider.
  Future<Map<String, dynamic>?> paymentStatus(
      String orderGuid, String payType) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/parts/payment-status',
        body: {'orderGuid': orderGuid, 'payType': payType},
      );
      return res.data;
    } on DioException {
      return null;
    }
  }
}
