import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    this.packageId,
    this.period = 60,
    this.error,
    this.prefDate,
    this.prefTime,
  });

  final OfferFormPhase phase;
  final int? packageId;
  final int period;
  final String? error;

  /// Preferred reservation slot — included in the staff email.
  final DateTime? prefDate;
  final String? prefTime;

  OfferFormState copyWith({
    OfferFormPhase? phase,
    int? Function()? packageId,
    int? period,
    String? Function()? error,
    DateTime? Function()? prefDate,
    String? Function()? prefTime,
  }) =>
      OfferFormState(
        phase: phase ?? this.phase,
        packageId: packageId == null ? this.packageId : packageId(),
        period: period ?? this.period,
        error: error == null ? this.error : error(),
        prefDate: prefDate == null ? this.prefDate : prefDate(),
        prefTime: prefTime == null ? this.prefTime : prefTime(),
      );

  @override
  List<Object?> get props =>
      [phase, packageId, period, error, prefDate, prefTime];
}

/// One cubit for the three offer application flows — the same three dialogs
/// the website opens from an offer detail page:
///  • maintenance offer  → POST /offers/reserve (name/phone/email + car info)
///  • plain vehicle offer → POST /online/contact-requests (callback lead)
///  • finance offer       → POST /online/finance-requests (source "Offer")
/// The app difference: only signed-in users reach this form, so identity
/// fields prefill from the account, and the car is always the supported
/// vehicle picked on the detail sheet's rail (no free car entry).
final class OfferFormCubit extends Cubit<OfferFormState> {
  OfferFormCubit({
    required this.kind,
    required this.detail,
    required this.vehicle,
    required OffersRepository offersRepo,
    required OnlineStoreRepository onlineRepo,
    required this.user,
    required String lang,
  })  : _offers = offersRepo,
        _online = onlineRepo,
        super(OfferFormState(
          period: detail.defaultFinancePeriod ?? 60,
          packageId:
              detail.packages.isNotEmpty ? detail.packages.first.id : null,
        )) {
    name.text = user?.displayName(lang) ?? '';
    phone.text = user?.phone ?? '';
    email.text = user?.email ?? '';
    if ((vehicle?.year ?? '').isNotEmpty) year.text = vehicle!.year!;
  }

  final OfferFormKind kind;
  final OfferDetail detail;

  /// The supported vehicle chosen on the detail sheet's rail — the only car
  /// this request can be for. Null only when the offer lists no supported
  /// vehicles (those offers keep submitting without car identifiers).
  final OfferVehicle? vehicle;

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
    bool ok;
    switch (kind) {
      case OfferFormKind.reserve:
        // Website OfferReserveDialog payload verbatim: subject = title —
        // package, message packs the vehicle details. The car identity is the
        // rail-selected supported vehicle.
        final pkg = detail.packages
            .where((p) => p.id == state.packageId)
            .firstOrNull;
        final parts = <String>[
          if (v != null)
            'Model: ${v.nameEn ?? v.nameAr ?? ''} ${v.groupEn ?? ''}'.trim(),
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
          'vehicleLine': v == null
              ? null
              : ('${v.nameEn ?? v.nameAr ?? ''} ${v.groupEn ?? ''} ${v.year ?? ''}'
                          .trim() +
                      (vin.text.trim().isEmpty
                          ? ''
                          : ' — VIN ${vin.text.trim()}'))
                  .trim(),
        });
      case OfferFormKind.contact:
        // Website OfferPurchaseDialog → contact request; note carries the
        // offer title so sales sees the source. Car identifiers come from
        // the selected supported vehicle (same payload keys as before).
        final res = await _online.submitContact({
          'name': name.text.trim(),
          'phone': _fullPhone(phone.text),
          'email': email.text.trim().isEmpty ? null : email.text.trim(),
          'quantity': 1,
          'brandID': v?.brandId,
          'productGroupID': v?.groupId,
          'productTypeID': v?.productTypeId,
          'modelYear': v?.year,
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
          'modelYear': v?.year ??
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
