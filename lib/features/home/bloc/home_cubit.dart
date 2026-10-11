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
final class HomeCubit extends Cubit<HomeState> with WidgetsBindingObserver {
  HomeCubit(this._repo, {required String brandKey})
      : _brandKey = brandKey,
        super(const HomeState()) {
    WidgetsBinding.instance.addObserver(this);
    load();
    _autoPlay = Timer.periodic(const Duration(seconds: 5), (_) => _advanceHero());
  }

  final HomeRepository _repo;
  final String _brandKey;
  final PageController heroController = PageController();
  Timer? _autoPlay;

  Future<void> load({bool fresh = false}) async {
    emit(state.copyWith(status: HomeStatus.loading));
    final feed = await _repo.fetch(_brandKey, fresh: fresh);
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

  /// Pull-to-refresh forces a network fetch (bypasses the SWR disk cache), so
  /// live inventory — e.g. a car that just sold — is reflected immediately
  /// instead of lingering behind the cached payload.
  Future<void> refresh() => load(fresh: true);

  /// When the app returns to the foreground, silently refetch the feed fresh so
  /// the home rails self-heal (a sold car drops off on its own) — without a
  /// loading flash or disturbing the user's parts/protection selections.
  Future<void> _refreshOnResume() async {
    final feed = await _repo.fetch(_brandKey, fresh: true);
    if (isClosed || feed == null) return;
    emit(state.copyWith(status: HomeStatus.ready, feed: feed));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) _refreshOnResume();
  }

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
    WidgetsBinding.instance.removeObserver(this);
    _autoPlay?.cancel();
    heroController.dispose();
    return super.close();
  }
}
