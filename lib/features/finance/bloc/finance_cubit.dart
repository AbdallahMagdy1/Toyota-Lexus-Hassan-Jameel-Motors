import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/finance_repository.dart';
import '../domain/finance_math.dart';
import '../domain/finance_models.dart';

enum FinanceStatus { loading, ready, error }

/// The website's three search modes: sliders / model dropdowns / max budget.
enum FinanceMode { monthly, model, budget }

final class FinanceState extends Equatable {
  const FinanceState({
    this.status = FinanceStatus.loading,
    this.banks = const [],
    this.filters = const FinanceFilters(),
    this.activeBankIndex = 0,
    this.vehicles = const [],
    this.vehiclesLoading = false,
    this.mode = FinanceMode.monthly,
    this.monthly = 3000,
    this.period = 60,
    this.lastBatch = 40000,
    this.monthlyTouched = false,
    this.budget,
    this.modelGroupId,
    this.refineCategory,
    this.refineGroupIds = const {},
    this.priceRange,
  });

  final FinanceStatus status;
  final List<FinanceBank> banks;
  final FinanceFilters filters;
  final int activeBankIndex;
  final List<FinanceVehicle> vehicles;
  final bool vehiclesLoading;

  final FinanceMode mode;
  // Monthly sliders — website ranges: 500–10000/50, 24–max/12, 0–250000/5000.
  final double monthly;
  final int period;
  final double lastBatch;
  final bool monthlyTouched;
  // Budget mode.
  final double? budget;
  // Model mode.
  final String? modelGroupId;
  // Refine facets.
  final String? refineCategory;
  final Set<String> refineGroupIds;
  final RangeValues? priceRange;

  FinanceBank? get activeBank => banks.elementAtOrNull(activeBankIndex);

  static const bodyCats = ['SEDAN', 'SUV', 'MVP', 'COUPES', 'COMMERCIAL'];

  /// Cars of the app's active brand for the current bank.
  List<FinanceVehicle> brandVehicles(String wantedDbId) =>
      vehicles.where((v) => v.brandId == wantedDbId).toList();

  /// Full pipeline: brand → mode filter → refine facets → website sort
  /// (body-type rank, then price).
  List<FinanceVehicle> visible(String wantedDbId) {
    var list = brandVehicles(wantedDbId);

    switch (mode) {
      case FinanceMode.monthly:
        if (monthlyTouched) {
          final cap = affordablePrice(monthly, period, lastBatch);
          list = list.where((v) => (v.minPrice ?? 0) <= cap).toList();
        }
      case FinanceMode.model:
        if (modelGroupId != null) {
          list = list.where((v) => v.carGroupId == modelGroupId).toList();
        }
      case FinanceMode.budget:
        if (budget != null && budget! > 0) {
          list = list.where((v) => (v.minPrice ?? 0) <= budget!).toList();
        }
    }

    if (refineCategory != null) {
      list = list
          .where((v) =>
              (v.category ?? '').toUpperCase() == refineCategory!.toUpperCase())
          .toList();
    }
    if (refineGroupIds.isNotEmpty) {
      list = list.where((v) => refineGroupIds.contains(v.carGroupId)).toList();
    }
    if (priceRange != null) {
      list = list
          .where((v) =>
              (v.minPrice ?? 0) >= priceRange!.start &&
              (v.minPrice ?? 0) <= priceRange!.end)
          .toList();
    }

    int rank(FinanceVehicle v) {
      final i = bodyCats.indexOf((v.category ?? '').toUpperCase());
      return i < 0 ? bodyCats.length : i;
    }

    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : (a.minPrice ?? 0).compareTo(b.minPrice ?? 0);
    });
    return list;
  }

  /// Price bounds of the current brand lineup (for the range slider).
  (double, double) priceBounds(String wantedDbId) {
    final prices = brandVehicles(wantedDbId)
        .map((v) => v.minPrice ?? 0)
        .where((p) => p > 0)
        .toList();
    if (prices.isEmpty) return (0, 0);
    prices.sort();
    return (prices.first, prices.last);
  }

  FinanceState copyWith({
    FinanceStatus? status,
    List<FinanceBank>? banks,
    FinanceFilters? filters,
    int? activeBankIndex,
    List<FinanceVehicle>? vehicles,
    bool? vehiclesLoading,
    FinanceMode? mode,
    double? monthly,
    int? period,
    double? lastBatch,
    bool? monthlyTouched,
    double? Function()? budget,
    String? Function()? modelGroupId,
    String? Function()? refineCategory,
    Set<String>? refineGroupIds,
    RangeValues? Function()? priceRange,
  }) =>
      FinanceState(
        status: status ?? this.status,
        banks: banks ?? this.banks,
        filters: filters ?? this.filters,
        activeBankIndex: activeBankIndex ?? this.activeBankIndex,
        vehicles: vehicles ?? this.vehicles,
        vehiclesLoading: vehiclesLoading ?? this.vehiclesLoading,
        mode: mode ?? this.mode,
        monthly: monthly ?? this.monthly,
        period: period ?? this.period,
        lastBatch: lastBatch ?? this.lastBatch,
        monthlyTouched: monthlyTouched ?? this.monthlyTouched,
        budget: budget == null ? this.budget : budget(),
        modelGroupId: modelGroupId == null ? this.modelGroupId : modelGroupId(),
        refineCategory:
            refineCategory == null ? this.refineCategory : refineCategory(),
        refineGroupIds: refineGroupIds ?? this.refineGroupIds,
        priceRange: priceRange == null ? this.priceRange : priceRange(),
      );

  @override
  List<Object?> get props => [
        status, banks, filters, activeBankIndex, vehicles, vehiclesLoading,
        mode, monthly, period, lastBatch, monthlyTouched, budget,
        modelGroupId, refineCategory, refineGroupIds, priceRange,
      ];
}

/// Finance page driver — loads banks + filters once, refetches the priced
/// lineup whenever the financier changes (website behavior), and holds every
/// filter/slider so the whole page stays stateless.
final class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit(this._repo) : super(const FinanceState()) {
    load();
  }

  final FinanceRepository _repo;
  final budgetCtrl = TextEditingController();

  Future<void> load() async {
    emit(state.copyWith(status: FinanceStatus.loading));
    final banks = await _repo.banks();
    final filters = await _repo.filters();
    if (isClosed) return;
    if (banks.isEmpty) {
      emit(state.copyWith(status: FinanceStatus.error));
      return;
    }
    emit(state.copyWith(
      status: FinanceStatus.ready,
      banks: banks,
      filters: filters,
      activeBankIndex: 0,
      period: banks.first.defaultFinancePeriod,
    ));
    await _loadVehicles(banks.first);
  }

  Future<void> _loadVehicles(FinanceBank bank) async {
    if ((bank.priceListTypeId ?? '').isEmpty) return;
    emit(state.copyWith(vehiclesLoading: true));
    final cars = await _repo.vehiclesByBank(bank.priceListTypeId!);
    if (isClosed) return;
    emit(state.copyWith(vehicles: cars, vehiclesLoading: false));
  }

  void selectBank(int index) {
    final bank = state.banks.elementAtOrNull(index);
    if (bank == null || index == state.activeBankIndex) return;
    emit(state.copyWith(
      activeBankIndex: index,
      period: bank.defaultFinancePeriod,
      priceRange: () => null,
    ));
    _loadVehicles(bank);
  }

  void setMode(FinanceMode mode) => emit(state.copyWith(mode: mode));
  void setMonthly(double v) =>
      emit(state.copyWith(monthly: v, monthlyTouched: true));
  void setPeriod(int v) => emit(state.copyWith(period: v, monthlyTouched: true));
  void setLastBatch(double v) =>
      emit(state.copyWith(lastBatch: v, monthlyTouched: true));
  void setBudget(String raw) =>
      emit(state.copyWith(budget: () => double.tryParse(raw.trim())));
  void selectModelGroup(String? id) =>
      emit(state.copyWith(modelGroupId: () => id));
  void refineByCategory(String? cat) => emit(state.copyWith(
      refineCategory: () => state.refineCategory == cat ? null : cat));
  void toggleRefineGroup(String id) {
    final next = Set<String>.from(state.refineGroupIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    emit(state.copyWith(refineGroupIds: next));
  }

  void setPriceRange(RangeValues r) =>
      emit(state.copyWith(priceRange: () => r));

  @override
  Future<void> close() {
    budgetCtrl.dispose();
    return super.close();
  }
}
