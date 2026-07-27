import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/protection_repository.dart';
import '../domain/protection_models.dart';

enum ProtectionStatus { loading, ready, error }

final class ProtectionState extends Equatable {
  const ProtectionState({
    this.status = ProtectionStatus.loading,
    this.groups = const [],
    this.models = const [],
    this.groupId,
    this.modelId,
    this.servicesLoading = false,
    this.result,
  });

  final ProtectionStatus status;
  final List<MaintGroup> groups;
  final List<MaintModel> models;
  final String? groupId;
  final String? modelId;
  final bool servicesLoading;
  final ProtectionResult? result;

  /// Models of the picked group — website dedupe: one row per productTypeID,
  /// preferring rows with carCategory populated, tie-break latest year.
  List<MaintModel> modelOptions() {
    if (groupId == null) return const [];
    final byType = <String, MaintModel>{};
    for (final m in models.where((m) => m.groupId == groupId)) {
      final key = m.id ?? '';
      if (key.isEmpty) continue;
      final prev = byType[key];
      if (prev == null) {
        byType[key] = m;
        continue;
      }
      final mHasCat = (m.carCategory ?? '').isNotEmpty;
      final prevHasCat = (prev.carCategory ?? '').isNotEmpty;
      if (mHasCat && !prevHasCat) {
        byType[key] = m;
      } else if (mHasCat == prevHasCat &&
          (int.tryParse(m.year ?? '') ?? 0) >
              (int.tryParse(prev.year ?? '') ?? 0)) {
        byType[key] = m;
      }
    }
    return byType.values.toList();
  }

  MaintModel? get selectedModel =>
      modelOptions().where((m) => m.id == modelId).firstOrNull;

  ProtectionState copyWith({
    ProtectionStatus? status,
    List<MaintGroup>? groups,
    List<MaintModel>? models,
    String? Function()? groupId,
    String? Function()? modelId,
    bool? servicesLoading,
    ProtectionResult? Function()? result,
  }) =>
      ProtectionState(
        status: status ?? this.status,
        groups: groups ?? this.groups,
        models: models ?? this.models,
        groupId: groupId == null ? this.groupId : groupId(),
        modelId: modelId == null ? this.modelId : modelId(),
        servicesLoading: servicesLoading ?? this.servicesLoading,
        result: result == null ? this.result : result(),
      );

  @override
  List<Object?> get props =>
      [status, groups, models, groupId, modelId, servicesLoading, result];
}

/// Protection & shading driver — the website's two pickers verbatim:
/// groups for the brand (year ≥ 2025, dedupe by name keeping highest year),
/// then models per group; picking a model resolves the package catalog.
final class ProtectionCubit extends Cubit<ProtectionState> {
  ProtectionCubit(this._repo, {required String brandDbId})
      : _brandDbId = brandDbId,
        super(const ProtectionState()) {
    load();
  }

  final ProtectionRepository _repo;
  final String _brandDbId;

  Future<void> load() async {
    emit(state.copyWith(status: ProtectionStatus.loading));
    final (groups, models) = await _repo.settings();
    if (isClosed) return;
    if (groups.isEmpty) {
      emit(state.copyWith(status: ProtectionStatus.error));
      return;
    }

    // Website group rules: this brand, drop "test", year ≥ 2025, dedupe by
    // description keeping the highest-year row.
    final byName = <String, MaintGroup>{};
    for (final g in groups) {
      if (g.brandId != _brandDbId) continue;
      final name = (g.nameEn ?? g.nameAr ?? '').trim();
      if (name.isEmpty || name.toLowerCase().contains('test')) continue;
      if ((int.tryParse(g.year ?? '') ?? 0) < 2025) continue;
      final prev = byName[name.toUpperCase()];
      if (prev == null ||
          (int.tryParse(g.year ?? '') ?? 0) >
              (int.tryParse(prev.year ?? '') ?? 0)) {
        byName[name.toUpperCase()] = g;
      }
    }
    final filtered = byName.values.toList()
      ..sort((a, b) => a.name('en').compareTo(b.name('en')));

    emit(state.copyWith(
      status: ProtectionStatus.ready,
      groups: filtered,
      models: models,
    ));
  }

  void selectGroup(String? id) => emit(state.copyWith(
        groupId: () => id,
        modelId: () => null,
        result: () => null,
      ));

  Future<void> selectModel(String? id) async {
    emit(state.copyWith(modelId: () => id, result: () => null));
    if (id == null) return;
    emit(state.copyWith(servicesLoading: true));
    final result = await _repo.protectionByModel(id, _brandDbId);
    if (isClosed) return;
    emit(state.copyWith(servicesLoading: false, result: () => result));
  }

  /// "لسيارتي" — resolve the catalog straight from a garage car's
  /// productTypeID, skipping the group/model pickers.
  Future<void> selectByProductType(String type) async {
    emit(state.copyWith(
        groupId: () => null,
        modelId: () => type,
        result: () => null,
        servicesLoading: true));
    final result = await _repo.protectionByModel(type, _brandDbId);
    if (isClosed) return;
    emit(state.copyWith(servicesLoading: false, result: () => result));
  }
}
