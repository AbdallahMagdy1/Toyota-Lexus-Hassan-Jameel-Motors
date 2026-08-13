import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_states.dart';
import '../../account/presentation/registered_home_view.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../coupons/presentation/coupon_banner_carousel.dart';
import '../../guest_home/presentation/guest_home_view.dart';
import '../bloc/home_cubit.dart';
import 'widgets/home_bits.dart';
import 'widgets/offer_hero_slider.dart';
import 'widgets/section_rails.dart';

/// Home — the website home, section for section:
/// offers hero slider → online store → models + category filter →
/// protection & shading → spare parts → used cars → maintenance specials →
/// vehicle offers. One aggregate request paints everything.
final class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    final status = context.select((AuthBloc b) => b.state.status);
    // Guests get the browse-first home; registered users get "Your Car,
    // Your Journey" — the backend's home-state resolves the dynamic card
    // for both with-car and without-car users.
    if (status == AuthStatus.guest) return const GuestHomeView();
    if (status == AuthStatus.authenticated) return const RegisteredHomeView();
    return BlocProvider(
      // New cubit (and fresh feed) whenever the brand switches.
      key: ValueKey('home-$brandKey'),
      create: (_) => HomeCubit(sl(), brandKey: brandKey),
      child: const _HomeView(),
    );
  }
}

final class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<HomeCubit>().state;
    final cubit = context.read<HomeCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Column(
        children: [
          const AppHeader(),
          Expanded(
            child: switch (state.status) {
              HomeStatus.loading => const _HomeSkeleton(),
              HomeStatus.error => AppErrorState(
                  title: t.stateErrorTitle,
                  message: t.stateErrorBody,
                  retryLabel: t.stateRetry,
                  onRetry: cubit.load,
                ),
              HomeStatus.ready => RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // 1 — Offers hero slider.
                      if (state.heroOffers.isNotEmpty)
                        SliverToBoxAdapter(
                          child: OfferHeroSlider(
                            offers: state.heroOffers,
                            controller: cubit.heroController,
                            index: state.heroIndex,
                            onChanged: cubit.onHeroChanged,
                            lang: lang,
                          ),
                        ),

                      // 1b — Home coupon banners (renders nothing when none).
                      const SliverToBoxAdapter(child: CouponBannerCarousel()),

                      // 2 — Online store rail.
                      if (state.feed.onlineVehicles.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: t.homeOnlineStore,
                            subtitle: t.homeOnlineStoreSub,
                            actionLabel: t.homeViewAll,
                            onAction: () => context.push(Routes.onlineStore),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: OnlineStoreRail(
                              vehicles: state.feed.onlineVehicles, lang: lang),
                        ),
                      ],

                      // 3 — Vehicles + category filter.
                      if (state.feed.vehicles.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: t.homeMeetTheModels,
                            actionLabel: t.homeViewAll,
                            onAction: () => context.push(Routes.models),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: FilterChipsRow(
                            labels: [t.homeAll, ...state.feed.vehicleCategories],
                            selectedIndex: state.vehicleCategory == null
                                ? 0
                                : state.feed.vehicleCategories
                                        .indexOf(state.vehicleCategory!) +
                                    1,
                            onSelected: (i) => cubit.selectVehicleCategory(
                                i == 0 ? null : state.feed.vehicleCategories[i - 1]),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: context.rs(12))),
                        SliverToBoxAdapter(
                          child: VehiclesRail(
                              vehicles: state.filteredVehicles, lang: lang),
                        ),
                      ],

                      // 4 — Protection & shading.
                      if (state.feed.vehicles.isNotEmpty)
                        const SliverToBoxAdapter(child: ProtectionCard()),

                      // 5 — Spare parts.
                      if (state.feed.partsCategories.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: t.homeSpareParts,
                            subtitle: t.homeSparePartsSub,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: FilterChipsRow(
                            labels: [
                              t.homeAll,
                              ...state.feed.partsCategories.map((c) => c.name(lang)),
                            ],
                            selectedIndex: state.partsCategoryId == null
                                ? 0
                                : state.feed.partsCategories.indexWhere(
                                        (c) => c.id == state.partsCategoryId) +
                                    1,
                            onSelected: (i) => cubit.selectPartsCategory(
                                i == 0 ? null : state.feed.partsCategories[i - 1].id),
                          ),
                        ),
                        // Sub-category tabs, shown once a main category is
                        // picked — same two-level filtering as the website.
                        if (state.partsSubCategories.isNotEmpty) ...[
                          SliverToBoxAdapter(child: SizedBox(height: context.rs(8))),
                          SliverToBoxAdapter(
                            child: FilterChipsRow(
                              labels: [
                                t.homeAll,
                                ...state.partsSubCategories.map((c) => c.name(lang)),
                              ],
                              selectedIndex: state.partsSubCategoryId == null
                                  ? 0
                                  : state.partsSubCategories.indexWhere(
                                          (c) => c.id == state.partsSubCategoryId) +
                                      1,
                              onSelected: (i) => cubit.selectPartsSubCategory(
                                  i == 0 ? null : state.partsSubCategories[i - 1].id),
                            ),
                          ),
                        ],
                        SliverToBoxAdapter(child: SizedBox(height: context.rs(12))),
                        SliverToBoxAdapter(
                          child: state.partsLoading
                              ? const SizedBox(
                                  height: 150,
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : PartsRail(parts: state.parts, lang: lang),
                        ),
                      ],

                      // 6 — Used cars (empty-state card when none approved yet,
                      // matching the website's always-visible section).
                      SliverToBoxAdapter(
                        child: SectionHeader(
                          title: t.homeUsedCars,
                          subtitle: t.homeUsedCarsSub,
                          actionLabel: t.homeViewAll,
                          onAction: () => _soon(context),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: state.feed.usedCars.isEmpty
                            ? const UsedCarsEmptyCard()
                            : UsedCarsRail(cars: state.feed.usedCars),
                      ),

                      // 7 — Maintenance specials.
                      if (state.feed.maintenanceOffers.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: t.homeMaintenanceSpecials,
                            subtitle: t.homeMaintenanceSpecialsSub,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: OffersRail(
                            offers: state.feed.maintenanceOffers,
                            lang: lang,
                            ctaLabel: t.homeBook,
                          ),
                        ),
                      ],

                      // 8 — Vehicle & finance offers.
                      if (state.feed.vehicleOffers.isNotEmpty) ...[
                        SliverToBoxAdapter(
                            child: SectionHeader(title: t.homeVehicleOffers)),
                        SliverToBoxAdapter(
                          child: OffersRail(
                            offers: state.feed.vehicleOffers,
                            lang: lang,
                            ctaLabel: t.homeViewOffer,
                          ),
                        ),
                      ],

                      SliverToBoxAdapter(child: SizedBox(height: context.rs(140))),
                    ],
                  ),
                ),
            },
          ),
        ],
    );
  }

  static void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).homeComingSoonFeature)));
  }
}

/// Shimmering placeholder mirroring the home layout (hero panel → chips →
/// card rails), so the page structure is visible while the feed loads and
/// nothing jumps when it arrives.
final class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget header() => Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(26), context.rs(20), context.rs(12)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(widthFactor: 0.45, height: 16),
              SizedBox(height: 8),
              SkeletonLine(widthFactor: 0.65, height: 11),
            ],
          ),
        );

    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero slider placeholder.
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(16), context.rs(20), 0),
              child: SkeletonBox(
                  width: double.infinity,
                  height: context.rs(170),
                  radius: 22),
            ),
            header(),
            SkeletonRail(height: context.rs(300), itemWidth: context.rs(216)),
            header(),
            // Filter chip placeholders.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
              child: Row(
                children: [
                  for (final w in [64.0, 84.0, 72.0, 90.0])
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: context.rs(8)),
                      child: SkeletonBox(
                          width: context.rs(w),
                          height: context.rs(34),
                          radius: 999),
                    ),
                ],
              ),
            ),
            SizedBox(height: context.rs(14)),
            SkeletonRail(height: context.rs(240), itemWidth: context.rs(236)),
            SizedBox(height: context.rs(40)),
          ],
        ),
      ),
    );
  }
}
