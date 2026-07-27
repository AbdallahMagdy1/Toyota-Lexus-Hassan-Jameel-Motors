import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/onboarding_slide.dart';

final class OnboardingRepository {
  OnboardingRepository(this._api);

  final ApiClient _api;

  /// Dashboard-managed slides for a brand + placement ('onboarding' slides
  /// or the pre-sign-in 'welcome' banner); falls back to the bundled set
  /// when the API is unreachable or returns nothing.
  Future<List<OnboardingSlide>> fetch(
    String brandKey, {
    String placement = 'onboarding',
  }) async {
    final fallback = switch (placement) {
      'welcome' => kWelcomeFallback,
      'auth' => kAuthFallback,
      _ => kDefaultSlides,
    };
    try {
      final res = await _api.get<List<dynamic>>(
        ApiPaths.onboarding,
        query: {'brand': brandKey, 'placement': placement},
      );
      final data = res.data;
      if (res.statusCode != 200 || data == null || data.isEmpty) {
        return fallback;
      }
      final slides = data
          .whereType<Map<String, dynamic>>()
          .map(OnboardingSlide.fromJson)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return slides.isEmpty ? fallback : slides;
    } catch (_) {
      return fallback;
    }
  }
}
