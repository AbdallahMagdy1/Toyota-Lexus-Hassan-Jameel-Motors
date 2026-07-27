import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../home/domain/home_models.dart';
import '../domain/online_store_models.dart';

/// Buy-online cycle — same endpoints/DTOs as the website's online store.
final class OnlineStoreRepository {
  OnlineStoreRepository(this._api);

  final ApiClient _api;

  Future<List<OnlineVehicle>> vehicles() async {
    try {
      final res = await _api.get<List<dynamic>>('/api/app/online/vehicles');
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OnlineVehicle.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// Detail row (SliderVehicleDto shape) — carries the stock `sn` the quick
  /// reservation requires.
  Future<SliderVehicle?> detail(String slug) async {
    try {
      final res =
          await _api.get<Map<String, dynamic>>('/api/app/online/vehicles/$slug');
      return res.statusCode == 200 && res.data != null
          ? SliderVehicle.fromJson(res.data!)
          : null;
    } on DioException {
      return null;
    }
  }

  /// "Pick a bank" — figures precomputed per price by the API.
  Future<List<BankOffer>> banks(double? price) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/online/banks',
        query: {'price': ?price},
      );
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BankOffer.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  Future<FormSettings> formSettings() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/app/online/form-settings');
      return res.data == null ? const FormSettings() : FormSettings.fromJson(res.data!);
    } on DioException {
      return const FormSettings();
    }
  }

  Future<ReservationSettings> reservationSettings() async {
    try {
      final res =
          await _api.get<Map<String, dynamic>>('/api/app/online/reservation-settings');
      return res.data == null
          ? const ReservationSettings()
          : ReservationSettings.fromJson(res.data!);
    } on DioException {
      return const ReservationSettings();
    }
  }

  Future<SubmissionResult> submitContact(Map<String, dynamic> body) =>
      _post('/api/app/online/contact-requests', body);

  Future<SubmissionResult> submitFinance(Map<String, dynamic> body) =>
      _post('/api/app/online/finance-requests', body);

  Future<SubmissionResult> submitReservation(Map<String, dynamic> body) =>
      _post('/api/app/online/reservations', body);

  Future<SubmissionResult> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(path, body: body);
      if (res.data != null) return SubmissionResult.fromJson(res.data!);
      return const SubmissionResult(ok: false);
    } on DioException {
      return const SubmissionResult(ok: false, error: 'network');
    }
  }
}
