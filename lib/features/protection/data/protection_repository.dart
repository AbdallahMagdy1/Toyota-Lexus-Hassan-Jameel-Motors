import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/protection_models.dart';

/// Protection & shading / maintenance-booking cycle — same endpoints as the
/// website's /maintenance page.
final class ProtectionRepository {
  ProtectionRepository(this._api);

  final ApiClient _api;

  /// /maintenance/settings — groups + product models (the two dropdowns).
  Future<(List<MaintGroup>, List<MaintModel>)> settings() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.maintSettings);
      final j = res.data ?? const {};
      List<T> parse<T>(dynamic node, T Function(Map<String, dynamic>) f) =>
          (node as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(f)
              .toList();
      return (
        parse(j['groups'], MaintGroup.fromJson),
        parse(j['productModels'], MaintModel.fromJson),
      );
    } on DioException {
      return (const <MaintGroup>[], const <MaintModel>[]);
    }
  }

  Future<ProtectionResult?> protectionByModel(
      String productTypeId, String brandId) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiPaths.maintProtectionByModel,
        query: {'productTypeId': productTypeId, 'brandId': brandId},
      );
      return res.data == null ? null : ProtectionResult.fromJson(res.data!);
    } on DioException {
      return null;
    }
  }

  /// Main maintenance services catalog (id = GUID, bilingual).
  Future<List<Map<String, dynamic>>> mainServices() async {
    try {
      final res = await _api.get<List<dynamic>>('/api/app/maintenance/services');
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  /// First-level sub-services of a main service (Mntc_SubService1).
  Future<List<Map<String, dynamic>>> subServices1(String mainId) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/maintenance/sub-services-1',
        query: {'mainId': mainId},
      );
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  /// Periodic (PM) packages for a main service, priced for a model.
  Future<List<Map<String, dynamic>>> periodicServices(
      String mainId, String? modelCode) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/maintenance/periodic-services',
        query: {'mainId': mainId, 'modelCode': ?modelCode},
      );
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  Future<List<MaintBranch>> branches() async {
    try {
      final res = await _api.get<List<dynamic>>(ApiPaths.maintBranches);
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MaintBranch.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// Available booking hours for a day (real capacity cycle).
  Future<List<String>> hours(DateTime date) async {
    try {
      final res = await _api.get<List<dynamic>>(
        ApiPaths.maintHours,
        query: {
          'date':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        },
      );
      return (res.data ?? []).map((e) => e.toString()).toList();
    } on DioException {
      return const [];
    }
  }

  /// POST /maintenance/bookings — audit insert + App_ServiceRequestAdd, so
  /// the order reaches operations + email like every website booking.
  Future<bool> book(Map<String, dynamic> body) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
          ApiPaths.maintBookings,
          body: body);
      return res.data?['ok'] == true;
    } on DioException {
      return false;
    }
  }
}
