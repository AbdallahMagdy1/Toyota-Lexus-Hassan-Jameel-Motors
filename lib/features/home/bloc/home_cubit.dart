import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/home_repository.dart';
import '../domain/home_models.dart';

part 'home_state.dart';

/// Owns the whole home page: the aggregate feed, the offers-hero auto-play
/// PageController, the vehicles category filter (client-side), the parts
/// category tabs and the protection model picker (both async).
final class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repo, {required String brandKey})
      : _brandKey = brandKey,
        super(const HomeState()) {
    load();
    _autoPlay = Timer.periodic(const Duration(seconds: 5), (_) => _advanceHero());
  }

  final HomeRepository _repo;
  final String _brandKey;
  final PageController heroController = PageController();
  Timer? _autoPlay;

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading));
    final feed = await _repo.fetch(_brandKey);
    if (isClosed) return;
    if (feed == null) {
      emit(state.copyWith(status: HomeStatus.error));
      return;
    }
    emit(state.copyWith(
      status: HomeStatus.ready,
      feed: feed,
      parts: feed.spareParts,
    ));
  }

  Future<void> refresh() => load();

  void _advanceHero() {
    final count = state.feed.vehicleOffers.length + state.feed.maintenanceOffers.length;
    if (count < 2 || !heroController.hasClients) return;
    final next = (state.heroIndex + 1) % count;
    heroController.animateToPage(
      next,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  void onHeroChanged(int index) => emit(state.copyWith(heroIndex: index));

  void selectVehicleCategory(String? category) =>
      emit(state.copyWith(vehicleCategory: category, clearVehicleCategory: category == null));

  Future<void> selectPartsCategory(String? categoryId) async {
    // Switching the main category resets the sub-category tab.
    emit(state.copyWith(
      partsCategoryId: categoryId,
      clearPartsCategory: categoryId == null,
      clearPartsSubCategory: true,
      partsLoading: true,
    ));
    final parts = categoryId == null
        ? state.feed.spareParts
        : await _repo.partsByCategory(categoryId);
    if (isClosed) return;
    emit(state.copyWith(parts: parts, partsLoading: false));
  }

  Future<void> selectPartsSubCategory(String? subCategoryId) async {
    final catId = state.partsCategoryId;
    if (catId == null) return;
    emit(state.copyWith(
      partsSubCategoryId: subCategoryId,
      clearPartsSubCategory: subCategoryId == null,
      partsLoading: true,
    ));
    final parts =
        await _repo.partsByCategory(catId, subCategoryId: subCategoryId);
    if (isClosed) return;
    emit(state.copyWith(parts: parts, partsLoading: false));
  }

  /// Protection picker step 1 — a maintenance group (Camry 2026, LS 2025…).
  void selectProtectionGroup(ProtectionGroup group) {
    emit(state.copyWith(
      protectionGroup: group,
      clearProtectionModel: true,
      protectionServices: const [],
      clearProtectionService: true,
    ));
  }

  /// Protection picker step 2 — a trim; its Id (productTypeID) loads the
  /// packages, exactly like the website's protection-by-model call.
  Future<void> selectProtectionModel(ProtectionModel model) async {
    final typeId = model.id;
    if (typeId == null || typeId.isEmpty) return;
    emit(state.copyWith(protectionModel: model, protectionLoading: true));
    final services =
        await _repo.protectionByModel(typeId, state.protectionGroup?.brandId);
    if (isClosed) return;
    emit(state.copyWith(
      protectionServices: services,
      protectionService: services.isEmpty ? null : services.first,
      clearProtectionService: services.isEmpty,
      protectionLoading: false,
    ));
  }

  void selectProtectionService(ProtectionService s) =>
      emit(state.copyWith(protectionService: s));

  @override
  Future<void> close() {
    _autoPlay?.cancel();
    heroController.dispose();
    return super.close();
  }
}
