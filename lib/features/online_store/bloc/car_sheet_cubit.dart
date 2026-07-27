import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/domain/home_models.dart';
import '../data/online_store_repository.dart';
import '../domain/online_store_models.dart';

/// One car's purchase sheet: loads detail (stock sn) + bank offers +
/// form/reservation settings in parallel; holds the color, bank, method and
/// T&C selections — the website's OnlineDetail + OnlineCheckout in one place.
enum PurchaseMethod { reserve, finance, contact }

enum SheetPage { overview, methods, form, success }

final class CarSheetState extends Equatable {
  const CarSheetState({
    this.loading = true,
    this.detail,
    this.banks = const [],
    this.formSettings = const FormSettings(),
    this.reservationSettings = const ReservationSettings(),
    this.color,
    this.selectedBankId,
    this.method = PurchaseMethod.reserve, // website default
    this.accepted = false,
    this.page = SheetPage.overview,
    this.reference,
  });

  final bool loading;
  final SliderVehicle? detail; // carries sn for quick reservation
  final List<BankOffer> banks;
  final FormSettings formSettings;
  final ReservationSettings reservationSettings;
  final CarColor? color;
  final String? selectedBankId;
  final PurchaseMethod method;
  final bool accepted;
  final SheetPage page;
  final String? reference; // HJ-… on success

  CarSheetState copyWith({
    bool? loading,
    SliderVehicle? detail,
    List<BankOffer>? banks,
    FormSettings? formSettings,
    ReservationSettings? reservationSettings,
    CarColor? color,
    String? selectedBankId,
    PurchaseMethod? method,
    bool? accepted,
    SheetPage? page,
    String? reference,
  }) =>
      CarSheetState(
        loading: loading ?? this.loading,
        detail: detail ?? this.detail,
        banks: banks ?? this.banks,
        formSettings: formSettings ?? this.formSettings,
        reservationSettings: reservationSettings ?? this.reservationSettings,
        color: color ?? this.color,
        selectedBankId: selectedBankId ?? this.selectedBankId,
        method: method ?? this.method,
        accepted: accepted ?? this.accepted,
        page: page ?? this.page,
        reference: reference ?? this.reference,
      );

  @override
  List<Object?> get props => [
        loading,
        detail,
        banks,
        formSettings,
        reservationSettings,
        color,
        selectedBankId,
        method,
        accepted,
        page,
        reference,
      ];
}

final class CarSheetCubit extends Cubit<CarSheetState> {
  CarSheetCubit(this._repo, this.vehicle, {required this.brandKey})
      : super(CarSheetState(
          color: vehicle.uniqueColors.isEmpty ? null : vehicle.uniqueColors.first,
        )) {
    _load();
  }

  final OnlineStoreRepository _repo;
  final OnlineVehicle vehicle;
  final String brandKey;

  double get downPayment => state.reservationSettings.forBrand(brandKey);

  Future<void> _load() async {
    final results = await Future.wait([
      if (vehicle.slug != null) _repo.detail(vehicle.slug!) else Future.value(null),
      _repo.banks(vehicle.minPrice),
      _repo.formSettings(),
      _repo.reservationSettings(),
    ]);
    if (isClosed) return;
    final banks = results[1] as List<BankOffer>;
    emit(state.copyWith(
      loading: false,
      detail: results[0] as SliderVehicle?,
      banks: banks,
      selectedBankId: banks.isEmpty ? null : banks.first.bankId,
      formSettings: results[2] as FormSettings,
      reservationSettings: results[3] as ReservationSettings,
    ));
  }

  void selectColor(CarColor c) => emit(state.copyWith(color: c));
  void selectBank(String? bankId) => emit(state.copyWith(selectedBankId: bankId));
  void selectMethod(PurchaseMethod m) => emit(state.copyWith(method: m));
  void toggleAccepted(bool v) => emit(state.copyWith(accepted: v));

  /// Overview NEXT → the "how would you like to buy" page.
  void goToMethods() => emit(state.copyWith(page: SheetPage.methods));

  void continueToForm() {
    if (state.accepted) emit(state.copyWith(page: SheetPage.form));
  }

  void backToOverview() => emit(state.copyWith(page: SheetPage.overview));
  void backToMethods() => emit(state.copyWith(page: SheetPage.methods));
  void showSuccess(String? reference) =>
      emit(state.copyWith(page: SheetPage.success, reference: reference));
}
