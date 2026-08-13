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

  /// The agreed applicant types — G4 individuals / G3 companies — shown
  /// whenever the API answers without custGroups so the "نوع مقدم الطلب"
  /// picker is never empty.
  static const List<CustGroup> kDefaultCustGroups = [
    CustGroup(
        id: 'G4',
        nameAr: 'أفراد',
        nameEn: 'Individuals',
        needIdentity: true),
    CustGroup(
        id: 'G3',
        nameAr: 'شركات ومؤسسات',
        nameEn: 'Companies & Organizations',
        needIdentity: false),
  ];

  static FormSettings _withCustGroupFallback(FormSettings s) =>
      s.custGroups.isNotEmpty
          ? s
          : FormSettings(custGroups: kDefaultCustGroups, cities: s.cities);

  Future<FormSettings> formSettings() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/app/online/form-settings');
      return _withCustGroupFallback(res.data == null
          ? const FormSettings()
          : FormSettings.fromJson(res.data!));
    } on DioException {
      return _withCustGroupFallback(const FormSettings());
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

  /// The old store's BUY: down-payment reservation via
  /// Site_Reservation_Car_Payment (MyFatoorah). Returns the raw result
  /// {status, urlPayment, sadadNumber, orderId, messageError}.
  Future<Map<String, dynamic>?> reservationPay(
      Map<String, dynamic> body) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
          '/api/app/online/reservations/pay',
          body: body);
      return res.data;
    } on DioException catch (e) {
      final d = e.response?.data;
      return d is Map<String, dynamic> ? d : null;
    }
  }

  /// One reservation draft by its deposit OrderGUID — the post-payment
  /// "complete purchase" resume (website getCarReservationByGuid).
  Future<CarReservation?> reservationByGuid(String guid) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/api/app/online/reservations/by-guid',
        query: {'guid': guid},
      );
      return res.statusCode == 200 && res.data != null
          ? CarReservation.fromJson(res.data!)
          : null;
    } on DioException {
      return null;
    }
  }

  /* ── Post-deposit continuation — the website's /api/carso wrappers ── */

  /// The ERP webreports URL for the online-registration sales contract —
  /// same constant as the website's contractPdfUrl().
  static String contractPdfUrl(String orderGuid) =>
      'https://cloud.hassanjameel.com.sa/tools/webreports?ObjectName=MInvoiceOnline'
      '&GUID=${Uri.encodeComponent(orderGuid)}'
      '&ReportID=329B1875-3DB2-4AC5-B8ED-3A9D2B511D11&type=OnlineRegistration';

  // Site_Car_Payment / the PDF proxy can be slow (order creation + ERP
  // report render) — give them a longer receive window than the default.
  static const _slow = Duration(seconds: 60);

  /// Site_Car_Payment — order-init (InitializeOrder:true → OrderGUID/OrderId)
  /// AND the final charge (InitializeOrder:false → URL_Payment/SadadNumber).
  Future<List<Map<String, dynamic>>> carsoCarPayment(
      Map<String, dynamic> payload) async {
    try {
      final res = await _api.dio.post<List<dynamic>>(
          '/api/app/carso/car-payment',
          data: payload,
          options: Options(receiveTimeout: _slow));
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  /// Payment status by sales-order GUID (after the gateway callback).
  Future<List<Map<String, dynamic>>> carsoPaymentStatus(String guid) async {
    try {
      final res = await _api.post<List<dynamic>>(
          '/api/app/carso/car-payment/status?id=${Uri.encodeComponent(guid)}');
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  /// Absher OTP as the digital signature on the contract — send then verify.
  Future<Map<String, dynamic>?> carsoSignSend(
          String identityNumber, String lang) =>
      _postOne('/api/app/carso/sign/send',
          {'identityNumber': identityNumber, 'lang': lang});

  Future<Map<String, dynamic>?> carsoSignVerify(
          String identityNumber, String codeOtp) =>
      _postOne('/api/app/carso/sign/verify',
          {'identityNumber': identityNumber, 'codeOtp': codeOtp});

  /// Contract PDF via the allow-listed server-side proxy → base64 string.
  Future<String?> carsoAgreementPdf(String url) async {
    try {
      final res = await _api.dio.post<String>('/api/app/carso/agreement-pdf',
          data: {'url': url},
          options: Options(
              receiveTimeout: _slow, responseType: ResponseType.plain));
      final b64 = res.data;
      return (res.statusCode == 200 && b64 != null && b64.isNotEmpty)
          ? b64
          : null;
    } on DioException {
      return null;
    }
  }

  /// The vehicle's delivery-schedule row (GUID/SiteID/StandardDeliveryDuration).
  Future<List<Map<String, dynamic>>> carsoDeliveryVehicle(
      String sn, String salesOrderId, String guestId) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/carso/delivery/vehicle',
        query: {'sn': sn, 'salesOrderId': salesOrderId, 'guestId': guestId},
      );
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  /// Available delivery slots (FromTime/ToTime) for a date + site.
  Future<List<Map<String, dynamic>>> carsoDeliveryAvailable(
      String date, String siteId, bool standardDuration) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/carso/delivery/available',
        query: {
          'date': date,
          'siteId': siteId,
          'standardDuration': standardDuration ? 'true' : 'false',
        },
      );
      return (res.data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException {
      return const [];
    }
  }

  /// Book a delivery slot (writes BookingFrom/BookingTo by schedule GUID).
  Future<Map<String, dynamic>?> carsoDeliveryBook(
          String guid, String bookingFrom, String bookingTo) =>
      _postOne('/api/app/carso/delivery/book',
          {'guid': guid, 'bookingFrom': bookingFrom, 'bookingTo': bookingTo});

  /// POST returning a single dynamic row — tolerates both an object and a
  /// one-row array body (the procs return either).
  Future<Map<String, dynamic>?> _postOne(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _api.post<dynamic>(path, body: body);
      final d = res.data;
      if (d is Map<String, dynamic>) return d;
      if (d is List) return d.whereType<Map<String, dynamic>>().firstOrNull;
      return null;
    } on DioException {
      return null;
    }
  }

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
