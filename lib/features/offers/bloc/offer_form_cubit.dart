import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../account/data/account_repository.dart';
import '../../account/domain/account_models.dart';
import '../../auth/domain/app_user.dart';
import '../../online_store/data/online_store_repository.dart';
import '../data/offers_repository.dart';
import '../domain/offer_models.dart';

/// Which website dialog this form replicates.
enum OfferFormKind { reserve, contact, finance }

enum OfferFormPhase { editing, busy, done, failed }

final class OfferFormState extends Equatable {
  const OfferFormState({
    this.phase = OfferFormPhase.editing,
    this.vehicleIndex,
    this.packageId,
    this.period = 60,
    this.error,
    this.garage = const [],
    this.useMyCar = false,
    this.myCarIndex = 0,
    this.prefDate,
    this.prefTime,
  });

  final OfferFormPhase phase;
  final int? vehicleIndex;
  final int? packageId;
  final int period;
  final String? error;

  /// Signed-in user's cars that fit this offer's brands — the app extra the
  /// user asked for ("احجز لسيارتي") on top of the website behavior.
  final List<GarageCar> garage;
  final bool useMyCar;
  final int myCarIndex;

  /// Preferred reservation slot — included in the staff email.
  final DateTime? prefDate;
  final String? prefTime;

  GarageCar? get myCar => garage.elementAtOrNull(myCarIndex);

  OfferFormState copyWith({
    OfferFormPhase? phase,
    int? Function()? vehicleIndex,
    int? Function()? packageId,
    int? period,
    String? Function()? error,
    List<GarageCar>? garage,
    bool? useMyCar,
    int? myCarIndex,
    DateTime? Function()? prefDate,
    String? Function()? prefTime,
  }) =>
      OfferFormState(
        phase: phase ?? this.phase,
        vehicleIndex: vehicleIndex == null ? this.vehicleIndex : vehicleIndex(),
        packageId: packageId == null ? this.packageId : packageId(),
        period: period ?? this.period,
        error: error == null ? this.error : error(),
        garage: garage ?? this.garage,
        useMyCar: useMyCar ?? this.useMyCar,
        myCarIndex: myCarIndex ?? this.myCarIndex,
        prefDate: prefDate == null ? this.prefDate : prefDate(),
        prefTime: prefTime == null ? this.prefTime : prefTime(),
      );

  @override
  List<Object?> get props => [
        phase, vehicleIndex, packageId, period, error, garage, useMyCar,
        myCarIndex, prefDate, prefTime,
      ];
}

/// One cubit for the three offer application flows — the same three dialogs
/// the website opens from an offer detail page:
///  • maintenance offer  → POST /offers/reserve (name/phone/email + car info)
///  • plain vehicle offer → POST /online/contact-requests (callback lead)
///  • finance offer       → POST /online/finance-requests (source "Offer")
/// The app difference: only signed-in users reach this form, so identity
/// fields prefill from the account.
final class OfferFormCubit extends Cubit<OfferFormState> {
  OfferFormCubit({
    required this.kind,
    required this.detail,
    required OffersRepository offersRepo,
    required OnlineStoreRepository onlineRepo,
    required this.user,
    required String lang,
    AccountRepository? accountRepo,
  })  : _offers = offersRepo,
        _online = onlineRepo,
        super(OfferFormState(
          period: detail.defaultFinancePeriod ?? 60,
          vehicleIndex: detail.supportedVehicles.isEmpty ? null : 0,
          packageId:
              detail.packages.isNotEmpty ? detail.packages.first.id : null,
        )) {
    name.text = user?.displayName(lang) ?? '';
    phone.text = user?.phone ?? '';
    email.text = user?.email ?? '';
    _loadGarage(accountRepo);
  }

  /// Load the user's cars matching the offer's brands, so the form can offer
  /// "احجز لسيارتي" (VIN/meter/year prefilled) or "سيارة أخرى".
  Future<void> _loadGarage(AccountRepository? repo) async {
    if (repo == null || user == null) return;
    final cars = await repo.garage(user!.userId);
    if (isClosed || cars.isEmpty) return;
    final offerBrands = (detail.offer.brandList ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final supportedBrands = detail.supportedVehicles
        .map((v) => v.brandId ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
    final allowed = {...offerBrands, ...supportedBrands};
    final fitting = allowed.isEmpty
        ? cars
        : cars.where((c) => allowed.contains(c.brandDbId)).toList();
    if (fitting.isEmpty) return;
    emit(state.copyWith(garage: fitting, useMyCar: true));
    _applyMyCar(fitting.first);
  }

  void _applyMyCar(GarageCar car) {
    if ((car.year ?? '').isNotEmpty) year.text = car.year!;
    if (car.meterReading != null) meter.text = '${car.meterReading}';
    if ((car.vin ?? '').isNotEmpty) vin.text = car.vin!;
  }

  void toggleMyCar(bool mine) {
    emit(state.copyWith(useMyCar: mine));
    if (mine && state.myCar != null) {
      _applyMyCar(state.myCar!);
    } else {
      year.clear();
      meter.clear();
      vin.clear();
    }
  }

  void selectMyCar(int? i) {
    if (i == null) return;
    emit(state.copyWith(myCarIndex: i));
    final car = state.garage.elementAtOrNull(i);
    if (car != null) _applyMyCar(car);
  }

  final OfferFormKind kind;
  final OfferDetail detail;
  final OffersRepository _offers;
  final OnlineStoreRepository _online;
  final AppUser? user;

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final identity = TextEditingController();
  final income = TextEditingController();
  final year = TextEditingController();
  final meter = TextEditingController();
  final vin = TextEditingController();
  final note = TextEditingController();

  OfferVehicle? get vehicle => state.vehicleIndex == null
      ? null
      : detail.supportedVehicles.elementAtOrNull(state.vehicleIndex!);

  void selectVehicle(int? i) => emit(state.copyWith(vehicleIndex: () => i));
  void selectPackage(int? id) => emit(state.copyWith(packageId: () => id));
  void selectPeriod(int p) => emit(state.copyWith(period: p));
  void setPrefDate(DateTime? d) => emit(state.copyWith(prefDate: () => d));
  void setPrefTime(String? tm) => emit(state.copyWith(prefTime: () => tm));

  String _fullPhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('00')) return '+${p.substring(2)}';
    if (p.startsWith('0')) p = p.substring(1);
    return '+966$p';
  }

  bool _validate() {
    final okPhone =
        RegExp(r'^\+?\d{10,15}$').hasMatch(_fullPhone(phone.text));
    var ok = name.text.trim().isNotEmpty && okPhone;
    if (kind == OfferFormKind.finance) {
      ok = ok && (double.tryParse(income.text.trim()) ?? 0) > 0;
    }
    if (!ok) emit(state.copyWith(error: () => 'invalid'));
    return ok;
  }

  Future<bool> submit(String lang) async {
    if (!_validate()) return false;
    emit(state.copyWith(phase: OfferFormPhase.busy, error: () => null));

    final o = detail.offer;
    final v = vehicle;
    final mine = state.useMyCar ? state.myCar : null;
    bool ok;
    switch (kind) {
      case OfferFormKind.reserve:
        // Website OfferReserveDialog payload verbatim: subject = title —
        // package, message packs the vehicle details. With "my car" picked,
        // the car identity comes from the garage (VIN prefilled).
        final pkg = detail.packages
            .where((p) => p.id == state.packageId)
            .firstOrNull;
        final parts = <String>[
          if (mine != null)
            'Model: ${mine.brandEn ?? ''} ${mine.modelEn ?? ''}'.trim()
          else if (v != null)
            'Model: ${v.nameEn ?? v.nameAr ?? ''} ${v.groupEn ?? ''}',
          if (year.text.trim().isNotEmpty) 'Year: ${year.text.trim()}',
          if (meter.text.trim().isNotEmpty) 'Meter: ${meter.text.trim()}',
          if (vin.text.trim().isNotEmpty) 'VIN: ${vin.text.trim()}',
          if (pkg != null) 'Package: ${pkg.titleEn ?? pkg.titleAr ?? ''}',
          if (note.text.trim().isNotEmpty) 'Note: ${note.text.trim()}',
        ];
        ok = await _offers.reserve({
          'offerId': o.id,
          'userId': user?.userId,
          'name': name.text.trim(),
          'email': email.text.trim().isEmpty ? null : email.text.trim(),
          'phone': _fullPhone(phone.text),
          'subject': pkg == null
              ? o.title(lang)
              : '${o.title(lang)} — ${pkg.title(lang)}',
          'message': parts.join(' | '),
          'preferredDate':
              state.prefDate?.toIso8601String().substring(0, 10),
          'preferredTime': state.prefTime,
          'vehicleLine': mine == null
              ? null
              : '${mine.brandEn ?? ''} ${mine.modelEn ?? ''} ${mine.year ?? ''} — VIN ${mine.vin ?? ''}'
                  .trim(),
        });
      case OfferFormKind.contact:
        // Website OfferPurchaseDialog → contact request; note carries the
        // offer title so sales sees the source.
        final res = await _online.submitContact({
          'name': name.text.trim(),
          'phone': _fullPhone(phone.text),
          'email': email.text.trim().isEmpty ? null : email.text.trim(),
          'quantity': 1,
          'brandID': mine?.brandDbId ?? v?.brandId,
          'productGroupID': mine?.productGroupId ?? v?.groupId,
          'productTypeID': mine?.type ?? v?.productTypeId,
          'modelYear': mine?.year ?? v?.year,
          'custGroupID': 'G4',
          'note': [
            'Offer: ${o.titleEn ?? o.titleAr ?? o.id}',
            if (note.text.trim().isNotEmpty) note.text.trim(),
          ].join(' | '),
        });
        ok = res.ok;
      case OfferFormKind.finance:
        // Website OfferFinanceDialog → finance request with source "Offer";
        // the bank is derived server-side from the offer's BankGuid.
        final res = await _online.submitFinance({
          'fullNameAr': name.text.trim(),
          'fullNameEn': name.text.trim(),
          'phoneNumber': _fullPhone(phone.text),
          'webUserID': user?.userId,
          'email': email.text.trim().isEmpty ? null : email.text.trim(),
          'custType': 'G4',
          'identityNo':
              identity.text.trim().isEmpty ? null : identity.text.trim(),
          'modelYear': mine?.year ??
              v?.year ??
              (year.text.trim().isEmpty ? null : year.text.trim()),
          'income': double.tryParse(income.text.trim()),
          'period': state.period,
          'offerID': o.id,
          'source': 'Offer',
          'message':
              note.text.trim().isEmpty ? null : note.text.trim(),
        });
        ok = res.ok;
    }

    if (isClosed) return ok;
    emit(state.copyWith(
        phase: ok ? OfferFormPhase.done : OfferFormPhase.failed));
    return ok;
  }

  @override
  Future<void> close() {
    for (final c in [name, phone, email, identity, income, year, meter, vin, note]) {
      c.dispose();
    }
    return super.close();
  }
}
