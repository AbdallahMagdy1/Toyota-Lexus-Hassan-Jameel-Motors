import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/media_url.dart' show isVideoUrl;
import '../../../shared/widgets/slide_media.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/page_dots.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../onboarding/domain/onboarding_slide.dart';
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
              // All Hassan Jameel services — the reference's tile row.
              SectionHeader(
                  title: t.acAllServices, subtitle: t.acAllServicesSub),
              const _StoreServices(),
              SectionHeader(
                title: t.homeOnlineStore,
                subtitle: t.svcStoreSub,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.onlineStore),
              ),
              const _StoreHero(),
              SectionHeader(
                title: t.ghSvcProtection,
                subtitle: t.svcProtectionSub,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.protection),
              ),
              const _StorePackages(),
              SectionHeader(
                title: t.ghSpareParts,
                subtitle: t.svcPartsSub,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.parts),
              ),
              const _StoreParts(),
              const _StoreOffers(),
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
              return const Padding(
                padding: EdgeInsets.all(26),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final items = snap.data?.items ?? const <PartItem>[];
            if (items.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(context.rs(24)),
                child: Center(
                  child: Text(t.partsEmpty,
                      style: TextStyle(
                          fontSize: context.rf(12),
                          color:
                              scheme.onSurface.withValues(alpha: 0.55))),
                ),
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
    final scheme = Theme.of(context).colorScheme;

    // Every Hassan Jameel service, one tap away.
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

    return SizedBox(
      height: context.rs(114),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
        itemCount: services.length,
        separatorBuilder: (_, _) => SizedBox(width: context.rs(9)),
        itemBuilder: (context, i) {
          final (icon, label, route) = services[i];
          return SizedBox(
            width: context.rs(86),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => context.push(route),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: context.rs(12)),
                  decoration: softCardDecoration(context, radius: 16),
                  child: Column(
                    children: [
                      Container(
                        width: context.rs(44),
                        height: context.rs(44),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color:
                                scheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child:
                            Icon(icon, size: 20, color: scheme.primary),
                      ),
                      SizedBox(height: context.rs(8)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(4)),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(10),
                              height: 1.25,
                              fontWeight: FontWeight.w800),
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
    );
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

  /// Dashboard 'car_bg' slides: TitleEn = model key ('corolla 2026'),
  /// media = the background image/GIF drawn behind that model.
  List<OnboardingSlide> _bgs = const [];

  @override
  void initState() {
    super.initState();
    final brandKey = sl<ThemeCubit>().state.brandKey;
    sl<OnboardingRepository>().fetch(brandKey, placement: 'car_bg').then((s) {
      if (mounted) setState(() => _bgs = s);
    }).catchError((_) {});
  }

  /// Longest matching model key wins ('corolla cross 2026' beats 'corolla').
  String? _bgFor(String name, String? year) {
    final hay = '$name ${year ?? ''}'.toLowerCase();
    OnboardingSlide? best;
    for (final s in _bgs) {
      final key = (s.titleEn ?? '').trim().toLowerCase();
      if (key.isEmpty || (s.mediaUrl ?? '').isEmpty) continue;
      if (hay.contains(key) &&
          (best == null || key.length > (best.titleEn ?? '').trim().length)) {
        best = s;
      }
    }
    return best?.mediaUrl;
  }

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
          return SizedBox(
            height: context.rs(240),
            child: const Center(child: CircularProgressIndicator()),
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

        return Column(children: [
          SizedBox(
            height: context.rs(238),
            child: PageView.builder(
              controller: _controller,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final v = items[i];
                // Backdrop priority: car_bg placement match → model shared
                // Background → brand-glow gradient.
                final bg = _bgFor(v.groupEn ?? '', v.year) ?? v.background(lang);
                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: context.rs(5)),
                  child: GestureDetector(
                    onTap: () => openCarSheet(context, v),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121317),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Stack(fit: StackFit.expand, children: [
                        if ((bg ?? '').isNotEmpty) ...[
                          // Image / GIF via the proxy; video via SlideMedia.
                          isVideoUrl(bg)
                              ? SlideMedia(
                                  mediaType: 'video',
                                  mediaUrl: bg,
                                  fit: BoxFit.cover,
                                )
                              : HomeImage(
                                  url: bg,
                                  fit: BoxFit.cover,
                                  logicalWidth: 400,
                                ),
                          // Legibility scrim over the artwork.
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.black.withValues(alpha: 0.15),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Brand-glow backdrop (the hero look).
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.lerp(scheme.primary,
                                      Colors.black, 0.55)!,
                                  const Color(0xFF121317),
                                  Color.lerp(scheme.primary,
                                      Colors.black, 0.75)!,
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, 0.5),
                                  radius: 1.1,
                                  colors: [
                                    scheme.primary
                                        .withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        // Ground shadow under the car — grounded, not floating.
                        PositionedDirectional(
                          start: context.rs(40),
                          end: context.rs(40),
                          bottom: context.rs(2),
                          height: context.rs(22),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: 0.9,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: const BorderRadius.all(
                                  Radius.elliptical(200, 11)),
                            ),
                          ),
                        ),
                        // Car pinned to the card's bottom edge with a subtle
                        // 3D perspective tilt (same stage look as the home hero).
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          top: context.rs(52),
                          bottom: context.rs(6),
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateX(-0.12)
                              ..scaleByDouble(1.03, 1.03, 1.03, 1),
                            child: HomeImage(
                              url: v.image,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              logicalWidth: 380,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          top: context.rs(14),
                          start: context.rs(16),
                          end: context.rs(16),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${v.name(lang)} ${v.year ?? ''}'
                                          .trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: context.rf(15),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white),
                                    ),
                                    if (v.minPrice != null &&
                                        v.showPrice)
                                      Row(children: [
                                        Text(
                                          t.homeFrom,
                                          style: TextStyle(
                                            fontSize: context.rf(10),
                                            color: Colors.white
                                                .withValues(alpha: 0.65),
                                          ),
                                        ),
                                        SizedBox(width: context.rs(5)),
                                        PriceText(
                                          price: v.minPrice,
                                          currency: t.currency,
                                          contactForPrice:
                                              t.homeContactForPrice,
                                          fontSize: context.rf(14),
                                          color: Colors.white,
                                        ),
                                      ]),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: context.rs(11),
                                    vertical: context.rs(6)),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text(
                                  t.homeBuyNow,
                                  style: TextStyle(
                                      fontSize: context.rf(10.5),
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
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
      return const Padding(
        padding: EdgeInsets.all(26),
        child: Center(child: CircularProgressIndicator()),
      );
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
          const Padding(
            padding: EdgeInsets.all(26),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (packages.isEmpty)
          Padding(
            padding: EdgeInsets.all(context.rs(24)),
            child: Center(
              child: Text(t.modelsNoData,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      color:
                          scheme.onSurface.withValues(alpha: 0.55))),
            ),
          )
        else
          CardRail(
            height: context.rs(168),
            itemWidth: context.rs(210),
            itemCount: packages.length,
            itemBuilder: (context, i) {
              final p = packages[i];
              final tint = switch (p.tier) {
                2 => const Color(0xFF7E57C2),
                1 => const Color(0xFF8A7B4F),
                _ => scheme.primary,
              };
              return HomeCard(
                onTap: () => showProtectionDetailSheet(
                  context,
                  package: p,
                  vehicleLabel: selectedModel?.name(lang),
                ),
                padding: EdgeInsets.all(context.rs(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: context.rs(34),
                        height: context.rs(34),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: tint.withValues(alpha: 0.35)),
                        ),
                        child: Icon(Icons.shield_outlined,
                            size: 17, color: tint),
                      ),
                      const Spacer(),
                      Icon(
                        Directionality.of(context) ==
                                TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color:
                            scheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ]),
                    SizedBox(height: context.rs(10)),
                    Text(
                      p.name(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(13),
                          height: 1.3,
                          fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    PriceText(
                      price: p.price,
                      currency: t.currency,
                      contactForPrice: t.homeContactForPrice,
                      fontSize: context.rf(15),
                    ),
                  ],
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
            height: context.rs(392),
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
