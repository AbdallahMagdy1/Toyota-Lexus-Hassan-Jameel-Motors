import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../coupons/domain/coupon_models.dart';

/* ─────────────────── case-tolerant dynamic-row helpers ───────────────────
 * The job-card endpoints return raw Dapper rows serialized with a camelCase
 * dictionary-key policy, so "Net Total" arrives as "net Total", "GUID" as
 * "guid", "SadadNumber" as "sadadNumber"… Keys are therefore matched
 * case-insensitively, mirroring the website page's `field()` helper. */

dynamic jcField(Map<String, dynamic>? obj, List<String> keys) {
  if (obj == null) return null;
  for (final k in keys) {
    final kl = k.toLowerCase();
    for (final e in obj.entries) {
      if (e.key.toLowerCase() == kl) return e.value;
    }
  }
  return null;
}

String jcStr(Map<String, dynamic>? obj, List<String> keys) {
  final v = jcField(obj, keys);
  return v == null ? '' : '$v';
}

double jcNum(Map<String, dynamic>? obj, List<String> keys) {
  final v = jcField(obj, keys);
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

bool jcTruthy(Map<String, dynamic>? obj, List<String> keys) {
  final v = jcField(obj, keys);
  return v == true || v == 1 || '$v' == '1' || '$v'.toLowerCase() == 'true';
}

Map<String, dynamic>? jcMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<Map<String, dynamic>> jcRows(dynamic v) => v is List
    ? [
        for (final e in v)
          if (e is Map) Map<String, dynamic>.from(e),
      ]
    : const [];

/// Passthrough to the mobile backend's /api/app/jobcard endpoints — the same
/// HJ_Live procs the website's /jobCard/[number] page calls. All requests are
/// POST { guid }; responses are loose dynamic rows (read with the jc* helpers).
final class JobCardRepository {
  JobCardRepository(this._api);

  final ApiClient _api;

  static const _base = '/api/app/jobcard';

  Future<Map<String, dynamic>?> _one(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _api.post<dynamic>('$_base/$path', body: body);
      return jcMap(res.data);
    } on DioException {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _many(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _api.post<dynamic>('$_base/$path', body: body);
      return jcRows(res.data);
    } on DioException {
      return const [];
    }
  }

  /// CheckJobCartStatus — INVERTED semantics: status == 0 means the card is
  /// PAID / settled / a payment was already issued (e.g. pending Sadad);
  /// status == 1 means it is still OPEN and payable.
  Future<Map<String, dynamic>?> paymentStatus(String guid) =>
      _one('payment-status', {'guid': guid});

  /// { netTotal: {numberNet, numberTotalBefore, numberDiscount, numberTax},
  ///   groupList, jobCardRespons: [raw rows] }
  Future<Map<String, dynamic>?> summary(String guid) =>
      _one('summary', {'guid': guid});

  /// Row 0 TamarClose truthy → Tamara/Tabby installments unavailable.
  Future<List<Map<String, dynamic>>> tamaraStatus(String guid) =>
      _many('tamara-status', {'guid': guid});

  /// Row 0 CheckCustomer truthy → complimentary card (free, no payment).
  Future<List<Map<String, dynamic>>> checkCustomer(String guid) =>
      _many('check-customer', {'guid': guid});

  Future<List<Map<String, dynamic>>> additionalsLines(String guid) =>
      _many('additionals-lines', {'guid': guid});

  /// Row 0 carries Remaining / PaidAmount for the additionals header.
  Future<List<Map<String, dynamic>>> additionalsHeader(String guid) =>
      _many('additionals-header', {'guid': guid});

  /// POST /api/app/jobcard/validate-coupon — server-computed coupon verdict
  /// for this job card. Failures resolve to the quiet invalid result so a
  /// coupon problem never blocks payment.
  Future<CouponResult> validateCoupon(
      String guid, String code, String lang) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '$_base/validate-coupon',
        body: {'guid': guid, 'code': code, 'lang': lang},
      );
      return res.data == null
          ? CouponResult.invalid
          : CouponResult.fromJson(res.data!);
    } on DioException {
      return CouponResult.invalid;
    }
  }

  /// Creates the provider payment; the redirect URL comes back as
  /// url_payment / URL_Paytabs / Url depending on the gateway. [couponCode]
  /// is forwarded only when the validate verdict was valid — the backend
  /// recomputes the discount server-side.
  Future<Map<String, dynamic>?> approvePayment(
    String guid, {
    required String prudocts,
    required String paymentType,
    required String callback,
    String? couponCode,
  }) =>
      _one('approve-payment', {
        'guid': guid,
        'prudocts': prudocts,
        'paymentType': paymentType,
        'callback': callback,
        if ((couponCode ?? '').isNotEmpty) 'couponCode': couponCode,
      });

  /// Second Sadad step — uploads the prepared bill and returns sadadNumber.
  Future<Map<String, dynamic>?> sadadCode(String guid) =>
      _one('sadad-code', {'guid': guid});

  Future<Map<String, dynamic>?> myFatoorahStatusFully(String guid) =>
      _one('myfatoorah-status-fully', {'guid': guid});

  Future<Map<String, dynamic>?> paytabsStatusFully(String guid) =>
      _one('paytabs-status-fully', {'guid': guid});

  Future<Map<String, dynamic>?> paytabsStatusPartially(String guid) =>
      _one('paytabs-status-partially', {'guid': guid});

  Future<Map<String, dynamic>?> tamaraCapture(String guid, String orderId) =>
      _one('tamara-capture', {'guid': guid, 'orderId': orderId});

  Future<Map<String, dynamic>?> tabbyCapture(String guid) =>
      _one('tabby-capture', {'guid': guid});
}
