import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
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
    emit(state.copyWith(loading: false, vehicles: feed?.vehicles ?? const []));
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

final class _ModelsView extends StatelessWidget {
  const _ModelsView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ModelsCubit>();
    final state = context.watch<ModelsCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.rs(8), context.rs(6), context.rs(8), 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => appBack(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                Expanded(
                  child: Text(
                    t.homeMeetTheModels,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: context.rf(17), fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          SizedBox(height: context.rs(8)),
          if (state.loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            FilterChipsRow(
              labels: [t.homeAll, ...state.categories],
              selectedIndex: state.category == null
                  ? 0
                  : state.categories.indexOf(state.category!) + 1,
              onSelected: (i) =>
                  cubit.setCategory(i == 0 ? null : state.categories[i - 1]),
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
                  ? Center(child: Text(t.storeNoResults))
                  : PageView.builder(
                      key: ValueKey('models-${state.category}'),
                      controller: cubit.pageController,
                      itemCount: state.filtered.length,
                      onPageChanged: cubit.onPage,
                      itemBuilder: (context, i) => Padding(
                        padding: EdgeInsets.only(bottom: context.rs(24)),
                        child: _ModelCard(vehicle: state.filtered[i], lang: lang)
                            .animate()
                            .fadeIn(duration: 260.ms)
                            .scale(
                                begin: const Offset(0.97, 0.97),
                                end: const Offset(1, 1),
                                duration: 260.ms,
                                curve: Curves.easeOut),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The reference's big dark editorial card: brand small, model huge muted,
/// specs row, car image, price + circular arrow action.
final class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.vehicle, required this.lang});

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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(8)),
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openModelSheet(context, vehicle),
          child: Padding(
            padding: EdgeInsets.all(context.rs(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.brandEn,
                  style: TextStyle(
                    color: fg,
                    fontSize: context.rf(15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${vehicle.name(lang)} ${vehicle.year ?? ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.4),
                    fontSize: context.rf(30),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: context.rs(6)),
                Row(
                  children: [
                    if (vehicle.seatsNumber != null)
                      _SpecChip(
                          icon: Icons.airline_seat_recline_normal_rounded,
                          text: '${vehicle.seatsNumber}',
                          color: fg),
                    if (vehicle.hp != null)
                      _SpecChip(
                          icon: Icons.speed_rounded,
                          text: '${vehicle.hp!.round()} HP',
                          color: fg),
                    if (vehicle.hybrid)
                      _SpecChip(icon: Icons.eco_rounded, text: 'HEV', color: fg),
                  ],
                ),
                // Car image.
                Expanded(
                  child: Hero(
                    tag: 'model-${vehicle.slug}',
                    child: HomeImage(
                      url: vehicle.image(lang),
                      fit: BoxFit.contain,
                      logicalWidth: MediaQuery.sizeOf(context).width,
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
                              fontSize: context.rf(11),
                            ),
                          ),
                          PriceText(
                            price:
                                vehicle.showPrice ? vehicle.minPrice : null,
                            currency: t.currency,
                            contactForPrice: t.homeContactForPrice,
                            fontSize: context.rf(19),
                            color: fg,
                          ),
                        ],
                      ),
                    ),
                    // Circular brand-colored action, like the reference's ↗.
                    Material(
                      color: arrowBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => openModelSheet(context, vehicle),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: context.rs(48),
                          height: context.rs(48),
                          child: Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.north_west_rounded
                                : Icons.north_east_rounded,
                            size: 20,
                            color: arrowFg,
                          ),
                        ),
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

final class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: context.rs(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.6)),
          SizedBox(width: context.rs(4)),
          Text(
            text,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: context.rf(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
