import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse('$v');

/// One car in the user's garage (ERP cars + user-added cars, unified).
final class GarageCar extends Equatable {
  const GarageCar({
    this.guid,
    this.alias,
    this.fetchType,
    this.vin,
    this.brandAr,
    this.brandEn,
    this.groupAr,
    this.groupEn,
    this.modelAr,
    this.modelEn,
    this.plateAr,
    this.plateEn,
    this.modelCode,
    this.year,
    this.type,
    this.productGroupId,
    this.maintenanceLastDate,
    this.meterReading,
    this.image,
  });

  final String? guid;
  final String? alias;
  final String? fetchType; // Purchase (ERP) | user (added)
  final String? vin;
  final String? brandAr;
  final String? brandEn;
  final String? groupAr;
  final String? groupEn;
  final String? modelAr;
  final String? modelEn;
  final String? plateAr;
  final String? plateEn;
  final String? modelCode;
  final String? year;
  final String? type;
  final String? productGroupId;
  final DateTime? maintenanceLastDate;
  final int? meterReading;
  final String? image;

  String brand(String lang) =>
      (lang == 'ar' ? brandAr : brandEn) ?? brandEn ?? brandAr ?? '';
  String model(String lang) =>
      (lang == 'ar' ? modelAr : modelEn) ?? modelEn ?? modelAr ?? '';
  String plate(String lang) =>
      (lang == 'ar' ? plateAr : plateEn) ?? plateEn ?? plateAr ?? '';

  /// Display name: alias if the user named the car, else brand + model.
  String displayName(String lang) {
    final a = (alias ?? '').trim();
    if (a.isNotEmpty) return a;
    return '${brand(lang)} ${model(lang)}'.trim();
  }

  /// Plate shown partially, like the spec (never the full board).
  String maskedPlate(String lang) {
    final p = plate(lang).trim();
    if (p.length <= 4) return p;
    return '${p.substring(0, 4)}•••';
  }

  /// '1' Toyota / '2' Lexus — matches the app brand switch.
  String? get brandDbId {
    final b = (brandEn ?? '').toLowerCase();
    if (b.contains('toyota')) return '1';
    if (b.contains('lexus')) return '2';
    return null;
  }

  factory GarageCar.fromJson(Map<String, dynamic> j) => GarageCar(
        guid: _s(j['guid']),
        alias: _s(j['alias']),
        fetchType: _s(j['fetchType']),
        vin: _s(j['vin']),
        brandAr: _s(j['brandAr']),
        brandEn: _s(j['brandEn']),
        groupAr: _s(j['groupAr']),
        groupEn: _s(j['groupEn']),
        modelAr: _s(j['modelAr']),
        modelEn: _s(j['modelEn']),
        plateAr: _s(j['plateAr']),
        plateEn: _s(j['plateEn']),
        modelCode: _s(j['modelCode']),
        year: _s(j['year']),
        type: _s(j['type']),
        productGroupId: _s(j['productGroupId']),
        maintenanceLastDate: _dt(j['maintenanceLastDate']),
        meterReading: _i(j['meterReading']),
        image: _s(j['image']),
      );

  @override
  List<Object?> get props => [vin, guid];
}

/// App_Vehicle_NextPM — the backend-computed next maintenance.
/// Status: ok | overdue | needs_reading | no_mapping.
final class NextPm extends Equatable {
  const NextPm({
    this.status,
    this.lastPmkm,
    this.lastPmDate,
    this.nextPmkm,
    this.nextServiceNameAr,
    this.nextServiceNameEn,
    this.currentOdometer,
    this.odometerSource,
    this.odometerDate,
    this.remainingKM,
  });

  final String? status;
  final int? lastPmkm;
  final DateTime? lastPmDate;
  final int? nextPmkm;
  final String? nextServiceNameAr;
  final String? nextServiceNameEn;
  final int? currentOdometer;
  final String? odometerSource; // branch | customer
  final DateTime? odometerDate;
  final int? remainingKM;

  String nextServiceName(String lang) =>
      (lang == 'ar' ? nextServiceNameAr : nextServiceNameEn) ??
      nextServiceNameEn ??
      nextServiceNameAr ??
      '';

  factory NextPm.fromJson(Map<String, dynamic> j) => NextPm(
        status: _s(j['status']),
        lastPmkm: _i(j['lastPmkm']),
        lastPmDate: _dt(j['lastPmDate']),
        nextPmkm: _i(j['nextPmkm']),
        nextServiceNameAr: _s(j['nextServiceNameAr']),
        nextServiceNameEn: _s(j['nextServiceNameEn']),
        currentOdometer: _i(j['currentOdometer']),
        odometerSource: _s(j['odometerSource']),
        odometerDate: _dt(j['odometerDate']),
        remainingKM: _i(j['remainingKM']),
      );

  @override
  List<Object?> get props =>
      [status, nextPmkm, currentOdometer, remainingKM];
}

/// Live work order (App_User_ActiveWorkOrders row). ERP stages verified on
/// real data: Open → InProcess → Under Test → Ready to Release →
/// SentForPayment (→ Closed | Canceled).
final class WorkOrder extends Equatable {
  const WorkOrder({
    this.orderId,
    this.guid,
    this.status,
    this.dateIn,
    this.vin,
    this.plateNo,
    this.descriptionAr,
    this.descriptionEn,
    this.grandTotal,
    this.remaining,
    this.paymentStatus,
    this.urlPayment,
    this.sadadNumber,
  });

  final String? orderId;
  final String? guid;
  final String? status;
  final DateTime? dateIn;
  final String? vin;
  final String? plateNo;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? grandTotal;
  final double? remaining;
  final String? paymentStatus;
  final String? urlPayment;
  final String? sadadNumber;

  static const stages = [
    'Open', 'InProcess', 'Under Test', 'Ready to Release', 'SentForPayment'
  ];

  /// 0-based index in the stage bar (unknown → 0).
  int get stageIndex {
    final i = stages.indexOf(status ?? '');
    return i < 0 ? 0 : i;
  }

  bool get readyToPay => status == 'SentForPayment' || status == 'Ready to Release';

  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory WorkOrder.fromJson(Map<String, dynamic> j) => WorkOrder(
        orderId: _s(j['orderId']),
        guid: _s(j['guid']),
        status: _s(j['status']),
        dateIn: _dt(j['dateIn']),
        vin: _s(j['vin']),
        plateNo: _s(j['plateNo']),
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        grandTotal: _d(j['grandTotal']),
        remaining: _d(j['remaining']),
        paymentStatus: _s(j['paymentStatus']),
        urlPayment: _s(j['urlPayment']),
        sadadNumber: _s(j['sadadNumber']),
      );

  @override
  List<Object?> get props => [orderId, status];
}

final class UpcomingBooking extends Equatable {
  const UpcomingBooking({
    this.descriptionAr,
    this.descriptionEn,
    this.receptionId,
    this.orderdate,
    this.ordertime,
    this.price,
    this.guid,
    this.orderStatusId,
    this.chassis,
  });

  final String? descriptionAr;
  final String? descriptionEn;
  final String? receptionId;
  final DateTime? orderdate;
  final String? ordertime;
  final double? price;
  final String? guid;
  final String? orderStatusId;
  final String? chassis;

  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory UpcomingBooking.fromJson(Map<String, dynamic> j) => UpcomingBooking(
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        receptionId: _s(j['receptionId']),
        orderdate: _dt(j['orderdate']),
        ordertime: _s(j['ordertime']),
        price: _d(j['price']),
        guid: _s(j['guid']),
        orderStatusId: _s(j['orderStatusId']),
        chassis: _s(j['chassis']),
      );

  @override
  List<Object?> get props => [guid, receptionId];
}

final class UserOrder extends Equatable {
  const UserOrder({
    this.cartId,
    this.statusAr,
    this.statusEn,
    this.total,
    this.createdAt,
    this.urlPayment,
    this.sadadNumber,
  });

  final int? cartId;
  final String? statusAr;
  final String? statusEn;
  final double? total;
  final DateTime? createdAt;
  final String? urlPayment;
  final String? sadadNumber;

  String status(String lang) =>
      (lang == 'ar' ? statusAr : statusEn) ?? statusEn ?? statusAr ?? '';

  factory UserOrder.fromJson(Map<String, dynamic> j) => UserOrder(
        cartId: _i(j['cartId']),
        statusAr: _s(j['statusAr']),
        statusEn: _s(j['statusEn']),
        total: _d(j['total']),
        createdAt: _dt(j['createdAt']),
        urlPayment: _s(j['urlPayment']),
        sadadNumber: _s(j['sadadNumber']),
      );

  @override
  List<Object?> get props => [cartId];
}

final class OrderTrackingStep extends Equatable {
  const OrderTrackingStep({this.descriptionAr, this.descriptionEn, this.createdAt});

  final String? descriptionAr;
  final String? descriptionEn;
  final DateTime? createdAt;

  String description(String lang) =>
      (lang == 'ar' ? descriptionAr : descriptionEn) ??
      descriptionEn ??
      descriptionAr ??
      '';

  factory OrderTrackingStep.fromJson(Map<String, dynamic> j) =>
      OrderTrackingStep(
        descriptionAr: _s(j['descriptionAr']),
        descriptionEn: _s(j['descriptionEn']),
        createdAt: _dt(j['createdAt']),
      );

  @override
  List<Object?> get props => [descriptionAr, createdAt];
}

/// One row of "Active Journeys" — backend pre-sorts by the urgency ladder.
final class Journey extends Equatable {
  const Journey({
    required this.kind,
    this.priority = 9,
    this.titleAr,
    this.titleEn,
    this.status,
    this.reference,
    this.date,
    this.needsAction = false,
    this.payload,
  });

  final String kind; // workorder | booking | order | finance
  final int priority;
  final String? titleAr;
  final String? titleEn;
  final String? status;
  final String? reference;
  final DateTime? date;
  final bool needsAction;
  final Map<String, dynamic>? payload;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';

  factory Journey.fromJson(Map<String, dynamic> j) => Journey(
        kind: _s(j['kind']) ?? '',
        priority: _i(j['priority']) ?? 9,
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        status: _s(j['status']),
        reference: _s(j['reference']),
        date: _dt(j['date']),
        needsAction: j['needsAction'] == true,
        payload: j['payload'] is Map<String, dynamic>
            ? j['payload'] as Map<String, dynamic>
            : null,
      );

  @override
  List<Object?> get props => [kind, reference, status];
}

/// GET /api/app/account/home-state — the whole registered home.
final class HomeState extends Equatable {
  const HomeState({
    this.cardKind = 'addCar',
    this.workOrder,
    this.booking,
    this.car,
    this.nextPm,
    this.garage = const [],
    this.journeys = const [],
  });

  final String cardKind; // workorder | booking | car | addCar
  final WorkOrder? workOrder;
  final UpcomingBooking? booking;
  final GarageCar? car;
  final NextPm? nextPm;
  final List<GarageCar> garage;
  final List<Journey> journeys;

  factory HomeState.fromJson(Map<String, dynamic> j) {
    List<T> parse<T>(dynamic node, T Function(Map<String, dynamic>) f) =>
        (node as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    Map<String, dynamic>? m(dynamic v) =>
        v is Map<String, dynamic> ? v : null;
    return HomeState(
      cardKind: _s(j['cardKind']) ?? 'addCar',
      workOrder: m(j['workOrder']) == null ? null : WorkOrder.fromJson(m(j['workOrder'])!),
      booking: m(j['booking']) == null ? null : UpcomingBooking.fromJson(m(j['booking'])!),
      car: m(j['car']) == null ? null : GarageCar.fromJson(m(j['car'])!),
      nextPm: m(j['nextPm']) == null ? null : NextPm.fromJson(m(j['nextPm'])!),
      garage: parse(j['garage'], GarageCar.fromJson),
      journeys: parse(j['journeys'], Journey.fromJson),
    );
  }

  @override
  List<Object?> get props => [cardKind, workOrder, booking, car, nextPm, garage, journeys];
}

/// One tracked order across the three cycles (maintenance reservation /
/// protection & shading / parts orders) — App_Orders_TrackingSnapshot.
final class TrackedOrder extends Equatable {
  const TrackedOrder({
    required this.kind,
    this.refNo,
    this.guid,
    this.titleAr,
    this.titleEn,
    this.statusAr,
    this.statusEn,
    this.stageIndex = 0,
    this.stageCount = 1,
    this.isTerminal = false,
    this.needsPayment = false,
    this.total,
    this.sadadNumber,
    this.paymentUrl,
    this.orderDate,
  });

  final String kind; // maintenance | protection | order
  final String? refNo;
  final String? guid;
  final String? titleAr;
  final String? titleEn;
  final String? statusAr;
  final String? statusEn;
  final int stageIndex;
  final int stageCount;
  final bool isTerminal;
  final bool needsPayment;
  final double? total;
  final String? sadadNumber;
  final String? paymentUrl;
  final DateTime? orderDate;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String status(String lang) =>
      (lang == 'ar' ? statusAr : statusEn) ?? statusEn ?? statusAr ?? '';

  factory TrackedOrder.fromJson(Map<String, dynamic> j) => TrackedOrder(
        kind: _s(j['kind']) ?? '',
        refNo: _s(j['refNo']),
        guid: _s(j['guid']),
        titleAr: _s(j['titleAr']),
        titleEn: _s(j['titleEn']),
        statusAr: _s(j['statusAr']),
        statusEn: _s(j['statusEn']),
        stageIndex: _i(j['stageIndex']) ?? 0,
        stageCount: _i(j['stageCount']) ?? 1,
        isTerminal: j['isTerminal'] == true,
        needsPayment: j['needsPayment'] == true,
        total: _d(j['total']),
        sadadNumber: _s(j['sadadNumber']),
        paymentUrl: _s(j['paymentUrl']),
        orderDate: _dt(j['orderDate']),
      );

  @override
  List<Object?> get props => [kind, refNo, statusAr, statusEn];
}
