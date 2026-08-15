import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/back_header.dart';
import '../../../shared/widgets/pressable.dart';
import '../../home/data/home_repository.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import 'model_sheet.dart';

/// "Meet the models" catalog — the reference's swiper of big editorial
/// cards with the category chips on top.
final class ModelsState extends Equatable {
  const ModelsState({
    this.loading = true,
    this.vehicles = const [],
    this.category,
    this.page = 0,
  });

  final bool loading;
  final List<SliderVehicle> vehicles;
  final String? category;
  final int page;

  List<String> get categories {
    final out = <String>[];
    for (final v in vehicles) {
      final c = v.category;
      if (c != null && c.isNotEmpty && !out.contains(c)) out.add(c);
    }
    return out;
  }

  List<SliderVehicle> get filtered => category == null
      ? vehicles
      : vehicles.where((v) => v.category == category).toList();

  ModelsState copyWith({
    bool? loading,
    List<SliderVehicle>? vehicles,
    String? category,
    bool clearCategory = false,
    int? page,
  }) =>
      ModelsState(
        loading: loading ?? this.loading,
        vehicles: vehicles ?? this.vehicles,
        category: clearCategory ? null : (category ?? this.category),
        page: page ?? this.page,
      );

  @override
  List<Object?> get props => [loading, vehicles, category, page];
}

final class ModelsCubit extends Cubit<ModelsState> {
  ModelsCubit(this._repo, {required String brandKey, String? initialCategory})
      : super(ModelsState(
            category: (initialCategory?.isEmpty ?? true) ? null : initialCategory)) {
    _load(brandKey);
  }

  final HomeRepository _repo;
  final PageController pageController = PageController(viewportFraction: 0.82);

  Future<void> _load(String brandKey) async {
    final feed = await _repo.fetch(brandKey);
    if (isClosed) return;
    // Website arrangement (ModelsCarousel): order by the ERP storeNumber,
    // ties broken by productId — so sedan reads Yaris → Corolla → Camry →
    // Crown, exactly like the site.
    final vehicles = [...?feed?.vehicles]..sort((a, b) {
        final s = (a.storeNumber ?? 1 << 30) - (b.storeNumber ?? 1 << 30);
        return s != 0 ? s : (a.productId ?? '').compareTo(b.productId ?? '');
      });
    emit(state.copyWith(loading: false, vehicles: vehicles));
  }

  void setCategory(String? c) =>
      emit(state.copyWith(category: c, clearCategory: c == null, page: 0));

  void onPage(int i) => emit(state.copyWith(page: i));

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}

final class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  Widget build(BuildContext context) {
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    return BlocProvider(
      key: ValueKey('models-$brandKey-$initialCategory'),
      create: (_) => ModelsCubit(sl(),
          brandKey: brandKey, initialCategory: initialCategory),
      child: const _ModelsView(),
    );
  }
}

/// Canonical section order (website order): sedan → suv → coupes →
/// commercial → the rest as they arrive.
int _categoryRank(String c) {
  final n = c.toLowerCase();
  const order = ['sedan', 'سيدان', 'suv', 'coupe', 'كوبيه', 'commercial',
      'تجاري', 'hybrid', 'هجين', 'van', 'truck'];
  for (var i = 0; i < order.length; i++) {
    if (n.contains(order[i])) return i;
  }
  return order.length;
}

final class _ModelsView extends StatefulWidget {
  const _ModelsView();

  @override
  State<_ModelsView> createState() => _ModelsViewState();
}

final class _ModelsViewState extends State<_ModelsView> {
  /// One-shot: pre-select the first section (sedan) once the catalog loads
  /// — user taps afterwards (including "All") are never overridden.
  bool _autoPicked = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ModelsCubit>();
    final state = context.watch<ModelsCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    // Presentation-only ordering of the category chips.
    final categories = [...state.categories]
      ..sort((a, b) => _categoryRank(a).compareTo(_categoryRank(b)));

    if (!_autoPicked && !state.loading && categories.isNotEmpty) {
      _autoPicked = true;
      if (state.category == null) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => cubit.setCategory(categories.first));
      }
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackHeader(title: t.homeMeetTheModels),
          SizedBox(height: context.rs(8)),
          if (state.loading)
            Expanded(
              child: Shimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: context.rs(20)),
                      child: Row(
                        children: [
                          for (final w in [64.0, 84.0, 72.0])
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                  end: context.rs(8)),
                              child: SkeletonBox(
                                  width: context.rs(w),
                                  height: context.rs(34),
                                  radius: 999),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.rs(20)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(context.rs(36), 0,
                            context.rs(36), context.rs(32)),
                        child: const SkeletonBox(
                            width: double.infinity, radius: 26),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Sections lead (sedan first); "All" sits at the END of the row.
            FilterChipsRow(
              labels: [...categories, t.homeAll],
              selectedIndex: state.category == null
                  ? categories.length
                  : categories.indexOf(state.category!),
              onSelected: (i) => cubit.setCategory(
                  i == categories.length ? null : categories[i]),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(20), context.rs(20), context.rs(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.sheetSelectYourCar,
                      style: TextStyle(
                          fontSize: context.rf(18), fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${state.filtered.length}',
                    style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.filtered.isEmpty
                  ? AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: t.storeNoResults,
                    )
                  // 2-column grid (3 on tablets) instead of the old pager.
                  : GridView.builder(
                      key: ValueKey('models-${state.category}'),
                      padding: EdgeInsets.fromLTRB(context.rs(16),
                          context.rs(4), context.rs(16), context.rs(40)),
                      cacheExtent: 800,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.isTablet ? 3 : 2,
                        mainAxisSpacing: context.rs(12),
                        crossAxisSpacing: context.rs(12),
                        childAspectRatio: 0.8,
                      ),
                      itemCount: state.filtered.length,
                      itemBuilder: (context, i) => RepaintBoundary(
                        child: _ModelGridCard(
                                vehicle: state.filtered[i], lang: lang)
                            .animate(delay: (25 * (i % 6)).ms)
                            .fadeIn(duration: 220.ms),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact grid card — the editorial panel scaled down for the 2-column
/// grid: brand + name on the panel, Hero car image, price + arrow roundel.
final class _ModelGridCard extends StatelessWidget {
  const _ModelGridCard({required this.vehicle, required this.lang});

  final SliderVehicle vehicle;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Light mode = brand-primary panel; dark mode = dark panel.
    final panel = isDark ? const Color(0xFF1A1C21) : scheme.primary;
    final fg = isDark ? Colors.white : scheme.onPrimary;
    final arrowBg = isDark ? scheme.primary : scheme.onPrimary;
    final arrowFg = isDark ? scheme.onPrimary : scheme.primary;

    return Pressable(
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openModelSheet(context, vehicle),
          child: Padding(
            padding: EdgeInsets.all(context.rs(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.brandEn,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.75),
                    fontSize: context.rf(10),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${vehicle.name(lang)} ${vehicle.year ?? ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: context.rf(13.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                // Car image.
                Expanded(
                  child: Hero(
                    tag: 'model-${vehicle.slug}',
                    child: HomeImage(
                      url: vehicle.image(lang),
                      fit: BoxFit.contain,
                      logicalWidth: 220,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.modelsPrice,
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.55),
                              fontSize: context.rf(9),
                            ),
                          ),
                          PriceText(
                            price:
                                vehicle.showPrice ? vehicle.minPrice : null,
                            currency: t.currency,
                            contactForPrice: t.homeContactForPrice,
                            fontSize: context.rf(12.5),
                            color: fg,
                          ),
                        ],
                      ),
                    ),
                    // Circular brand-colored action, like the reference's ↗.
                    Container(
                      width: context.rs(32),
                      height: context.rs(32),
                      decoration:
                          BoxDecoration(color: arrowBg, shape: BoxShape.circle),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.north_west_rounded
                            : Icons.north_east_rounded,
                        size: 15,
                        color: arrowFg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
