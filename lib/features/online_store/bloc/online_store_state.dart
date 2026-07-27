part of 'online_store_cubit.dart';

enum StoreStatus { loading, ready, error }

final class OnlineStoreState extends Equatable {
  const OnlineStoreState({
    this.status = StoreStatus.loading,
    this.vehicles = const [],
    this.categoryOf = const {},
    this.priceCeiling = 0,
    this.query = '',
    this.maxPrice = 0,
    this.categories = const {},
    this.colorName,
  });

  final StoreStatus status;
  final List<OnlineVehicle> vehicles;
  final Map<String, String> categoryOf; // carGroupId → SEDAN/SUV/…
  final double priceCeiling;
  final String query;
  final double maxPrice;
  final Set<String> categories;
  final String? colorName;

  String? categoryFor(OnlineVehicle v) => categoryOf[v.carGroupId?.trim()];

  List<String> get availableCategories {
    final out = <String>[];
    for (final v in vehicles) {
      final c = categoryFor(v);
      if (c != null && !out.contains(c)) out.add(c);
    }
    return out;
  }

  List<String> get availableColors {
    final out = <String>[];
    for (final v in vehicles) {
      for (final c in v.uniqueColors) {
        final n = (c.nameEn ?? '').trim();
        if (n.isNotEmpty && !out.contains(n)) out.add(n);
      }
    }
    out.sort();
    return out;
  }

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      categories.isNotEmpty ||
      colorName != null ||
      (priceCeiling > 0 && maxPrice < priceCeiling);

  List<OnlineVehicle> get filtered {
    final q = query.trim().toLowerCase();
    return vehicles.where((v) {
      if (q.isNotEmpty &&
          !'${v.groupEn} ${v.groupAr} ${v.year}'.toLowerCase().contains(q)) {
        return false;
      }
      if (priceCeiling > 0 && (v.minPrice ?? 0) > maxPrice) return false;
      if (categories.isNotEmpty && !categories.contains(categoryFor(v))) {
        return false;
      }
      if (colorName != null &&
          !v.uniqueColors.any((c) => (c.nameEn ?? '').trim() == colorName)) {
        return false;
      }
      return true;
    }).toList();
  }

  OnlineStoreState copyWith({
    StoreStatus? status,
    List<OnlineVehicle>? vehicles,
    Map<String, String>? categoryOf,
    double? priceCeiling,
    String? query,
    double? maxPrice,
    Set<String>? categories,
    String? colorName,
    bool clearColor = false,
  }) =>
      OnlineStoreState(
        status: status ?? this.status,
        vehicles: vehicles ?? this.vehicles,
        categoryOf: categoryOf ?? this.categoryOf,
        priceCeiling: priceCeiling ?? this.priceCeiling,
        query: query ?? this.query,
        maxPrice: maxPrice ?? this.maxPrice,
        categories: categories ?? this.categories,
        colorName: clearColor ? null : (colorName ?? this.colorName),
      );

  @override
  List<Object?> get props =>
      [status, vehicles, categoryOf, priceCeiling, query, maxPrice, categories, colorName];
}
