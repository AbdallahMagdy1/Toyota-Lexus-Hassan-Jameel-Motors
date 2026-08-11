import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../auth/bloc/auth_bloc.dart';
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
                  onPressed: () => appBack(context),
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
          // ── Hero header (Rentcars-style): brand gradient panel with the
          //    greeting → big title → search pill flow. ──
          const _HeroHeader(),
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
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(context.rs(16),
                            context.rs(12), context.rs(16), context.rs(140)),
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: 900,
                        itemCount: state.filtered.length,
                        itemBuilder: (context, i) {
                          final v = state.filtered[i];
                          return Padding(
                            padding: EdgeInsets.only(bottom: context.rs(14)),
                            child: RepaintBoundary(
                              child: StoreCarCard(vehicle: v, lang: lang)
                                  .animate(delay: (30 * (i % 6)).ms)
                                  .fadeIn(
                                      duration: 280.ms, curve: Curves.easeOut)
                                  .slideY(
                                      begin: 0.05, end: 0, duration: 280.ms),
                            ),
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

/// Brand-colored hero header — the "Rentcars" mock: rounded gradient panel,
/// personal greeting when signed in, the big "find your car" line, then the
/// search pill (surface-colored, dark-mode aware) with the filter shortcut.
final class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<OnlineStoreCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final user = context.select((AuthBloc b) => b.state.user);
    final name = (lang == 'ar'
            ? (user?.firstNameAr ?? user?.firstNameEn)
            : (user?.firstNameEn ?? user?.firstNameAr))
        ?.trim();
    final greeting = (name == null || name.isEmpty)
        ? t.osHeroGreetingGuest
        : t.osHeroGreeting(name);

    return Padding(
      padding:
          EdgeInsets.fromLTRB(context.rs(12), context.rs(8), context.rs(12), 0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            context.rs(18), context.rs(18), context.rs(18), context.rs(18)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.84)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rf(12.5),
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(height: context.rs(4)),
            Text(
              t.osHeroTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rf(21),
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: context.rs(14)),
            Row(children: [
              Expanded(
                child: TextField(
                  onChanged: cubit.setQuery,
                  decoration: InputDecoration(
                    hintText: t.storeSearch,
                    hintStyle: TextStyle(
                        fontSize: context.rf(12),
                        color: scheme.onSurface.withValues(alpha: 0.4)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                  ),
                ),
              ),
              SizedBox(width: context.rs(8)),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => showEndDrawerSheet(
                  context,
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const StoreFilterDrawer(),
                  ),
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.tune_rounded, size: 19, color: scheme.primary),
                ),
              ),
            ]),
          ],
        ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HomeCard(
      onTap: () => openCarSheet(context, vehicle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Big image panel with the badge + heart overlaid (mock) ──
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: context.rs(186),
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF6F8FB),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(18), vertical: context.rs(14)),
                    child: Hero(
                      tag: 'car-${vehicle.slug}',
                      child: HomeImage(
                        url: vehicle.image,
                        fit: BoxFit.contain,
                        logicalWidth: 380,
                      ),
                    ),
                  ),
                ),
                // AVAILABLE ONLINE — solid red pill with a car icon.
                PositionedDirectional(
                  top: context.rs(10),
                  start: context.rs(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(9), vertical: context.rs(4.5)),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.directions_car_filled_rounded,
                          size: 11, color: scheme.onPrimary),
                      SizedBox(width: context.rs(4)),
                      Text(
                        t.storeAvailableOnline,
                        style: TextStyle(
                          fontSize: context.rf(8.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ]),
                  ),
                ),
                // Heart — white roundel top-end.
                PositionedDirectional(
                  top: context.rs(10),
                  end: context.rs(10),
                  child: GestureDetector(
                    onTap: () => context.read<FavoritesCubit>().toggle(slug),
                    child: AnimatedScale(
                      scale: favorited ? 1.08 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: context.rs(32),
                        height: context.rs(32),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: kSoftShadows(context),
                        ),
                        child: Icon(
                          favorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: favorited
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ── Content ──
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(16), context.rs(13), context.rs(16), context.rs(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ((lang == 'ar'
                                        ? vehicle.brandAr
                                        : vehicle.brandEn) ??
                                    vehicle.brandEn ??
                                    '')
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: context.rf(9),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: scheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          Text(
                            vehicle.name(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.rf(19),
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3),
                          ),
                          Text(
                            [
                              vehicle.subtitle(lang),
                              vehicle.year ?? '',
                            ].where((s) => s.trim().isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.rf(10.5),
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.rs(10)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          t.storeFrom.toUpperCase(),
                          style: TextStyle(
                            fontSize: context.rf(8),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                        PriceText(
                          price: vehicle.minPrice,
                          currency: t.currency,
                          contactForPrice: t.homeContactForPrice,
                          fontSize: context.rf(17),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: context.rs(4)),
                Text(
                  t.storeVatNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rf(8.5),
                    color: scheme.primary.withValues(alpha: 0.75),
                  ),
                ),
                SizedBox(height: context.rs(12)),
                Row(
                  children: [
                    // Color swatches — first ringed, like the mock.
                    for (final (ci, c)
                        in vehicle.uniqueColors.take(4).indexed)
                      Padding(
                        padding:
                            EdgeInsetsDirectional.only(end: context.rs(6)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ci == 0
                                  ? scheme.onSurface.withValues(alpha: 0.6)
                                  : scheme.outline.withValues(alpha: 0.4),
                              width: ci == 0 ? 1.4 : 1,
                            ),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: context.rs(16),
                              height: context.rs(16),
                              child: HomeImage(url: c.image, logicalWidth: 16),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    SizedBox(
                      height: context.rs(40),
                      child: FilledButton.icon(
                        onPressed: () {
                          context
                              .read<CartCubit>()
                              .add(CartItem.fromVehicle(vehicle));
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                                SnackBar(content: Text(t.cartAdded)));
                        },
                        icon: Icon(
                            inCart
                                ? Icons.check_rounded
                                : Icons.shopping_cart_rounded,
                            size: context.rs(15)),
                        label: Text(t.storeAddToCart),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(16)),
                          textStyle: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
