import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';

/// Cross-brand app-store download links (dashboard "App Settings" screen →
/// GET /api/app/store-links). The Toyota app opens the Lexus URLs and the
/// Lexus app opens the Toyota URLs; the app picks Android vs iOS by the device.
class StoreLinks {
  const StoreLinks({
    this.toyotaAndroid,
    this.toyotaIos,
    this.lexusAndroid,
    this.lexusIos,
  });

  final String? toyotaAndroid;
  final String? toyotaIos;
  final String? lexusAndroid;
  final String? lexusIos;

  static String? _s(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory StoreLinks.fromJson(Map<String, dynamic> j) => StoreLinks(
        toyotaAndroid: _s(j['toyotaAndroidUrl']),
        toyotaIos: _s(j['toyotaIosUrl']),
        lexusAndroid: _s(j['lexusAndroidUrl']),
        lexusIos: _s(j['lexusIosUrl']),
      );

  /// The store URL for a brand on the given platform, or null if not configured
  /// (blank fields are omitted by the API, so null = "hide the button").
  String? urlFor(String brandKey, {required bool isIos}) {
    if (brandKey == 'lexus') return isIos ? lexusIos : lexusAndroid;
    return isIos ? toyotaIos : toyotaAndroid; // toyota / default
  }
}

/// Fetches the cross-brand store links. Returns null when offline / unreachable
/// / not configured — the side menu simply hides the cross-promo row.
final class StoreLinksRepository {
  StoreLinksRepository(this._api);

  final ApiClient _api;

  Future<StoreLinks?> fetch() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.storeLinks);
      final data = res.data;
      if (res.statusCode != 200 || data == null) return null;
      return StoreLinks.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
