import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_header.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/parts_cart_cubit.dart';
import '../bloc/parts_cubit.dart';
import '../data/parts_repository.dart';
import '../domain/parts_cart_models.dart';
import '../domain/parts_models.dart';

/// Genuine spare parts — the website's /parts page for mobile: dashboard
/// banner, category chips (main → sub), debounced free-text search, sort and
/// the paged parts grid.
final class PartsScreen extends StatelessWidget {
  const PartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    return BlocProvider(
      key: ValueKey('parts-$brandKey'),
      create: (_) => PartsCubit(
        PartsRepository(sl<ApiClient>()),
        brandDbId: brandKey == 'lexus' ? 2 : 1,
        brandKey: brandKey,
      ),
      child: const _PartsView(),
    );
  }
}

final class _PartsView extends StatelessWidget {
  const _PartsView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<PartsCubit>().state;
    final cubit = context.read<PartsCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: state.status == PartsStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 400) cubit.loadMore();
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: cubit.refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ── Dashboard hero (parts_hero placement) with the
                        //    floating search card overlapping its bottom. ──
                        SliverToBoxAdapter(
                          child: _Hero(
                            hero: state.hero,
                            fallbackBanner: state.banners.firstOrNull,
                            lang: lang,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Transform.translate(
                            offset: Offset(0, -context.rs(26)),
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: context.rs(16),
                                right: context.rs(16),
                                top: context.rs(45),
                              ),
                              child: Container(
                                padding: EdgeInsets.all(context.rs(8)),
                                decoration: softCardDecoration(
                                  context,
                                  radius: 18,
                                ),
                                child: Row(
                                  children: [
                                    _SortButton(sort: state.sort),
                                    SizedBox(width: context.rs(6)),
                                    const _CartButton(),
                                    SizedBox(width: context.rs(6)),
                                    Expanded(
                                      child: TextField(
                                        controller: cubit.searchCtrl,
                                        decoration: InputDecoration(
                                          hintText: t.partsSearchHint,
                                          hintStyle: TextStyle(
                                            fontSize: context.rf(12),
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                          suffixIcon: const Icon(
                                            Icons.search_rounded,
                                            size: 20,
                                          ),
                                          isDense: true,
                                          filled: true,
                                          fillColor:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : const Color(0xFFF2F4F8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 11,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Category chips (main → sub) ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: context.rs(12)),
                            child: FilterChipsRow(
                              labels: [
                                t.homeAll,
                                ...state.filters.mainCategories.map(
                                  (c) => c.name(lang),
                                ),
                              ],
                              selectedIndex: state.catId == null
                                  ? 0
                                  : state.filters.mainCategories.indexWhere(
                                          (c) => c.id == state.catId,
                                        ) +
                                        1,
                              onSelected: (i) => cubit.selectCategory(
                                i == 0
                                    ? null
                                    : state.filters.mainCategories[i - 1].id,
                              ),
                            ),
                          ),
                        ),
                        if (state.filters.subsOf(state.catId).isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: context.rs(8)),
                              child: FilterChipsRow(
                                labels: [
                                  t.homeAll,
                                  ...state.filters
                                      .subsOf(state.catId)
                                      .map((c) => c.name(lang)),
                                ],
                                selectedIndex: state.subCatId == null
                                    ? 0
                                    : state.filters
                                              .subsOf(state.catId)
                                              .indexWhere(
                                                (c) => c.id == state.subCatId,
                                              ) +
                                          1,
                                onSelected: (i) => cubit.selectSubCategory(
                                  i == 0
                                      ? null
                                      : state.filters
                                            .subsOf(state.catId)[i - 1]
                                            .id,
                                ),
                              ),
                            ),
                          ),

                        // ── In-stock toggle + count ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.rs(20),
                              context.rs(8),
                              context.rs(20),
                              0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.partsResults(state.totalCount),
                                    style: TextStyle(
                                      fontSize: context.rf(11),
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  t.partsInStockOnly,
                                  style: TextStyle(
                                    fontSize: context.rf(11),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Switch(
                                  value: state.inStockOnly,
                                  onChanged: cubit.toggleInStock,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Grid ──
                        if (state.searching)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        else if (state.items.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(context.rs(40)),
                              child: Center(child: Text(t.partsEmpty)),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              context.rs(16),
                              context.rs(10),
                              context.rs(16),
                              0,
                            ),
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: context.rs(12),
                                    crossAxisSpacing: context.rs(12),
                                    childAspectRatio: 0.72,
                                  ),
                              itemCount: state.items.length,
                              itemBuilder: (context, i) =>
                                  _PartCard(part: state.items[i], lang: lang)
                                      .animate(delay: (25 * (i % 6)).ms)
                                      .fadeIn(duration: 200.ms),
                            ),
                          ),
                        if (state.loadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: context.rs(140)),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Parts-cart entry with a live badge — mirrors the website header's cart.
final class _CartButton extends StatelessWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = context.watch<PartsCartCubit>().count;
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => context.push(Routes.partsCart),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.shopping_cart_outlined,
              size: 19, color: scheme.onSurface.withValues(alpha: 0.7)),
          if (count > 0)
            PositionedDirectional(
              top: 5,
              end: 5,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimary)),
              ),
            ),
        ]),
      ),
    );
  }
}

final class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort});

  final PartsSort sort;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<PartsCubit>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
      ),
      child: PopupMenuButton<PartsSort>(
        initialValue: sort,
        onSelected: cubit.setSort,
        icon: Icon(
          Icons.tune_rounded,
          size: 19,
          color: scheme.onSurface.withValues(alpha: 0.7),
        ),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: PartsSort.relevance,
            child: Text(t.partsSortRelevance),
          ),
          PopupMenuItem(
            value: PartsSort.priceDesc,
            child: Text(t.partsSortPriceDesc),
          ),
          PopupMenuItem(
            value: PartsSort.priceAsc,
            child: Text(t.partsSortPriceAsc),
          ),
          PopupMenuItem(value: PartsSort.partNo, child: Text(t.partsSortNo)),
        ],
      ),
    );
  }
}

/// Full-bleed page hero — dashboard 'parts_hero' slide (title + subtitle +
/// media, per brand); falls back to the Parts Banners image, then to a
/// brand gradient. Rounded bottom; the search card overlaps it.
final class _Hero extends StatelessWidget {
  const _Hero({
    required this.hero,
    required this.fallbackBanner,
    required this.lang,
  });

  final PartsHero? hero;
  final PartsBanner? fallbackBanner;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final image = optimizedImageUrl(
      hero?.mediaType == 'image' ? hero?.mediaUrl : fallbackBanner?.imageUrl,
      width:
          (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
              .round(),
    );
    final title = (hero?.title(lang) ?? '').isNotEmpty
        ? hero!.title(lang)
        : t.partsTitle;
    final subtitle = (hero?.subtitle(lang) ?? '').isNotEmpty
        ? hero!.subtitle(lang)
        : t.partsSubtitle;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      child: SizedBox(
        height: context.rs(206),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.network(
                image,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => ColoredBox(color: scheme.primary),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, const Color(0xFF15171C)],
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.25, 1.0],
                  colors: [Color(0x14000000), Color(0xB8000000)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20),
                0,
                context.rs(20),
                context.rs(40),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.rf(22),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.rs(3)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: context.rf(11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local favorite part numbers (heart on the card) — SharedPreferences set.
final class _PartFavs {
  static final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    ids.value = (prefs.getStringList('fav_parts') ?? const []).toSet();
  }

  static Future<void> toggle(String guid) async {
    final next = Set<String>.from(ids.value);
    next.contains(guid) ? next.remove(guid) : next.add(guid);
    ids.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fav_parts', next.toList());
  }
}

/// Part card — the reference tile: photo with the heart button (top-start)
/// and the red availability pill (top-end), name, then the price with the
/// round brand action button.
final class _PartCard extends StatelessWidget {
  const _PartCard({required this.part, required this.lang});

  final PartItem part;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    _PartFavs.ensureLoaded();
    final guid = part.guid ?? part.productNo ?? '';

    return HomeCard(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: EdgeInsets.all(context.rs(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: HomeImage(
                      url: part.image,
                      fit: BoxFit.contain,
                      logicalWidth: 180,
                    ),
                  ),
                  // Favorite heart — white roundel, brand fill when saved.
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: _PartFavs.ids,
                      builder: (context, favs, _) {
                        final fav = favs.contains(guid);
                        return GestureDetector(
                          onTap: () => _PartFavs.toggle(guid),
                          child: Container(
                            width: context.rs(30),
                            height: context.rs(30),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: kSoftShadows(context),
                            ),
                            child: Icon(
                              fav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 15,
                              color: fav
                                  ? scheme.primary
                                  : scheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Availability pill — red-tinted "متوفر" like the mock.
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(8),
                        vertical: context.rs(3.5),
                      ),
                      decoration: BoxDecoration(
                        color: part.inStock
                            ? scheme.primary.withValues(alpha: 0.1)
                            : scheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        part.inStock ? t.partsInStock : t.partsOutOfStock,
                        style: TextStyle(
                          fontSize: context.rf(8.5),
                          fontWeight: FontWeight.w800,
                          color: part.inStock
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.rs(6)),
            if ((part.productNo ?? '').isNotEmpty)
              Text(
                part.productNo!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: context.rf(9),
                  letterSpacing: 0.4,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            Text(
              part.name(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rf(11.5),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            SizedBox(height: context.rs(7)),
            Row(
              children: [
                // Round brand action — opens the part detail (mock's red dot).
                Container(
                  width: context.rs(28),
                  height: context.rs(28),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: scheme.onPrimary,
                  ),
                ),
                const Spacer(),
                if (part.hasDiscount) ...[
                  Text(
                    formatPrice(part.salesPrice!),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: context.rf(9.5),
                      decoration: TextDecoration.lineThrough,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  SizedBox(width: context.rs(5)),
                ],
                PriceText(
                  price: part.effectivePrice,
                  currency: '',
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(13.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showHeroBottomSheet<void>(
      context,
      heightFactor: 0.62,
      builder: (_) => _PartDetailSheet(part: part, lang: lang),
    );
  }
}

final class _PartDetailSheet extends StatefulWidget {
  const _PartDetailSheet({required this.part, required this.lang});

  final PartItem part;
  final String lang;

  @override
  State<_PartDetailSheet> createState() => _PartDetailSheetState();
}

final class _PartDetailSheetState extends State<_PartDetailSheet> {
  int _qty = 1;

  PartItem get part => widget.part;
  String get lang => widget.lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.rs(20),
            context.rs(10),
            context.rs(20),
            context.rs(24),
          ),
          children: [
            const Center(child: SheetHandle()),
            SizedBox(height: context.rs(12)),
            SizedBox(
              height: context.rs(180),
              child: HomeImage(
                url: part.image,
                fit: BoxFit.contain,
                logicalWidth: 360,
              ),
            ),
            SizedBox(height: context.rs(12)),
            if ((part.productNo ?? '').isNotEmpty)
              Text(
                part.productNo!,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: context.rf(11),
                  letterSpacing: 0.5,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            SizedBox(height: context.rs(4)),
            Text(
              part.name(lang),
              style: TextStyle(
                fontSize: context.rf(17),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: context.rs(10)),
            Row(
              children: [
                PriceText(
                  price: part.effectivePrice,
                  currency: '',
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(18),
                ),
                if (part.hasDiscount) ...[
                  SizedBox(width: context.rs(8)),
                  Text(
                    formatPrice(part.salesPrice!),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: context.rf(12),
                      decoration: TextDecoration.lineThrough,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(10),
                    vertical: context.rs(5),
                  ),
                  decoration: BoxDecoration(
                    color: part.inStock
                        ? const Color(0xFF1E9E5A).withValues(alpha: 0.12)
                        : scheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    part.inStock ? t.partsInStock : t.partsOutOfStock,
                    style: TextStyle(
                      fontSize: context.rf(10.5),
                      fontWeight: FontWeight.w800,
                      color: part.inStock
                          ? const Color(0xFF1E9E5A)
                          : scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(14)),
            Text(
              t.partsDetailHint,
              style: TextStyle(
                fontSize: context.rf(11.5),
                height: 1.6,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: context.rs(16)),

            // ── الكمية + أضف إلى السلة (the website's part page CTA) ──
            Row(children: [
              Text(t.pcQty,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _qty++),
                    icon: const Icon(Icons.add_rounded, size: 17),
                  ),
                  Text('$_qty',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        _qty <= 1 ? null : () => setState(() => _qty--),
                    icon: const Icon(Icons.remove_rounded, size: 17),
                  ),
                ]),
              ),
            ]),
            SizedBox(height: context.rs(12)),
            Builder(builder: (context) {
              final cart = context.watch<PartsCartCubit>();
              final inCart = cart.contains(part.guid ?? '');
              return FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: TextStyle(
                      fontSize: context.rf(13.5),
                      fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  cart.add(PartsCartItem(
                    guid: part.guid ?? part.productNo ?? '',
                    productId: part.productId,
                    productNo: part.productNo,
                    nameAr: part.descriptionAr,
                    nameEn: part.descriptionEn,
                    image: part.image,
                    price: part.effectivePrice,
                    inStock: part.inStock,
                    qty: _qty,
                  ));
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t.pcAdded),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: t.pcViewCart,
                      onPressed: () => sl<GoRouter>().push(Routes.partsCart),
                    ),
                  ));
                },
                icon: Icon(
                    inCart
                        ? Icons.check_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 18),
                label: Text(inCart ? t.pcInCart : t.pcAddToCart),
              );
            }),
          ],
        ),
      ),
    );
  }
}
