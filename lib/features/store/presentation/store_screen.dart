import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/keep_alive_section.dart';
import '../../../shared/widgets/page_dots.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/quick_links_panel.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../offers/bloc/offers_cubit.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/offers_screen.dart' show OfferCard;
import '../../online_store/data/online_store_repository.dart';
import '../../online_store/presentation/car_sheet.dart' show openCarSheet;
import '../../parts/data/parts_repository.dart';
import '../../parts/domain/parts_models.dart';
import '../../parts/presentation/parts_screen.dart' show showPartDetailSheet;
import '../../protection/bloc/protection_cubit.dart';
import '../../protection/data/protection_repository.dart';
import '../../protection/presentation/protection_detail_sheet.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';

/// المتجر — the storefront hub: online-store cars hero slider, then the
/// protection & shading packages, then the maintenance/vehicle offers.
/// Lives on the bottom navigation (replaces the favorites tab).
final class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => OffersCubit(OffersRepository(sl<ApiClient>())),
      child: Column(children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: context.rs(140)),
            children: [
              // Self-fetching sections are pinned with KeepAliveSection so
              // scrolling them off-screen never disposes their state (which
              // used to refetch parts/protection on every scroll-back).
              // All Hassan Jameel services — the reference's tile row.
              SectionHeader(
                  title: t.acAllServices, subtitle: t.acAllServicesSub),
              const KeepAliveSection(child: _StoreServices()),
              SectionHeader(
                title: t.homeOnlineStore,
                subtitle: t.svcStoreSub,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.onlineStore),
              ),
              const KeepAliveSection(child: _StoreHero()),
              SectionHeader(
                title: t.ghSvcProtection,
                subtitle: t.svcProtectionSub,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.protection),
              ),
              const KeepAliveSection(child: _StorePackages()),
              SectionHeader(
                title: t.ghSpareParts,
                subtitle: t.svcPartsSub,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.parts),
              ),
              const KeepAliveSection(child: _StoreParts()),
              const KeepAliveSection(child: _StoreOffers()),
            ],
          ),
        ),
      ]),
    );
  }
}

/* ───────────────────── Spare parts (featured rail) ───────────────────── */

final class _StoreParts extends StatefulWidget {
  const _StoreParts();

  @override
  State<_StoreParts> createState() => _StorePartsState();
}

final class _StorePartsState extends State<_StoreParts> {
  final PartsRepository _repo = PartsRepository(sl<ApiClient>());

  /// Category filters — same repository data the main parts screen loads.
  PartsFilters _filters = const PartsFilters();
  String? _catId;
  String? _subCatId;

  late Future<PartsSearchResult> _future =
      _repo.search(pageSize: 10, inStockOnly: true);

  @override
  void initState() {
    super.initState();
    _repo.filters().then((f) {
      if (mounted) setState(() => _filters = f);
    });
  }

  void _reload() {
    setState(() {
      _future = _repo.search(
        cat: _catId,
        subCat: _subCatId,
        pageSize: 10,
        inStockOnly: true,
      );
    });
  }

  void _selectCategory(String? id) {
    _catId = id;
    _subCatId = null;
    _reload();
  }

  void _selectSubCategory(String? id) {
    _subCatId = id;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final subs = _filters.subsOf(_catId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category chips (main → sub), like the main parts screen ──
        if (_filters.mainCategories.isNotEmpty) ...[
          FilterChipsRow(
            labels: [
              t.homeAll,
              ..._filters.mainCategories.map((c) => c.name(lang)),
            ],
            selectedIndex: _catId == null
                ? 0
                : _filters.mainCategories
                        .indexWhere((c) => c.id == _catId) +
                    1,
            onSelected: (i) => _selectCategory(
                i == 0 ? null : _filters.mainCategories[i - 1].id),
          ),
          if (subs.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: context.rs(8)),
              child: FilterChipsRow(
                labels: [t.homeAll, ...subs.map((c) => c.name(lang))],
                selectedIndex: _subCatId == null
                    ? 0
                    : subs.indexWhere((c) => c.id == _subCatId) + 1,
                onSelected: (i) =>
                    _selectSubCategory(i == 0 ? null : subs[i - 1].id),
              ),
            ),
          SizedBox(height: context.rs(12)),
        ],
        FutureBuilder<PartsSearchResult>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SkeletonRail(
                  height: context.rs(212), itemWidth: context.rs(160));
            }
            final items = snap.data?.items ?? const <PartItem>[];
            if (items.isEmpty) {
              return AppEmptyState(
                icon: Icons.settings_suggest_outlined,
                title: t.partsEmpty,
                compact: true,
              );
            }

            return CardRail(
              height: context.rs(212),
              itemWidth: context.rs(158),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final p = items[i];
                final hasDiscount = (p.salesPriceDiscount ?? 0) > 0 &&
                    (p.salesPrice ?? 0) > (p.salesPriceDiscount ?? 0);
                return RepaintBoundary(
                  child: HomeCard(
                    // Same add-to-cart sheet as the main parts screen.
                    onTap: () =>
                        showPartDetailSheet(context, part: p, lang: lang),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product photo panel.
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: Stack(fit: StackFit.expand, children: [
                              ColoredBox(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF3F5F9),
                                child: Padding(
                                  padding: EdgeInsets.all(context.rs(10)),
                                  child: HomeImage(
                                    url: p.image,
                                    fit: BoxFit.contain,
                                    logicalWidth: 200,
                                  ),
                                ),
                              ),
                              if (hasDiscount)
                                PositionedDirectional(
                                  top: context.rs(8),
                                  start: context.rs(8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: context.rs(7),
                                        vertical: context.rs(3)),
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '-${(100 - (p.salesPriceDiscount! / p.salesPrice!) * 100).round()}%',
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                          fontSize: context.rf(9),
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onPrimary),
                                    ),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(context.rs(11),
                              context.rs(9), context.rs(11), context.rs(11)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name(lang),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: context.rf(11),
                                    height: 1.25,
                                    fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: context.rs(5)),
                              Row(children: [
                                PriceText(
                                  price: hasDiscount
                                      ? p.salesPriceDiscount
                                      : p.salesPrice,
                                  currency: t.currency,
                                  contactForPrice: t.homeContactForPrice,
                                  fontSize: context.rf(13),
                                ),
                                if (hasDiscount) ...[
                                  SizedBox(width: context.rs(6)),
                                  Expanded(
                                    child: Text(
                                      p.salesPrice!.toStringAsFixed(0),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: context.rf(10),
                                        decoration:
                                            TextDecoration.lineThrough,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                ],
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/* ─────────────── All HJ services (reference tile rail) ─────────────── */

final class _StoreServices extends StatelessWidget {
  const _StoreServices();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Every Hassan Jameel service, one tap away — the Quick Links panel
    // (first service = the filled brand tile, scroll bar under the row).
    final services = <(IconData, String, String)>[
      (Icons.build_circle_outlined, t.mhTitle, Routes.maintenance),
      (Icons.shield_outlined, t.ghSvcProtection, Routes.protection),
      (Icons.account_balance_outlined, t.ghSvcFinance, Routes.finance),
      (Icons.local_offer_outlined, t.offersTitle, Routes.offers),
      (Icons.storefront_outlined, t.homeOnlineStore, Routes.onlineStore),
      (Icons.directions_car_outlined, t.homeMeetTheModels, Routes.models),
      (Icons.settings_rounded, t.ghSpareParts, Routes.parts),
      (Icons.car_repair_rounded, t.trackTitle, Routes.tracking),
      (Icons.sell_outlined, t.ucTitle, Routes.usedCars),
      (Icons.request_quote_outlined, t.finReqTitle, Routes.financeRequests),
      (Icons.favorite_border_rounded, t.favTitle, Routes.favorites),
      (Icons.newspaper_outlined, t.newsTitle, Routes.news),
      (Icons.support_agent_outlined, t.contactTitle, Routes.contact),
    ];

    return QuickLinksPanel(actions: [
      for (final (icon, label, route) in services)
        (icon, label, () => context.push(route)),
    ]);
  }
}

/* ───────────────────── Hero: online-store cars ───────────────────── */

final class _StoreHero extends StatefulWidget {
  const _StoreHero();

  @override
  State<_StoreHero> createState() => _StoreHeroState();
}

final class _StoreHeroState extends State<_StoreHero> {
  late final Future<List<OnlineVehicle>> _future =
      OnlineStoreRepository(sl<ApiClient>()).vehicles();
  final _controller = PageController(viewportFraction: 0.9);
  Timer? _auto;
  int _page = 0;
  int _count = 0;

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAuto() {
    if (_auto != null || _count < 2) return;
    _auto = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients || _count < 2) return;
      _controller.animateToPage(
        (_page + 1) % _count,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final brandKey = context.watch<ThemeCubit>().state.brandKey;

    return FutureBuilder<List<OnlineVehicle>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Shimmer(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
              child: SkeletonBox(
                  width: double.infinity,
                  height: context.rs(224),
                  radius: 22),
            ),
          );
        }
        final all = snap.data ?? const <OnlineVehicle>[];
        final needle = brandKey == 'lexus' ? 'lexus' : 'toyota';
        var items = all
            .where((v) =>
                (v.brandEn ?? '').toLowerCase().contains(needle))
            .toList();
        if (items.isEmpty) items = all;
        if (items.isEmpty) return const SizedBox.shrink();
        _count = items.length;
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAuto());

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(children: [
          SizedBox(
            height: context.rs(288),
            child: PageView.builder(
              controller: _controller,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final v = items[i];
                // Meet-the-models card style: one solid brand panel (dark
                // panel in dark mode), plain car image — no backdrop, no
                // glow, no overlay. Flat paint = cheap to scroll.
                final panel =
                    isDark ? const Color(0xFF1A1C21) : scheme.primary;
                final fg = isDark ? Colors.white : scheme.onPrimary;
                final ctaBg = isDark ? scheme.primary : scheme.onPrimary;
                final ctaFg = isDark ? scheme.onPrimary : scheme.primary;

                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: context.rs(5)),
                  child: RepaintBoundary(
                    child: Material(
                      color: panel,
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => openCarSheet(context, v),
                        child: Padding(
                          padding: EdgeInsets.all(context.rs(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.brandEn ?? '',
                                style: TextStyle(
                                  color: fg.withValues(alpha: 0.75),
                                  fontSize: context.rf(10.5),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${v.name(lang)} ${v.year ?? ''}'.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: context.rf(17),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: HomeImage(
                                    url: v.image,
                                    fit: BoxFit.contain,
                                    logicalWidth: 380,
                                  ),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.modelsPrice,
                                          style: TextStyle(
                                            color:
                                                fg.withValues(alpha: 0.55),
                                            fontSize: context.rf(9.5),
                                          ),
                                        ),
                                        PriceText(
                                          price: v.showPrice
                                              ? v.minPrice
                                              : null,
                                          currency: t.currency,
                                          contactForPrice:
                                              t.homeContactForPrice,
                                          fontSize: context.rf(13),
                                          color: fg,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // "Buy Now" chip — contrasts with the
                                  // panel, like the grid card's roundel.
                                  Container(
                                    height: context.rs(38),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: context.rs(16)),
                                    decoration: BoxDecoration(
                                      color: ctaBg,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Row(children: [
                                      Text(
                                        t.homeBuyNow,
                                        style: TextStyle(
                                          fontSize: context.rf(12),
                                          fontWeight: FontWeight.w800,
                                          color: ctaFg,
                                        ),
                                      ),
                                      SizedBox(width: context.rs(6)),
                                      Icon(
                                        Directionality.of(context) ==
                                                TextDirection.rtl
                                            ? Icons.north_west_rounded
                                            : Icons.north_east_rounded,
                                        size: 14,
                                        color: ctaFg,
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: context.rs(9)),
          PageDots(
            count: items.length.clamp(0, 10),
            index: _page.clamp(0, 9),
            activeColor: scheme.primary,
          ),
        ]).animate().fadeIn(duration: 280.ms);
      },
    );
  }
}

/* ─────────────── Protection & shading packages rail ─────────────── */

final class _StorePackages extends StatelessWidget {
  const _StorePackages();

  @override
  Widget build(BuildContext context) {
    final brandDbId = context.select(
        (ThemeCubit c) => c.state.brandKey == 'lexus' ? '2' : '1');
    return BlocProvider(
      // Recreate on brand switch so the catalog follows the theme.
      key: ValueKey('store-prot-$brandDbId'),
      create: (_) => ProtectionCubit(
          ProtectionRepository(sl<ApiClient>()),
          brandDbId: brandDbId),
      child: const _StorePackagesView(),
    );
  }
}

/// Uses ProtectionCubit — the website's exact picker rules (brand scope,
/// year >= 2025, dedupe groups by name / models by productTypeID) — so the
/// dropdowns never repeat, and auto-selects the first group + model.
final class _StorePackagesView extends StatelessWidget {
  const _StorePackagesView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final cubit = context.read<ProtectionCubit>();
    final state = context.watch<ProtectionCubit>().state;

    if (state.status == ProtectionStatus.loading) {
      return SkeletonRail(
          height: context.rs(268), itemWidth: context.rs(236));
    }
    if (state.status == ProtectionStatus.error || state.groups.isEmpty) {
      return const SizedBox.shrink();
    }

    // Auto-select the first group, then the first model of that group.
    if (state.groupId == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => cubit.selectGroup(state.groups.first.id));
    } else if (state.modelId == null) {
      final options = state.modelOptions();
      if (options.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => cubit.selectModel(options.first.id));
      }
    }

    final models = state.modelOptions();
    final selectedModel = state.selectedModel;
    final packages = state.result?.services ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
          child: Row(children: [
            Expanded(
              child: AppDropdown<String>(
                label: t.homeSelectCar,
                value: state.groupId,
                dense: true,
                items: [
                  for (final g in state.groups)
                    AppDropdownItem(
                        value: g.id ?? '',
                        label: g.name(lang),
                        icon: Icons.directions_car_filled_rounded),
                ],
                onChanged: cubit.selectGroup,
              ),
            ),
            SizedBox(width: context.rs(10)),
            Expanded(
              child: AppDropdown<String>(
                label: t.homeSelectModel,
                value: state.modelId,
                dense: true,
                enabled: models.isNotEmpty,
                items: [
                  for (final m in models)
                    AppDropdownItem(
                        value: m.id ?? '', label: m.name(lang)),
                ],
                onChanged: cubit.selectModel,
              ),
            ),
          ]),
        ),
        SizedBox(height: context.rs(12)),
        if (state.servicesLoading)
          SkeletonRail(height: context.rs(268), itemWidth: context.rs(236))
        else if (packages.isEmpty)
          AppEmptyState(
            icon: Icons.shield_outlined,
            title: t.modelsNoData,
            compact: true,
          )
        else
          CardRail(
            height: context.rs(268),
            itemWidth: context.rs(236),
            itemCount: packages.length,
            itemBuilder: (context, i) {
              final p = packages[i];
              final isDark =
                  Theme.of(context).brightness == Brightness.dark;
              // Same tier card as the home protection section: palette
              // from the package NAME drives wash, roundel, badge + CTA.
              final tier = packageTierColors(p.name(lang), scheme);
              void open() => showProtectionDetailSheet(
                    context,
                    package: p,
                    vehicleLabel: selectedModel?.name(lang),
                  );
              return Pressable(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: open,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all(context.rs(15)),
                      decoration: softCardDecoration(context,
                          radius: 20, tint: tier.color),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: context.rs(42),
                                height: context.rs(42),
                                decoration: BoxDecoration(
                                    color: tier.color.withValues(
                                        alpha: isDark ? 0.3 : 0.18),
                                    shape: BoxShape.circle),
                                child: Icon(Icons.verified_user_rounded,
                                    size: 19,
                                    color:
                                        isDark ? tier.color : tier.deep),
                              ),
                              const Spacer(),
                              if (i == 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: context.rs(9),
                                      vertical: context.rs(4)),
                                  decoration: BoxDecoration(
                                    color: tier.color.withValues(
                                        alpha: isDark ? 0.3 : 0.18),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    t.protPopular,
                                    style: TextStyle(
                                        fontSize: context.rf(8.5),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: isDark
                                            ? tier.color
                                            : tier.deep),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.rs(13)),
                          Text(p.name(lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: context.rf(13.5),
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: context.rs(5)),
                          Expanded(
                            child: Text(
                              p.description(lang).replaceAll('\n', ' '),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: context.rf(11),
                                  height: 1.45,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55)),
                            ),
                          ),
                          PriceText(
                              price: p.price,
                              currency: t.currency,
                              contactForPrice: t.homeContactForPrice,
                              fontSize: context.rf(15),
                              color: isDark ? tier.color : tier.deep),
                          SizedBox(height: context.rs(10)),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: tier.color,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(64, 42),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                textStyle: TextStyle(
                                    fontSize: context.rf(12),
                                    fontWeight: FontWeight.w800),
                              ),
                              onPressed: open,
                              child: Text(t.protSelectPackage),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/* ───────────────────── Offers (vehicle / maintenance) ───────────────────── */

final class _StoreOffers extends StatefulWidget {
  const _StoreOffers();

  @override
  State<_StoreOffers> createState() => _StoreOffersState();
}

final class _StoreOffersState extends State<_StoreOffers> {
  int _tab = 0; // 0 all, 1 vehicles (typeId 2), 2 maintenance (typeId 3)

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final state = context.watch<OffersCubit>().state;
    final brandDbId = context.select(
        (ThemeCubit c) => c.state.brandKey == 'lexus' ? '2' : '1');

    final offers = state.offers.where((o) {
      final visible = o.visibleForBrand(brandDbId);
      return switch (_tab) {
        1 => o.typeId == 2 && visible,
        2 => o.typeId == 3 && visible,
        _ => visible,
      };
    }).toList();

    if (state.offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: t.offersTitle,
          actionLabel: t.homeViewAll,
          onAction: () => context.push(Routes.offers),
        ),
        FilterChipsRow(
          labels: [t.trkAll, t.homeVehicleOffers, t.ghMaintOffers],
          selectedIndex: _tab,
          onSelected: (i) => setState(() => _tab = i),
        ),
        SizedBox(height: context.rs(12)),
        if (offers.isEmpty)
          Padding(
            padding: EdgeInsets.all(context.rs(24)),
            child: Center(child: Text(t.offersEmpty)),
          )
        else
          CardRail(
            height: context.rs(368),
            itemWidth: context.rs(310),
            itemCount: offers.length,
            itemBuilder: (context, i) => OfferCard(
              offer: offers[i],
              lang: lang,
              now: state.now ?? DateTime.now(),
              expand: true,
            ),
          ),
      ],
    );
  }
}
