import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/account_models.dart';

/// Registered-user home cycle — backend owns state + priority; the app only
/// renders what /home-state returns.
final class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  // Last-known home per user — painted instantly while the fresh state
  // loads, so the registered home never blocks on the heavy garage TVF.
  static final Map<int, HomeState> _memo = {};

  HomeState? cachedHome(int userId) => _memo[userId];

  /// Disk copy of the last home payload — makes the very first paint after
  /// a cold app start instant (the network refresh continues behind it).
  Future<HomeState?> cachedHomeDisk(int userId) async {
    final inMemory = _memo[userId];
    if (inMemory != null) return inMemory;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('home_state_$userId');
      if (raw == null) return null;
      final state = HomeState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _memo[userId] = state;
      return state;
    } catch (_) {
      return null;
    }
  }

  Future<HomeState?> homeState({
    required int userId,
    String? custId,
    String? phone,
    bool fresh = false,
  }) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiPaths.accountHomeState,
        query: {
          'userId': userId,
          if ((custId ?? '').isNotEmpty) 'custId': custId,
          if ((phone ?? '').isNotEmpty) 'phone': phone,
          if (fresh) 'fresh': true,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final state = HomeState.fromJson(res.data!);
        _memo[userId] = state;
        // Fire-and-forget disk copy for instant cold-start paint.
        final raw = jsonEncode(res.data);
        SharedPreferences.getInstance()
            .then((p) => p.setString('home_state_$userId', raw))
            .ignore();
        return state;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Unified tracking over the three cycles (maintenance reservations /
  /// protection & shading / parts orders) — App_Orders_TrackingSnapshot.
  Future<List<TrackedOrder>> ordersTracking(
      {required int userId, String? custId}) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/account/orders-tracking',
        query: {
          'userId': userId,
          if ((custId ?? '').isNotEmpty) 'custId': custId,
        },
      );
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TrackedOrder.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  Future<List<GarageCar>> garage(int userId) async {
    try {
      final res = await _api
          .get<List<dynamic>>(ApiPaths.accountGarage, query: {'userId': userId});
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GarageCar.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// Add-car flow (pickers + manual VIN). Returns (ok, reason).
  Future<(bool, String?)> addCar(Map<String, dynamic> body) async {
    try {
      final res =
          await _api.post<Map<String, dynamic>>(ApiPaths.accountGarage, body: body);
      final j = res.data ?? const {};
      // The legacy inner proc answers InsertedId/Affected; the wrapper
      // answers Ok/Reason — treat either shape as success.
      final ok = j['ok'] == true || (j['affected'] is num && j['affected'] > 0);
      return (ok, j['reason']?.toString());
    } on DioException {
      return (false, 'network');
    }
  }

  /// Customer odometer reading. Returns (ok, reason, latestKnown).
  Future<(bool, String?, int?)> addMeterReading({
    required String vin,
    required int userId,
    required int reading,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.accountMeterReading,
        body: {'vin': vin, 'userId': userId, 'reading': reading},
      );
      final j = res.data ?? const {};
      return (
        j['ok'] == true,
        j['reason']?.toString(),
        j['latestKnown'] is num ? (j['latestKnown'] as num).toInt() : null,
      );
    } on DioException {
      return (false, 'network', null);
    }
  }

  Future<NextPm?> nextPm({
    required String vin,
    required String modelCode,
    int? userId,
  }) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiPaths.accountNextPm,
        query: {'vin': vin, 'modelCode': modelCode, 'userId': ?userId},
      );
      return res.statusCode == 200 && res.data != null
          ? NextPm.fromJson(res.data!)
          : null;
    } on DioException {
      return null;
    }
  }

  Future<List<OrderTrackingStep>> orderTracking(int cartId) async {
    try {
      final res = await _api
          .get<List<dynamic>>('${ApiPaths.accountOrders}/$cartId/tracking');
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderTrackingStep.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }
}
