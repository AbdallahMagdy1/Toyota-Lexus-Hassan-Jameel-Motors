import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/domain/home_models.dart';
import '../../online_store/data/online_store_repository.dart';
import '../data/finance_repository.dart';
import '../domain/finance_math.dart';
import '../domain/finance_models.dart';

enum FinanceCalcStatus { loading, ready, error }

/// One row of the benefit report: a bank + its computeFinance estimate.
final class BankEstimate {
  const BankEstimate(this.bank, this.estimate);

  final FinanceBank bank;
  final FinanceEstimate estimate;
}

final class FinanceCalcState extends Equatable {
  const FinanceCalcState({
    this.status = FinanceCalcStatus.loading,
    this.vehicles = const [],
    this.banks = const [],
    this.custGroups = const [],
    this.groupKey,
    this.trimIndex,
    this.period = 60,
    this.downPct,
    this.showReport = false,
  });

  final FinanceCalcStatus status;
  final List<OnlineVehicle> vehicles;
  final List<FinanceBank> banks;
  final List<FinanceCustGroup> custGroups;

  /// brandId|carGroupId|year — the hero's "Car" dropdown key.
  final String? groupKey;
  final int? trimIndex;
  final int period;

  /// Down-payment % override (null = each bank's own advance rate).
  final double? downPct;
  final bool showReport;

  static String keyOf(OnlineVehicle v) =>
      '${v.brandId}|${v.carGroupId}|${v.year}';

  /// The "Car" dropdown: one entry per group (dedup by brand|group|year).
  List<OnlineVehicle> groupsFor(String wantedDbId) {
    final seen = <String>{};
    final out = <OnlineVehicle>[];
    for (final v in vehicles) {
      if (v.brandId != wantedDbId) continue;
      if (seen.add(keyOf(v))) out.add(v);
    }
    return out;
  }

  /// The "Model" dropdown: trims inside the picked group.
  List<OnlineVehicle> trimsFor(String wantedDbId) => groupKey == null
      ? const []
      : vehicles
          .where((v) => v.brandId == wantedDbId && keyOf(v) == groupKey)
          .toList();

  OnlineVehicle? selected(String wantedDbId) {
    final trims = trimsFor(wantedDbId);
    if (trims.isEmpty) return null;
    return trims.elementAtOrNull(trimIndex ?? 0) ?? trims.first;
  }

  /// The report: every bank computed on the picked car's price, cheapest
  /// monthly first — the website's FinanceBenefitReport.
  List<BankEstimate> report(String wantedDbId) {
    final car = selected(wantedDbId);
    final price = car?.minPrice ?? 0;
    if (price <= 0) return const [];
    final rows = <BankEstimate>[];
    for (final b in banks) {
      final p = period > b.maxFinancePeriod ? b.maxFinancePeriod : period;
      final down =
          downPct == null ? null : ((downPct! / 100) * price).roundToDouble();
      rows.add(BankEstimate(
          b, computeFinance(price, b, p, customFirstPay: down)));
    }
    rows.sort((a, b) => a.estimate.monthly.compareTo(b.estimate.monthly));
    return rows;
  }

  FinanceCalcState copyWith({
    FinanceCalcStatus? status,
    List<OnlineVehicle>? vehicles,
    List<FinanceBank>? banks,
    List<FinanceCustGroup>? custGroups,
    String? Function()? groupKey,
    int? Function()? trimIndex,
    int? period,
    double? Function()? downPct,
    bool? showReport,
  }) =>
      FinanceCalcState(
        status: status ?? this.status,
        vehicles: vehicles ?? this.vehicles,
        banks: banks ?? this.banks,
        custGroups: custGroups ?? this.custGroups,
        groupKey: groupKey == null ? this.groupKey : groupKey(),
        trimIndex: trimIndex == null ? this.trimIndex : trimIndex(),
        period: period ?? this.period,
        downPct: downPct == null ? this.downPct : downPct(),
        showReport: showReport ?? this.showReport,
      );

  @override
  List<Object?> get props => [
        status, vehicles, banks, custGroups, groupKey, trimIndex,
        period, downPct, showReport,
      ];
}

/// The home-hero "Finance" tab as a bottom sheet: pick car → pick model →
/// price appears → Calculate → per-bank benefit report (website math).
final class FinanceCalcCubit extends Cubit<FinanceCalcState> {
  FinanceCalcCubit(this._online, this._finance)
      : super(const FinanceCalcState()) {
    _load();
  }

  final OnlineStoreRepository _online;
  final FinanceRepository _finance;

  Future<void> _load() async {
    final vehicles = await _online.vehicles();
    final banks = await _finance.banks();
    final filters = await _finance.filters();
    if (isClosed) return;
    if (vehicles.isEmpty || banks.isEmpty) {
      emit(state.copyWith(status: FinanceCalcStatus.error));
      return;
    }
    emit(state.copyWith(
      status: FinanceCalcStatus.ready,
      vehicles: vehicles,
      banks: banks,
      custGroups: filters.custGroups,
    ));
  }

  void selectGroup(String? key) => emit(state.copyWith(
        groupKey: () => key,
        trimIndex: () => 0,
        showReport: false,
      ));

  void selectTrim(int? i) =>
      emit(state.copyWith(trimIndex: () => i, showReport: false));

  void selectPeriod(int p) => emit(state.copyWith(period: p));

  void setDownPct(double? pct) => emit(state.copyWith(downPct: () => pct));

  void calculate() => emit(state.copyWith(showReport: true));
}
