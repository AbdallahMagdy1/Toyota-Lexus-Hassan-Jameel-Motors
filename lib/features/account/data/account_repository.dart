import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/di/injector.dart' show appBrand;
import '../../../core/network/api_client.dart';
import '../domain/account_models.dart';

/// Brand pass over garage rows — mirrors the server's FilterGarageByBrand
/// so pre-update caches and not-yet-redeployed servers can never surface a
/// Toyota car inside the Lexus app (and vice versa). Cars with no brand
/// info (user-added) stay visible in both apps rather than vanish.
List<GarageCar> filterGarageByBrand(List<GarageCar> cars) {
  bool hasBrand(GarageCar c) =>
      (c.brandEn ?? '').trim().isNotEmpty || (c.brandAr ?? '').trim().isNotEmpty;
  bool isLexus(GarageCar c) =>
      (c.brandEn ?? '').toLowerCase().contains('lexus') ||
      (c.brandAr ?? '').contains('لكزس');
  return appBrand == 'lexus'
      ? cars.where((c) => isLexus(c) || !hasBrand(c)).toList()
      : cars.where((c) => !isLexus(c)).toList();
}

/// Same pass over the raw home-state JSON, applied BEFORE parsing so the
/// dynamic card / cached cold-start paint are brand-scoped too.
Map<String, dynamic> _filterHomeStateJson(Map<String, dynamic> j) {
  final garage = j['garage'];
  if (garage is List) {
    bool hasBrand(Map m) =>
        (m['brandEn']?.toString().trim().isNotEmpty ?? false) ||
        (m['brandAr']?.toString().trim().isNotEmpty ?? false);
    bool isLexus(Map m) =>
        (m['brandEn']?.toString().toLowerCase() ?? '').contains('lexus') ||
        (m['brandAr']?.toString() ?? '').contains('لكزس');
    j['garage'] = garage
        .whereType<Map<String, dynamic>>()
        .where((m) =>
            appBrand == 'lexus' ? (isLexus(m) || !hasBrand(m)) : !isLexus(m))
        .toList();
  }
  return j;
}

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
      final state = HomeState.fromJson(
          _filterHomeStateJson(jsonDecode(raw) as Map<String, dynamic>));
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
          // Brand-scopes the garage/dynamic card: the Lexus app must never
          // surface the customer's Toyota cars (and vice versa).
          'brand': appBrand,
          if ((custId ?? '').isNotEmpty) 'custId': custId,
          if ((phone ?? '').isNotEmpty) 'phone': phone,
          if (fresh) 'fresh': true,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final state = HomeState.fromJson(_filterHomeStateJson(res.data!));
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

  /// Reschedule a maintenance booking — the website profile tab's cycle
  /// (App_ServiceRequestUpdate: ownership + status='Created' gated in SQL,
  /// ops notified). Returns null on success, else the error to show.
  Future<String?> updateBooking({
    required String guid,
    required String custId,
    required String orderdate, // yyyy-MM-dd
    required String orderTime, // HH:mm:ss
  }) async {
    try {
      final res = await _api.put<Map<String, dynamic>>(
        '/api/app/maintenance/bookings',
        body: {
          'guid': guid,
          'custId': custId,
          'orderdate': orderdate,
          'orderTime': orderTime,
        },
      );
      if (res.data?['ok'] == true) return null;
      final err = '${res.data?['error'] ?? ''}';
      return err.isEmpty || err == 'null' ? '' : err;
    } on DioException {
      return '';
    }
  }

  /// Cancel (soft-delete) a maintenance booking — the website myBookings
  /// cycle (App_ServiceRequestDelete: ownership + status='Created' gated in
  /// SQL, row kept for audit, ops notified). Null on success, else error.
  Future<String?> cancelBooking({
    required String guid,
    required String custId,
    required String reason,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/maintenance/bookings/cancel',
        body: {'guid': guid, 'custId': custId, 'reason': reason},
      );
      if (res.data?['ok'] == true) return null;
      final err = '${res.data?['error'] ?? ''}';
      return err.isEmpty || err == 'null' ? '' : err;
    } on DioException {
      return '';
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
      final res = await _api.get<List<dynamic>>(ApiPaths.accountGarage,
          query: {'userId': userId, 'brand': appBrand});
      return filterGarageByBrand((res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GarageCar.fromJson)
          .toList());
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

  /// Rename a garage car (App_UserCar_SetAlias). Returns (ok, reason).
  Future<(bool, String?)> setCarAlias({
    required String vin,
    required int userId,
    required String alias,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/account/garage/alias',
        body: {'vin': vin, 'userId': userId, 'alias': alias},
      );
      final j = res.data ?? const {};
      return (j['ok'] == true, j['reason']?.toString());
    } on DioException {
      return (false, 'network');
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
