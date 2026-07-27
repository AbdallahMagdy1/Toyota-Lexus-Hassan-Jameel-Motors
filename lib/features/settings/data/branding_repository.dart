import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_brand.dart';

/// Fetches the dashboard-managed themes (SiteThemes → GET /api/app/themes)
/// and keeps a local cache so cold starts paint the last-known palette
/// instantly — the mobile mirror of the website's BrandProvider.
final class BrandingRepository {
  BrandingRepository(this._api, this._store);

  final ApiClient _api;
  final LocalStore _store;

  /// Last-known themes (cache → fallback). Synchronous: safe for first paint.
  Map<String, AppBrand> cached() {
    final raw = _store.themesCache;
    if (raw == null) return Map.of(kFallbackBrands);
    return _merge(raw);
  }

  /// Live fetch. Returns null when offline/unreachable (caller keeps cache).
  Future<Map<String, AppBrand>?> fetch() async {
    try {
      final res = await _api.get<List<dynamic>>(ApiPaths.themes);
      final data = res.data;
      if (res.statusCode != 200 || data == null || data.isEmpty) return null;
      await _store.setThemesCache(data);
      return _merge(data);
    } catch (_) {
      return null;
    }
  }

  Map<String, AppBrand> _merge(List<dynamic> rows) {
    // Start from fallbacks so toyota/lexus always exist even if the
    // dashboard deactivates one, then overlay every API theme.
    final map = Map.of(kFallbackBrands);
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final brand = AppBrand.fromApi(row);
      if (brand.key.isEmpty) continue;
      map[brand.key] = brand;
    }
    return map;
  }
}
