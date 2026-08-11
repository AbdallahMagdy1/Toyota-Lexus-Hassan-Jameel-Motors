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
    this.trimIndex = 0,
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
  final int trimIndex; // active trim (overview + specs)
  final int trimA; // comparison selections
  final int trimB;

  VehicleTrim? get activeTrim =>
      trims.isEmpty ? null : trims[trimIndex.clamp(0, trims.length - 1)];

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
    int? trimIndex,
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
        trimIndex: trimIndex ?? this.trimIndex,
        trimA: trimA ?? this.trimA,
        trimB: trimB ?? this.trimB,
      );

  @override
  List<Object?> get props => [
        loading, detail, trims, colors, colorImages, features, gallery,
        equipments, tab, colorIndex, trimIndex, trimA, trimB,
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
    final images = results[3] as List<VehicleColorImage>;
    emit(state.copyWith(
      loading: false,
      detail: results[0] as SliderVehicle?,
      trims: results[1] as List<VehicleTrim>,
      colors: cleanColors(results[2] as List<VehicleColor>, images),
      colorImages: images,
      features: results[4] as List<VehicleFeature>,
      gallery: results[5] as List<VehicleGalleryItem>,
      equipments: results[6] as List<EquipmentRow>,
    ));
  }

  /// The website's exact color pipeline (VehicleDetail.tsx):
  /// 1. ColorID is the combined "EXT/INT" code, so one exterior shows once
  ///    per interior — dedupe by exterior code, first row wins.
  /// 2. Keep only colors whose exterior code actually has a car image;
  ///    fall back to the full deduped list if that filter empties it.
  static List<VehicleColor> cleanColors(
      List<VehicleColor> raw, List<VehicleColorImage> images) {
    final seen = <String, VehicleColor>{};
    for (final c in raw) {
      final key =
          (c.exteriorCode ?? c.colorId.split('/').first).trim().toLowerCase();
      if (key.isEmpty) continue;
      seen.putIfAbsent(key, () => c);
    }
    var list = seen.values.toList();
    final codes = images
        .map((i) => i.colorCode)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet();
    if (codes.isNotEmpty) {
      final filtered = list
          .where((c) =>
              codes.contains(c.exteriorCode ?? c.colorId.split('/').first))
          .toList();
      if (filtered.isNotEmpty) list = filtered;
    }
    return list;
  }

  void setTab(int i) => emit(state.copyWith(tab: i));

  void setColorIndex(int i) {
    if (i < 0 || i >= state.colors.length) return;
    emit(state.copyWith(colorIndex: i));
  }

  void setTrimA(int i) => emit(state.copyWith(trimA: i));
  void setTrimB(int i) => emit(state.copyWith(trimB: i));

  /// Selecting a trim also refetches its color palette (website behavior).
  void selectTrim(int i) {
    if (i < 0 || i >= state.trims.length || i == state.trimIndex) return;
    emit(state.copyWith(trimIndex: i));
    loadColorsForTrim(state.trims[i]);
  }

  /// Colors follow the selected trim (website behavior): refetch the trim's
  /// palette + images, keep the picked exterior code selected when it still
  /// exists, and never wipe a working palette with an empty response.
  Future<void> loadColorsForTrim(VehicleTrim trim) async {
    final slug = trim.slug;
    if (slug == null || slug.isEmpty) return;
    final keepCode = state.color?.exteriorCode ??
        state.color?.colorId.split('/').first;
    final results = await Future.wait<Object?>([
      _repo.colors(slug),
      _repo.colorImages(slug),
    ]);
    if (isClosed) return;
    final rawColors = results[0] as List<VehicleColor>;
    final images = results[1] as List<VehicleColorImage>;
    if (rawColors.isEmpty || images.isEmpty) return;
    final cleaned = cleanColors(rawColors, images);
    if (cleaned.isEmpty) return;
    var idx = cleaned.indexWhere((c) =>
        (c.exteriorCode ?? c.colorId.split('/').first) == keepCode);
    if (idx < 0) idx = 0;
    emit(state.copyWith(
        colors: cleaned, colorImages: images, colorIndex: idx));
  }
}
