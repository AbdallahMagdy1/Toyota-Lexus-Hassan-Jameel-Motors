import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/domain/home_models.dart';
import '../data/vehicles_repository.dart';
import '../domain/vehicle_models.dart';

/// One model's sheet: Overview / Gallery / Specs / Features / Comparison —
/// everything the website vehicle page loads, fetched in parallel.
final class ModelSheetState extends Equatable {
  const ModelSheetState({
    this.loading = true,
    this.detail,
    this.trims = const [],
    this.colors = const [],
    this.colorImages = const [],
    this.features = const [],
    this.gallery = const [],
    this.equipments = const [],
    this.tab = 0,
    this.colorIndex = 0,
    this.trimA = 0,
    this.trimB = 1,
  });

  final bool loading;
  final SliderVehicle? detail; // carries the marketing description
  final List<VehicleTrim> trims;
  final List<VehicleColor> colors;
  final List<VehicleColorImage> colorImages;
  final List<VehicleFeature> features;
  final List<VehicleGalleryItem> gallery;
  final List<EquipmentRow> equipments;
  final int tab;
  final int colorIndex;
  final int trimA; // comparison selections
  final int trimB;

  VehicleColor? get color =>
      colors.isEmpty ? null : colors[colorIndex.clamp(0, colors.length - 1)];

  /// Car image for the selected color, falling back to the catalog image.
  String? imageFor(String? fallback) {
    final code = color?.exteriorCode;
    if (code != null && code.isNotEmpty) {
      for (final ci in colorImages) {
        if (ci.colorCode == code && (ci.imageUrl ?? '').isNotEmpty) {
          return ci.imageUrl;
        }
      }
    }
    return fallback;
  }

  ModelSheetState copyWith({
    bool? loading,
    SliderVehicle? detail,
    List<VehicleTrim>? trims,
    List<VehicleColor>? colors,
    List<VehicleColorImage>? colorImages,
    List<VehicleFeature>? features,
    List<VehicleGalleryItem>? gallery,
    List<EquipmentRow>? equipments,
    int? tab,
    int? colorIndex,
    int? trimA,
    int? trimB,
  }) =>
      ModelSheetState(
        loading: loading ?? this.loading,
        detail: detail ?? this.detail,
        trims: trims ?? this.trims,
        colors: colors ?? this.colors,
        colorImages: colorImages ?? this.colorImages,
        features: features ?? this.features,
        gallery: gallery ?? this.gallery,
        equipments: equipments ?? this.equipments,
        tab: tab ?? this.tab,
        colorIndex: colorIndex ?? this.colorIndex,
        trimA: trimA ?? this.trimA,
        trimB: trimB ?? this.trimB,
      );

  @override
  List<Object?> get props => [
        loading, detail, trims, colors, colorImages, features, gallery,
        equipments, tab, colorIndex, trimA, trimB,
      ];
}

final class ModelSheetCubit extends Cubit<ModelSheetState> {
  ModelSheetCubit(this._repo, this.vehicle) : super(const ModelSheetState()) {
    _load();
  }

  final VehiclesRepository _repo;
  final SliderVehicle vehicle;

  Future<void> _load() async {
    final slug = vehicle.slug;
    if (slug == null) {
      emit(state.copyWith(loading: false));
      return;
    }
    final results = await Future.wait<Object?>([
      _repo.detail(slug),
      _repo.trims(slug),
      _repo.colors(slug),
      _repo.colorImages(slug),
      _repo.features(slug),
      _repo.gallery(slug),
      _repo.equipments(slug),
    ]);
    if (isClosed) return;
    emit(state.copyWith(
      loading: false,
      detail: results[0] as SliderVehicle?,
      trims: results[1] as List<VehicleTrim>,
      colors: results[2] as List<VehicleColor>,
      colorImages: results[3] as List<VehicleColorImage>,
      features: results[4] as List<VehicleFeature>,
      gallery: results[5] as List<VehicleGalleryItem>,
      equipments: results[6] as List<EquipmentRow>,
    ));
  }

  void setTab(int i) => emit(state.copyWith(tab: i));

  void setColorIndex(int i) {
    if (i < 0 || i >= state.colors.length) return;
    emit(state.copyWith(colorIndex: i));
  }

  void setTrimA(int i) => emit(state.copyWith(trimA: i));
  void setTrimB(int i) => emit(state.copyWith(trimB: i));
}
