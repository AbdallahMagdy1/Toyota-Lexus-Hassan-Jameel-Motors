import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/data/home_repository.dart';
import '../../home/domain/home_models.dart';

part 'online_store_state.dart';

/// Online store catalog + the website's /online filters (search, price up
/// to, categories, color). Data comes from the warm home aggregate — one
/// call carries the catalog AND the carGroupId→category map.
final class OnlineStoreCubit extends Cubit<OnlineStoreState> {
  OnlineStoreCubit(this._homeRepo, {required String brandKey})
      : _brandKey = brandKey,
        super(const OnlineStoreState()) {
    load();
  }

  final HomeRepository _homeRepo;
  final String _brandKey;

  Future<void> load() async {
    emit(state.copyWith(status: StoreStatus.loading));
    final feed = await _homeRepo.fetch(_brandKey);
    if (isClosed) return;
    if (feed == null) {
      emit(state.copyWith(status: StoreStatus.error));
      return;
    }
    // Brand-filter the catalog (the site does it by domain; the app by the
    // active theme brand) using the ERP brand id carried on each row.
    final brandIds = feed.vehicles
        .map((v) => v.brandId?.trim())
        .whereType<String>()
        .toSet();
    final all = feed.onlineVehicles
        .where((v) =>
            brandIds.isEmpty ||
            v.brandId == null ||
            brandIds.contains(v.brandId!.trim()))
        .toList();

    // carGroupId → body-type bucket (SEDAN/SUV/…) from the models slider.
    final categoryOf = <String, String>{};
    for (final v in feed.vehicles) {
      final g = v.carGroupId?.trim();
      final c = v.category;
      if (g != null && g.isNotEmpty && c != null && c.isNotEmpty) {
        categoryOf.putIfAbsent(g, () => c);
      }
    }

    final maxPrice = all.fold<double>(
        0, (m, v) => (v.minPrice ?? 0) > m ? v.minPrice! : m);

    emit(OnlineStoreState(
      status: StoreStatus.ready,
      vehicles: all,
      categoryOf: categoryOf,
      priceCeiling: maxPrice,
      maxPrice: maxPrice,
    ));
  }

  void setQuery(String q) => emit(state.copyWith(query: q));

  void setMaxPrice(double v) => emit(state.copyWith(maxPrice: v));

  void toggleCategory(String category) {
    final next = Set<String>.from(state.categories);
    next.contains(category) ? next.remove(category) : next.add(category);
    emit(state.copyWith(categories: next));
  }

  void setColor(String? colorName) =>
      emit(state.copyWith(colorName: colorName, clearColor: colorName == null));

  void clearFilters() => emit(state.copyWith(
        query: '',
        maxPrice: state.priceCeiling,
        categories: const {},
        clearColor: true,
      ));
}
