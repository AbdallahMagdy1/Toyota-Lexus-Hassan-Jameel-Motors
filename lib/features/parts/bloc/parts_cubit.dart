import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/parts_repository.dart';
import '../domain/parts_models.dart';

enum PartsStatus { loading, ready, error }

/// Sort options: relevance (backend ranking, default), price, part no.
enum PartsSort { relevance, priceDesc, priceAsc, partNo }

final class PartsState extends Equatable {
  const PartsState({
    this.status = PartsStatus.loading,
    this.filters = const PartsFilters(),
    this.banners = const [],
    this.hero,
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.searching = false,
    this.loadingMore = false,
    this.catId,
    this.subCatId,
    this.inStockOnly = false,
    this.sort = PartsSort.relevance,
  });

  final PartsStatus status;
  final PartsFilters filters;
  final List<PartsBanner> banners;
  final PartsHero? hero;
  final List<PartItem> items;
  final int totalCount;
  final int page;
  final bool searching;
  final bool loadingMore;
  final String? catId;
  final String? subCatId;
  final bool inStockOnly;
  final PartsSort sort;

  bool get hasMore => items.length < totalCount;

  PartsState copyWith({
    PartsStatus? status,
    PartsFilters? filters,
    List<PartsBanner>? banners,
    PartsHero? hero,
    List<PartItem>? items,
    int? totalCount,
    int? page,
    bool? searching,
    bool? loadingMore,
    String? Function()? catId,
    String? Function()? subCatId,
    bool? inStockOnly,
    PartsSort? sort,
  }) =>
      PartsState(
        status: status ?? this.status,
        filters: filters ?? this.filters,
        banners: banners ?? this.banners,
        hero: hero ?? this.hero,
        items: items ?? this.items,
        totalCount: totalCount ?? this.totalCount,
        page: page ?? this.page,
        searching: searching ?? this.searching,
        loadingMore: loadingMore ?? this.loadingMore,
        catId: catId == null ? this.catId : catId(),
        subCatId: subCatId == null ? this.subCatId : subCatId(),
        inStockOnly: inStockOnly ?? this.inStockOnly,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [
        status, filters, banners, hero, items, totalCount, page, searching,
        loadingMore, catId, subCatId, inStockOnly, sort,
      ];
}

/// Parts browser driver — filters + hero + banners once, then debounced
/// paged search (350ms) on the ranked App_Parts_Search backend.
final class PartsCubit extends Cubit<PartsState> {
  PartsCubit(this._repo, {required int brandDbId, required String brandKey})
      : super(const PartsState()) {
    searchCtrl.addListener(_onQueryChanged);
    _init(brandDbId, brandKey);
  }

  final PartsRepository _repo;
  final searchCtrl = TextEditingController();
  Timer? _debounce;

  (String?, String) get _sortParams => switch (state.sort) {
        PartsSort.relevance => (null, 'DESC'),
        PartsSort.priceDesc => ('SalesPrice', 'DESC'),
        PartsSort.priceAsc => ('SalesPrice', 'ASC'),
        PartsSort.partNo => ('ProductNo', 'ASC'),
      };

  Future<void> _init(int brandDbId, String brandKey) async {
    final results = await Future.wait([
      _repo.filters(),
      _repo.banners(brandDbId),
      _repo.hero(brandKey),
    ]);
    if (isClosed) return;
    emit(state.copyWith(
      status: PartsStatus.ready,
      filters: results[0] as PartsFilters,
      banners: results[1] as List<PartsBanner>,
      hero: results[2] as PartsHero?,
    ));
    await _search(reset: true);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!isClosed) _search(reset: true);
    });
  }

  Future<void> _search({required bool reset}) async {
    final page = reset ? 1 : state.page + 1;
    emit(state.copyWith(searching: reset, loadingMore: !reset));
    final (sortBy, sortDir) = _sortParams;
    final res = await _repo.search(
      freeText: searchCtrl.text,
      cat: state.catId,
      subCat: state.subCatId,
      inStockOnly: state.inStockOnly,
      pageNumber: page,
      sortBy: sortBy,
      sortDir: sortDir,
    );
    if (isClosed) return;
    emit(state.copyWith(
      items: reset ? res.items : [...state.items, ...res.items],
      totalCount: res.totalCount,
      page: page,
      searching: false,
      loadingMore: false,
    ));
  }

  Future<void> refresh() => _search(reset: true);

  void loadMore() {
    if (state.loadingMore || state.searching || !state.hasMore) return;
    _search(reset: false);
  }

  void selectCategory(String? id) {
    emit(state.copyWith(catId: () => id, subCatId: () => null));
    _search(reset: true);
  }

  void selectSubCategory(String? id) {
    emit(state.copyWith(subCatId: () => id));
    _search(reset: true);
  }

  void toggleInStock(bool v) {
    emit(state.copyWith(inStockOnly: v));
    _search(reset: true);
  }

  void setSort(PartsSort sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    _search(reset: true);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    searchCtrl.dispose();
    return super.close();
  }
}
