import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../../cart/bloc/cart_cubit.dart';
import '../../cart/domain/cart_item.dart';
import '../bloc/collections_cubits.dart';
import '../bloc/online_store_cubit.dart';
import 'car_sheet.dart';
import 'widgets/filter_drawer.dart';

/// Online car store — the website's /online grid with the sidebar filters
/// moved into a trailing drawer, and the car detail as a hero bottom sheet.
final class OnlineStoreScreen extends StatelessWidget {
  const OnlineStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    return BlocProvider(
      key: ValueKey('store-$brandKey'),
      create: (_) => OnlineStoreCubit(sl(), brandKey: brandKey),
      child: const _StoreView(),
    );
  }
}

final class _StoreView extends StatelessWidget {
  const _StoreView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<OnlineStoreCubit>().state;
    final cubit = context.read<OnlineStoreCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header: back + title + filter button (badge when filters active).
          Padding(
            padding: EdgeInsets.fromLTRB(context.rs(8), context.rs(6), context.rs(8), 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        t.homeOnlineStore,
                        style: TextStyle(
                            fontSize: context.rf(17), fontWeight: FontWeight.w800),
                      ),
                      if (state.status == StoreStatus.ready)
                        Text(
                          t.storeModelsCount(state.filtered.length),
                          style: TextStyle(
                            fontSize: context.rf(11),
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      tooltip: t.storeFilters,
                      onPressed: () => showEndDrawerSheet(
                        context,
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: const StoreFilterDrawer(),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                    if (state.hasActiveFilters)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: scheme.primary, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state.status) {
              StoreStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              StoreStatus.error => Center(
                  child: TextButton(
                      onPressed: cubit.load, child: Text(t.homeErrorRetry))),
              StoreStatus.ready => state.filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40,
                              color: scheme.onSurface.withValues(alpha: 0.35)),
                          const SizedBox(height: 10),
                          Text(t.storeNoResults),
                          TextButton(
                              onPressed: cubit.clearFilters,
                              child: Text(t.storeClearFilters)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cubit.load,
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(context.rs(16),
                            context.rs(10), context.rs(16), context.rs(30)),
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: 800,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.isTablet ? 3 : 2,
                          mainAxisSpacing: context.rs(12),
                          crossAxisSpacing: context.rs(12),
                          childAspectRatio: 0.58,
                        ),
                        itemCount: state.filtered.length,
                        itemBuilder: (context, i) {
                          final v = state.filtered[i];
                          return RepaintBoundary(
                            child: StoreCarCard(vehicle: v, lang: lang)
                                .animate(delay: (30 * (i % 8)).ms)
                                .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                                .slideY(begin: 0.05, end: 0, duration: 280.ms),
                          );
                        },
                      ),
                    ),
            },
          ),
        ],
      ),
    );
  }
}

/// Grid card — the website's /online card: heart, AVAILABLE ONLINE badge,
/// year, image (Hero), brand, name/trim, FROM price + VAT note, Add to cart,
/// color dots. Tapping opens the purchase sheet.
final class StoreCarCard extends StatelessWidget {
  const StoreCarCard({super.key, required this.vehicle, required this.lang});

  final OnlineVehicle vehicle;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final slug = vehicle.slug ?? '';
    final favorited =
        context.select((FavoritesCubit c) => c.state.contains(slug));
    final inCart =
        context.select((CartCubit c) => c.state.any((i) => i.slug == slug));

    return HomeCard(
      onTap: () => openCarSheet(context, vehicle),
      child: Padding(
        padding: EdgeInsets.all(context.rs(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Heart — favorites, like the website card's top-start button.
                GestureDetector(
                  onTap: () => context.read<FavoritesCubit>().toggle(slug),
                  child: AnimatedScale(
                    scale: favorited ? 1.08 : 1,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: context.rs(30),
                      height: context.rs(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.7)),
                      ),
                      child: Icon(
                        favorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: favorited
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.rs(7), vertical: context.rs(3)),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: context.rs(9), color: scheme.onPrimary),
                      SizedBox(width: context.rs(3)),
                      Text(
                        t.storeAvailableOnline,
                        style: TextStyle(
                          fontSize: context.rf(7.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                vehicle.year ?? '',
                style: TextStyle(
                  fontSize: context.rf(10.5),
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: Hero(
                tag: 'car-${vehicle.slug}',
                child: HomeImage(
                  url: vehicle.image,
                  fit: BoxFit.contain,
                  logicalWidth: 220,
                ),
              ),
            ),
            Text(
              (lang == 'ar' ? vehicle.brandAr : vehicle.brandEn) ??
                  vehicle.brandEn ??
                  '',
              style: TextStyle(
                fontSize: context.rf(8.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            Text(
              vehicle.name(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: context.rf(14.5), fontWeight: FontWeight.w800),
            ),
            Text(
              vehicle.subtitle(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rf(10),
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: context.rs(5)),
            Text(
              t.storeFrom,
              style: TextStyle(
                fontSize: context.rf(8),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            PriceText(
              price: vehicle.minPrice,
              currency: t.currency,
              contactForPrice: t.homeContactForPrice,
              fontSize: context.rf(14.5),
            ),
            Text(
              t.storeVatNote,
              maxLines: 2,
              style: TextStyle(
                fontSize: context.rf(7.5),
                height: 1.3,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            SizedBox(height: context.rs(6)),
            Row(
              children: [
                // Color dots preview.
                for (final c in vehicle.uniqueColors.take(2))
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: context.rs(3)),
                    child: ClipOval(
                      child: SizedBox(
                        width: context.rs(14),
                        height: context.rs(14),
                        child: HomeImage(url: c.image, logicalWidth: 14),
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  height: context.rs(30),
                  child: FilledButton.icon(
                    onPressed: () {
                      context.read<CartCubit>().add(CartItem.fromVehicle(vehicle));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(t.cartAdded)));
                    },
                    icon: Icon(
                        inCart
                            ? Icons.check_rounded
                            : Icons.shopping_cart_outlined,
                        size: context.rs(12)),
                    label: Text(t.storeAddToCart),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding:
                          EdgeInsets.symmetric(horizontal: context.rs(10)),
                      textStyle: TextStyle(
                          fontSize: context.rf(10),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
