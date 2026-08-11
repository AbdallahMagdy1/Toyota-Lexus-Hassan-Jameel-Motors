import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/offers_repository.dart';
import '../domain/offer_models.dart';

enum OffersStatus { loading, ready, error }

final class OffersState extends Equatable {
  const OffersState({
    this.status = OffersStatus.loading,
    this.offers = const [],
    this.types = const [],
    this.selectedTypeId,
    this.now,
  });

  final OffersStatus status;
  final List<SiteOffer> offers;
  final List<OfferType> types;

  /// null = all types (the website's "All" chip).
  final int? selectedTypeId;

  /// Ticks every second — drives the live countdown tiles.
  final DateTime? now;

  /// Types that actually have visible offers, in catalog order — each becomes
  /// a section exactly like the website's /offers page.
  List<(OfferType, List<SiteOffer>)> sections(String? wantedDbId) {
    final visible =
        offers.where((o) => o.visibleForBrand(wantedDbId)).toList();
    final out = <(OfferType, List<SiteOffer>)>[];
    for (final t in types) {
      if (selectedTypeId != null && t.id != selectedTypeId) continue;
      final group = visible.where((o) => o.typeId == t.id).toList();
      if (group.isNotEmpty) out.add((t, group));
    }
    return out;
  }

  OffersState copyWith({
    OffersStatus? status,
    List<SiteOffer>? offers,
    List<OfferType>? types,
    int? Function()? selectedTypeId,
    DateTime? now,
  }) =>
      OffersState(
        status: status ?? this.status,
        offers: offers ?? this.offers,
        types: types ?? this.types,
        selectedTypeId:
            selectedTypeId == null ? this.selectedTypeId : selectedTypeId(),
        now: now ?? this.now,
      );

  @override
  List<Object?> get props => [status, offers, types, selectedTypeId, now];
}

/// Loads the offers catalog once and ticks a 1s clock for the countdowns
/// (the website runs the same setInterval per card).
final class OffersCubit extends Cubit<OffersState> {
  OffersCubit(this._repo, {int? initialTypeId})
      : super(OffersState(selectedTypeId: initialTypeId, now: DateTime.now())) {
    load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) emit(state.copyWith(now: DateTime.now()));
    });
  }

  final OffersRepository _repo;
  Timer? _ticker;

  Future<void> load() async {
    emit(state.copyWith(status: OffersStatus.loading));
    final (offers, types) = await _repo.all();
    if (isClosed) return;
    if (offers.isEmpty && types.isEmpty) {
      emit(state.copyWith(status: OffersStatus.error));
    } else {
      emit(state.copyWith(
          status: OffersStatus.ready, offers: offers, types: types));
    }
  }

  void selectType(int? typeId) =>
      emit(state.copyWith(selectedTypeId: () => typeId));

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}

/* ───────────────────────── Offer detail ───────────────────────── */

enum OfferDetailStatus { loading, ready, error }

final class OfferDetailState extends Equatable {
  const OfferDetailState({
    this.status = OfferDetailStatus.loading,
    this.detail,
    this.activePackageId,
    this.selectedVehicle,
  });

  final OfferDetailStatus status;
  final OfferDetail? detail;
  final int? activePackageId;

  /// The supported vehicle picked on the rail — the single source of truth
  /// for the request: the CTA stays disabled until one is chosen (when the
  /// offer lists supported vehicles) and the form payload is built from it.
  final OfferVehicle? selectedVehicle;

  /// Vehicles filtered by active package + brand, like the website detail page.
  List<OfferVehicle> vehicles(String? wantedDbId) {
    var list = detail?.supportedVehicles ?? const <OfferVehicle>[];
    if (activePackageId != null) {
      list = list.where((v) => v.packageId == activePackageId).toList();
    }
    if (wantedDbId != null) {
      final branded = list.where((v) => v.brandId == wantedDbId).toList();
      if (branded.isNotEmpty) list = branded;
    }
    return list;
  }

  OfferDetailState copyWith({
    OfferDetailStatus? status,
    OfferDetail? detail,
    int? Function()? activePackageId,
    OfferVehicle? Function()? selectedVehicle,
  }) =>
      OfferDetailState(
        status: status ?? this.status,
        detail: detail ?? this.detail,
        activePackageId:
            activePackageId == null ? this.activePackageId : activePackageId(),
        selectedVehicle:
            selectedVehicle == null ? this.selectedVehicle : selectedVehicle(),
      );

  @override
  List<Object?> get props => [status, detail, activePackageId, selectedVehicle];
}

final class OfferDetailCubit extends Cubit<OfferDetailState> {
  OfferDetailCubit(this._repo, String slug) : super(const OfferDetailState()) {
    _load(slug);
  }

  final OffersRepository _repo;

  Future<void> _load(String slug) async {
    final d = await _repo.detail(slug);
    if (isClosed) return;
    if (d == null) {
      emit(state.copyWith(status: OfferDetailStatus.error));
    } else {
      emit(OfferDetailState(
        status: OfferDetailStatus.ready,
        detail: d,
        activePackageId: d.packages.isNotEmpty ? d.packages.first.id : null,
      ));
    }
  }

  void selectPackage(int? id) {
    // Switching packages re-filters the rail; drop a selection that is no
    // longer visible so the CTA can't submit a hidden vehicle.
    final v = state.selectedVehicle;
    final drop = v != null && id != null && v.packageId != id;
    emit(state.copyWith(
      activePackageId: () => id,
      selectedVehicle: drop ? () => null : null,
    ));
  }

  /// Rail tap — exactly one supported vehicle selected at a time.
  void selectVehicle(OfferVehicle v) =>
      emit(state.copyWith(selectedVehicle: () => v));
}
