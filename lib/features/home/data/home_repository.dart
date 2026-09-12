import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/home_models.dart';

final class HomeRepository {
  HomeRepository(this._api);

  final ApiClient _api;

  /// One request paints the whole home page (server-side warmed aggregate).
  Future<HomeFeed?> fetch(String brandKey) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiPaths.home,
        query: {'brand': brandKey},
      );
      final data = res.data;
      if (res.statusCode != 200 || data == null) return null;
      // Defensive brand pass on the buy-online rail for servers deployed
      // before the backend filter existed: Lexus shows only Lexus rows,
      // Toyota (the house brand) everything that isn't Lexus.
      final online = data['onlineVehicles'];
      if (online is List) {
        bool isLexus(Map m) =>
            (m['brandEn']?.toString().toLowerCase() ?? '').contains('lexus') ||
            (m['brandAr']?.toString() ?? '').contains('لكزس');
        data['onlineVehicles'] = online
            .whereType<Map<String, dynamic>>()
            .where((m) => brandKey == 'lexus' ? isLexus(m) : !isLexus(m))
            .toList();
      }
      return HomeFeed.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Protection & shading packages for a selected model (ProductTypeID).
  Future<List<ProtectionService>> protectionByModel(
      String productTypeId, String? brandId) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiPaths.protectionByModel,
        query: {'productTypeId': productTypeId, 'brandId': ?brandId},
      );
      final services = res.data?['services'] as List<dynamic>? ?? [];
      return services
          .whereType<Map<String, dynamic>>()
          .map(ProtectionService.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Spare parts for a main category tab (+ optional sub-category).
  Future<List<SparePart>> partsByCategory(String? categoryId, {String? subCategoryId}) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.partsSearch,
        body: {
          'isStock': true,
          'pageSize': 10,
          'cat': ?categoryId,
          'subCat': ?subCategoryId,
        },
      );
      final items = res.data?['items'] as List<dynamic>? ?? [];
      return items.whereType<Map<String, dynamic>>().map(SparePart.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }
}
