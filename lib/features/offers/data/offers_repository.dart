import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/offer_models.dart';

/// Offers cycle — same endpoints/DTOs as the website's /offers page.
final class OffersRepository {
  OffersRepository(this._api);

  final ApiClient _api;

  /// GET /api/app/offers → { offers[], types[] } (the whole page in one call,
  /// grouped client-side by typeId exactly like the website).
  Future<(List<SiteOffer>, List<OfferType>)> all() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.offers);
      final j = res.data ?? const {};
      List<T> parse<T>(dynamic node, T Function(Map<String, dynamic>) f) =>
          (node as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(f)
              .toList();
      return (
        parse(j['offers'], SiteOffer.fromJson),
        parse(j['types'], OfferType.fromJson),
      );
    } on DioException {
      return (const <SiteOffer>[], const <OfferType>[]);
    }
  }

  Future<OfferDetail?> detail(String slug) async {
    try {
      final res = await _api
          .get<Map<String, dynamic>>('${ApiPaths.offers}/${Uri.encodeComponent(slug)}');
      return res.statusCode == 200 && res.data != null
          ? OfferDetail.fromJson(res.data!)
          : null;
    } on DioException {
      return null;
    }
  }

  /// (offerId → brand/group/type) pairs — badge offers matching my car.
  Future<List<Map<String, dynamic>>> supportedMap() async {
    try {
      final res =
          await _api.get<List<dynamic>>('${ApiPaths.offers}/supported-map');
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  /// POST /api/app/offers/reserve — website payload + preferred slot +
  /// my-vehicle line (App_Offers_Reserve sends the full staff email).
  Future<bool> reserve(Map<String, dynamic> body) async {
    try {
      final res =
          await _api.post<Map<String, dynamic>>(ApiPaths.offersReserve, body: body);
      return res.data?['ok'] == true;
    } on DioException {
      return false;
    }
  }
}
