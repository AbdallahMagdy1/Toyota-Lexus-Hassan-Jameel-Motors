import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/maintenance_hub_models.dart';

/// Maintenance hub data — the website's /maintenance page cycle:
/// GET periodic (tab details + footnotes) and GET testimonials.
/// Both are SWR-cached catalog GETs, so revisits paint instantly.
final class MaintenanceHubRepository {
  MaintenanceHubRepository(this._api);

  final ApiClient _api;

  Future<PeriodicData?> periodic() async {
    try {
      final res =
          await _api.get<Map<String, dynamic>>(ApiPaths.maintPeriodic);
      if (res.statusCode == 200 && res.data != null) {
        return PeriodicData.fromJson(res.data!);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<List<Testimonial>> testimonials() async {
    try {
      final res = await _api.get<List<dynamic>>(ApiPaths.maintTestimonials);
      if (res.statusCode == 200 && res.data != null) {
        return [
          for (final t in res.data!)
            Testimonial.fromJson(t as Map<String, dynamic>)
        ];
      }
      return const [];
    } on DioException {
      return const [];
    }
  }
}
