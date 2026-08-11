import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'used_cars_models.dart';

/// Used-cars cycle — the website's exact endpoints via the mobile API
/// passthrough (/api/app/used-cars/*).
final class UsedCarsRepository {
  UsedCarsRepository(this._api);

  final ApiClient _api;

  /// Brand-scoped like the website: Toyota theme shows Toyota only.
  Future<List<UsedCarItem>> list({String? brand}) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/used-cars/list',
        query: {if ((brand ?? '').isNotEmpty) 'brand': brand},
      );
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(UsedCarItem.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  Future<UsedCarDetail?> detail(String guid) async {
    try {
      final res =
          await _api.get<Map<String, dynamic>>('/api/app/used-cars/$guid');
      return res.data == null ? null : UsedCarDetail.fromJson(res.data!);
    } on DioException {
      return null;
    }
  }

  /// "اعرض سيارتك" — the website's public submission payload verbatim.
  /// Returns (ok, error).
  Future<(bool, String?)> submit(Map<String, dynamic> payload) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/used-cars/submit',
        body: payload,
      );
      final ok = res.data?['ok'] == true;
      return (ok, res.data?['error']?.toString());
    } on DioException catch (e) {
      final data = e.response?.data;
      return (
        false,
        data is Map<String, dynamic> ? data['error']?.toString() : null,
      );
    }
  }
}
