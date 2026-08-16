import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/media_url.dart' show isVideoUrl;
import '../../../shared/widgets/slide_media.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart' show SheetHandle;
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/keep_alive_section.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/quick_links_panel.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../../shared/widgets/page_dots.dart';
import '../../home/data/home_repository.dart';
import '../../home/domain/home_models.dart' show SliderVehicle;
import '../../onboarding/data/onboarding_repository.dart';
import '../../onboarding/domain/onboarding_slide.dart';
import '../../../shared/navigation/side_menu.dart' show MenuCubit;
import '../../content/contact_screen.dart' show showBranchesSheet;
import '../../coupons/presentation/coupon_banner_carousel.dart';
import '../../notifications/notifications.dart';
import '../../offers/bloc/offers_cubit.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/domain/offer_models.dart';
import '../../offers/presentation/offers_screen.dart' show OfferCard;
import '../../protection/data/protection_repository.dart';
import '../../protection/domain/protection_models.dart';
import '../../protection/presentation/protection_detail_sheet.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart' as settings;
import '../../jobcard/presentation/jobcard_pay_sheet.dart';
import '../bloc/active_car_cubit.dart';
import '../bloc/registered_home_cubit.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';
import 'garage_sheets.dart';
import 'maintenance_booking_sheet.dart';

/// The registered-user home — "Your Car, Your Journey": greeting →
/// dynamic action card → my garage → quick actions (4 + all services) →
/// active journeys → offers tabs. The backend resolves the card + the
/// journeys priority; this view only renders.
final class RegisteredHomeView extends StatelessWidget {
  const RegisteredHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          key: ValueKey('reg-home-${user?.id}'),
          create: (_) => RegisteredHomeCubit(
            AccountRepository(sl<ApiClient>()),
            user: user,
          ),
        ),
        BlocProvider(
          create: (_) => OffersCubit(OffersRepository(sl<ApiClient>())),
        ),
        // Global selected-garage-car (persisted); offers + protection follow.
        BlocProvider.value(value: sl<ActiveCarCubit>()),
      ],
      child: const _Body(),
    );
  }
}

final class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

final class _BodyState extends State<_Body> {
  final _scroll = ScrollController();
  final _stuck = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // The solid theme-colored bar fades in once the hero header scrolls
    // out (≈ header + tabs height).
    _scroll.addListener(() {
      final stuck = _scroll.hasClients && _scroll.offset > 130;
      if (stuck != _stuck.value) _stuck.value = stuck;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _stuck.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<RegisteredHomeCubit>().state;
    final cubit = context.read<RegisteredHomeCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Column(
      children: [
        // The ready state draws its own transparent header INSIDE the hero
        // (reference design); loading/error keep the standard header.
        if (state.status != RegisteredHomeStatus.ready) const AppHeader(),
        Expanded(
          child: switch (state.status) {
            RegisteredHomeStatus.loading => Shimmer(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero slider placeholder + quick-trio + greeting rows.
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.rs(20),
                        context.rs(14),
                        context.rs(20),
                        context.rs(16),
                      ),
                      child: SkeletonBox(
                        width: double.infinity,
                        height: context.rs(250),
                        radius: 24,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  end: i == 2 ? 0 : context.rs(10),
                                ),
                                child: SkeletonBox(
                                  height: context.rs(72),
                                  radius: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.rs(24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                      child: const SkeletonLine(widthFactor: 0.5, height: 15),
                    ),
                    SizedBox(height: context.rs(14)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                      child: SkeletonBox(
                        width: double.infinity,
                        height: context.rs(140),
                        radius: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            RegisteredHomeStatus.error => AppErrorState(
              title: t.stateErrorTitle,
              message: t.stateErrorBody,
              retryLabel: t.stateRetry,
              onRetry: cubit.load,
            ),
            RegisteredHomeStatus.ready => Stack(
              children: [
                RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: context.rs(140)),
                    children: [
                      // Sections that own state (sliders, timers, section
                      // cubits, futures) are pinned with KeepAliveSection so
                      // scrolling away never disposes them — protection and
                      // offers used to refetch on every scroll-back.
                      // Reference-UI hero FIRST: full-bleed slider with the
                      // transparent header + tabs on top and the car-trio
                      // panel stacked over its bottom.
                      KeepAliveSection(
                        child: _HeroCarSlider(
                          home: state.home,
                          lang: lang,
                        ).animate().fadeIn(duration: 280.ms),
                      ),
                      _Greeting(lang: lang),
                      const KeepAliveSection(child: CouponBannerCarousel()),
                      KeepAliveSection(
                        child: _DynamicCard(
                          home: state.home,
                          lang: lang,
                        ).animate().fadeIn(duration: 280.ms),
                      ),
                      _GarageSection(home: state.home, lang: lang),
                      _QuickActions(home: state.home, lang: lang),
                      if (state.home.journeys.isNotEmpty) ...[
                        SectionHeader(
                          title: t.acJourneys,
                          actionLabel: t.homeViewAll,
                          onAction: () => context.push(Routes.tracking),
                        ),
                        _JourneysList(
                          journeys: state.home.journeys,
                          lang: lang,
                        ),
                      ],
                      // Protection & shading packages resolved for MY car.
                      if (state.home.garage.any(
                        (c) => (c.type ?? '').isNotEmpty,
                      ))
                        KeepAliveSection(
                          child: _ProtectionForCar(
                            garage: state.home.garage,
                            lang: lang,
                          ),
                        ),
                      KeepAliveSection(
                        child: _OffersTabs(home: state.home, lang: lang),
                      ),
                    ],
                  ),
                ),
                // Sticky theme-colored header — appears once the hero header
                // scrolls away (white in light / dark in dark theme).
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _stuck,
                    builder: (context, stuck, child) => IgnorePointer(
                      ignoring: !stuck,
                      child: AnimatedOpacity(
                        opacity: stuck ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: child,
                      ),
                    ),
                    child: const AppHeader(),
                  ),
                ),
              ],
            ),
          },
        ),
      ],
    );
  }
}

/* ────────────────────── Hero car slider (reference UI) ────────────────────── */

/// The reference-kit hero: big car slider. Default tab = the user's own cars
/// (brand-scoped, with name + odometer overlay); the متجر تويوتا/لكزس tab
/// flips the slider to the online-store lineup. Swiping updates the dots;
/// tapping a MY car makes it the active one and opens its hub, tapping a
/// store car opens the store car sheet.
final class _HeroCarSlider extends StatefulWidget {
  const _HeroCarSlider({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  State<_HeroCarSlider> createState() => _HeroCarSliderState();
}

final class _HeroCarSliderState extends State<_HeroCarSlider> {
  int _page = 0;

  /// Dashboard 'car_bg' slides: TitleEn = model key ('corolla 2026'),
  /// media = the background image/GIF drawn behind that model.
  List<OnboardingSlide> _bgs = const [];

  /// Dashboard 'garage_bg' placement: ONE brand-level background
  /// (image/GIF/video) shown behind ALL of the user's cars — takes priority
  /// over per-model artwork when uploaded. The slide's Overlay checkbox
  /// controls the bottom→center primary gradient on top of it.
  String? _garageBg;
  bool _garageBgOverlay = false;

  /// Guest-feed vehicles (SliderVehicle) — the source of the per-model
  /// shared "Background" artwork used when no 'car_bg' placement matches.
  /// Cached statically (SWR) so revisiting the home doesn't refetch.
  List<SliderVehicle> _feedVehicles = const [];
  static List<SliderVehicle>? _feedCache;
  static String? _feedCacheBrand;
  static DateTime? _feedCacheAt;

  @override
  void initState() {
    super.initState();
    final brandKey = sl<settings.ThemeCubit>().state.brandKey;
    sl<OnboardingRepository>()
        .fetch(brandKey, placement: 'car_bg')
        .then((s) {
          if (mounted) setState(() => _bgs = s);
        })
        .catchError((_) {});
    sl<OnboardingRepository>()
        .fetch(brandKey, placement: 'garage_bg')
        .then((s) {
          final slide = s
              .where((x) => (x.mediaUrl ?? '').isNotEmpty)
              .firstOrNull;
          if (mounted && slide != null) {
            setState(() {
              _garageBg = slide.mediaUrl;
              _garageBgOverlay = slide.overlay;
            });
          }
        })
        .catchError((_) {});
    _loadFeedVehicles(brandKey);
  }

  /// SWR: serve the cached lineup immediately, revalidate when stale.
  void _loadFeedVehicles(String brandKey) {
    final cached = _feedCache;
    if (cached != null && _feedCacheBrand == brandKey) {
      _feedVehicles = cached;
    }
    final fresh =
        cached != null &&
        _feedCacheBrand == brandKey &&
        _feedCacheAt != null &&
        DateTime.now().difference(_feedCacheAt!) < const Duration(minutes: 10);
    if (fresh) return;
    sl<HomeRepository>()
        .fetch(brandKey)
        .then((feed) {
          final vs = feed?.vehicles ?? const <SliderVehicle>[];
          if (vs.isEmpty) return;
          _feedCache = vs;
          _feedCacheBrand = brandKey;
          _feedCacheAt = DateTime.now();
          if (mounted) setState(() => _feedVehicles = vs);
        })
        .catchError((_) {});
  }

  /// The MODEL's shared Background (dashboard Cars-page upload) for a car:
  /// match the guest feed's lineup by carGroupId == productGroupId first,
  /// else by name containment, preferring the row with the same year.
  String? _modelBgFor({String? productGroupId, String? nameEn, String? year}) {
    if (_feedVehicles.isEmpty) return null;
    final gid = (productGroupId ?? '').trim();
    var matches = gid.isEmpty
        ? const <SliderVehicle>[]
        : _feedVehicles
              .where((v) => (v.carGroupId ?? '').trim() == gid)
              .toList();
    if (matches.isEmpty) {
      final name = (nameEn ?? '').trim().toLowerCase();
      if (name.isNotEmpty) {
        matches = _feedVehicles.where((v) {
          final g = v.groupEn.trim().toLowerCase();
          return g.isNotEmpty && (name.contains(g) || g.contains(name));
        }).toList();
      }
    }
    if (matches.isEmpty) return null;
    final y = (year ?? '').trim();
    return matches
            .where((v) => y.isNotEmpty && (v.year ?? '').trim() == y)
            .map((v) => v.background(widget.lang))
            .nonNulls
            .firstOrNull ??
        matches.map((v) => v.background(widget.lang)).nonNulls.firstOrNull;
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
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brandKey = context.watch<settings.ThemeCubit>().state.brandKey;
    final cars = garageForBrand(widget.home.garage, brandKey);
    if (cars.isEmpty) {
      // No garage yet — nothing to hero; the add-car flows live below.
      return const SizedBox.shrink();
    }

    // Full-bleed immersive hero (the reference design): the slider fills
    // edge-to-edge behind a transparent header; the car-trio panel stacks
    // over the hero bottom on a theme-colored sheet.
    // The hero extends under the status bar, so every fixed position below
    // offsets by the top inset or the rows collide.
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: context.rs(492) + topInset,
      child: Stack(
        children: [
          Positioned.fill(
            child: _slider(
              count: cars.length,
              itemBuilder: (context, i) {
                final car = cars[i];
                final meter = car.meterReading;
                return _HeroSlide(
                  image: car.image,
                  // Brand-level garage_bg (dashboard) → car_bg placement
                  // match → model shared Background → brand-glow gradient
                  // (inside _HeroSlide).
                  background:
                      _garageBg ??
                      _bgFor(car.groupEn ?? car.displayName('en'), car.year) ??
                      _modelBgFor(
                        productGroupId: car.productGroupId,
                        nameEn: car.groupEn ?? car.modelEn,
                        year: car.year,
                      ),
                  primaryOverlay: _garageBg != null && _garageBgOverlay,
                  title: car.displayName(widget.lang),
                  subtitle: [
                    if (meter != null && meter > 0)
                      '${NumberFormat.decimalPattern().format(meter)} ${t.acKm}',
                    if ((car.year ?? '').isNotEmpty) '${car.year}',
                  ].join(' • '),
                  onTap: () {
                    sl<ActiveCarCubit>().select(car.vin);
                    showVehicleHubSheet(
                      context,
                      car: car,
                      onChanged: context.read<RegisteredHomeCubit>().load,
                    );
                  },
                );
              },
            ),
          ),
          // ── Transparent header ON the hero: avatar | centered logo | icons ──
          const PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: _HeroHeader(),
          ),
          // ── Dots (above the trio panel, red like the mock) ──
          Positioned(
            bottom: context.rs(128),
            left: 0,
            right: 0,
            child: Center(
              child: PageDots(
                count: _count.clamp(0, 10),
                index: _page.clamp(0, 9),
                activeColor: scheme.primary,
              ),
            ),
          ),
          // ── The trio panel stacked over the hero bottom: white/dark sheet
          // (theme scaffold color) with rounded top corners, like the mock. ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: context.rs(122),
              // Clip to the rounded sheet so the sliding cards stay INSIDE
              // the panel instead of bleeding past its edges mid-scroll.
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: _CarQuickTrio(home: widget.home, lang: widget.lang),
            ),
          ),
        ],
      ),
    );
  }

  int _count = 1;

  Widget _slider({
    required int count,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    if (_count != count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _count = count);
      });
    }
    return PageView.builder(
      controller: PageController(initialPage: _page),
      itemCount: count,
      onPageChanged: (i) => setState(() => _page = i),
      itemBuilder: itemBuilder,
    );
  }
}

/// The reference-design slide: a dark immersive card. Background = the
/// dashboard 'car_bg' media for this model (image or animated GIF, full
/// bleed) with a scrim; fallback = a brand-glow dark gradient so the design
/// holds before any backgrounds are uploaded. Name + odometer sit top-start
/// in white, exactly like the mock.
final class _HeroSlide extends StatelessWidget {
  const _HeroSlide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.background,
    this.primaryOverlay = false,
  });

  final String? image;
  final String? background; // dashboard per-model bg (image/GIF)
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// garage_bg Overlay flag: brand-primary gradient rising from the hero
  /// bottom and fading out at the center.
  final bool primaryOverlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Color(0xFF121317)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Backdrop: per-model media (image / GIF / video), else
            // brand-glow fallback ──
            if ((background ?? '').isNotEmpty)
              isVideoUrl(background)
                  ? SlideMedia(
                      mediaType: 'video',
                      mediaUrl: background,
                      fit: BoxFit.cover,
                    )
                  : HomeImage(
                      url: background,
                      fit: BoxFit.cover,
                      logicalWidth: 420,
                    )
            else ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(scheme.primary, Colors.black, 0.55)!,
                      const Color(0xFF121317),
                      Color.lerp(scheme.primary, Colors.black, 0.75)!,
                    ],
                  ),
                ),
              ),
              // Soft glow pool behind the car, like the mock's red haze.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.45),
                      radius: 1.1,
                      colors: [
                        scheme.primary.withValues(alpha: 0.38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // Legibility scrim (top for the text, bottom for the dots).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            // garage_bg overlay: brand-primary glow rising from the bottom
            // edge and dissolving at the center (dashboard Overlay toggle).
            if (primaryOverlay)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      scheme.primary.withValues(alpha: 0.85),
                      scheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            // ── Ground shadow: elliptical pool right above the trio panel
            // so the car reads as sitting ON the ledge, not floating. ──
            PositionedDirectional(
              start: context.rs(46),
              end: context.rs(46),
              bottom: context.rs(112),
              height: context.rs(30),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.9,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.elliptical(220, 15)),
                ),
              ),
            ),
            // ── The car: anchored to the hero's bottom edge (wheels tucked
            // just under the panel curve) with a subtle 3D perspective tilt —
            // the mock's grounded "stage" look instead of a floating car. ──
            PositionedDirectional(
              start: 0,
              end: 0,
              top: MediaQuery.paddingOf(context).top + context.rs(118),
              bottom: context.rs(116),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(-0.12)
                  ..scaleByDouble(1.03, 1.03, 1.03, 1),
                child: HomeImage(
                  url: image,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  logicalWidth: 400,
                ),
              ),
            ),
            // ── Name + odometer (mock top-start block, white; sits under
            // the floating tabs row) ──
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + context.rs(98),
              start: context.rs(16),
              end: context.rs(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: context.rf(20),
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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

/* ───────────── Transparent hero header (reference design) ───────────── */

/// The mock's app bar, fused with the hero background: user avatar at the
/// start, brand logo dead-center, and compact white bell/location/menu
/// icons at the end — all transparent over the dark hero.
final class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  /// Always the transparent-over-hero variant; the sticky scroll bar uses
  /// the main AppHeader instead.
  static const bool solid = false;

  @override
  Widget build(BuildContext context) {
    // The user/name lookup moved into UserAvatar with the photo it renders.
    final brandKey = context.watch<settings.ThemeCubit>().state.brandKey;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Foreground: white on the hero; theme onSurface on the solid bar.
    final fg = solid ? scheme.onSurface : Colors.white;
    final chipBg = solid
        ? scheme.onSurface.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.16);
    final chipBorder = solid
        ? scheme.outline.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.4);
    // The initial-letter fallback now lives inside UserAvatar, alongside the
    // photo it falls back from.
    final brandIcon = brandKey == 'lexus'
        ? 'assets/logos/lexus-ico.png'
        : 'assets/logos/toyota-ico.png';
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final hjLogo =
        'assets/logos/logo-${isRtl ? 'right' : 'left'}-${solid && !isDark ? 'black' : 'white'}.png';

    // Equal-width wings on both sides force the logo to the TRUE center of
    // the screen (a Stack+Center drifts when the two sides differ in width).
    final wing = context.rs(116);

    return Container(
      decoration: solid
          ? BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: scheme.outline.withValues(alpha: 0.4),
                ),
              ),
            )
          : null,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.rs(10),
            context.rs(6),
            context.rs(10),
            context.rs(6),
          ),
          child: SizedBox(
            height: context.rs(44),
            child: Row(
              children: [
                // Start wing: the user's avatar roundel → profile.
                SizedBox(
                  width: wing,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push(Routes.profile),
                      child: UserAvatar(
                        size: context.rs(34),
                        background: chipBg,
                        foreground: fg,
                        border: chipBorder,
                      ),
                    ),
                  ),
                ),
                // Dead-center logo (brand roundel + white HJ wordmark).
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          brandIcon,
                          height: context.rs(22),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: context.rs(7)),
                        Image.asset(
                          hjLogo,
                          height: context.rs(20),
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
                // End wing: compact bell / location / menu.
                SizedBox(
                  width: wing,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BlocBuilder<
                          NotificationsCubit,
                          (List<AppNotification>, int)
                        >(
                          bloc: sl<NotificationsCubit>(),
                          builder: (context, s) => IconButton(
                            onPressed: () => showNotificationsSheet(context),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            icon: Badge(
                              isLabelVisible: s.$2 > 0,
                              label: Text('${s.$2}'),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 19,
                                color: fg,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => showBranchesSheet(context),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          icon: Icon(
                            Icons.location_on_outlined,
                            size: 19,
                            color: fg,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.read<MenuCubit>().open(),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          icon: Icon(Icons.menu_rounded, size: 20, color: fg),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ─────────────── Under-hero trio (mock's two-card row, ×3) ─────────────── */

/// The mock's row right under the hero: compact action cards tied to the
/// ACTIVE car — spare parts, protection & tinting packages, and service
/// booking. First card is brand-filled with a small CTA pill (like the
/// mock's red card); the others are light with icon + chevron.
final class _CarQuickTrio extends StatelessWidget {
  const _CarQuickTrio({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brandKey = context.watch<settings.ThemeCubit>().state.brandKey;
    final active = resolveActiveCar(
      home.garage,
      brandKey,
      context.watch<ActiveCarCubit>().state,
    );
    if (active == null) return const SizedBox.shrink();

    return SizedBox(
      height: context.rs(108),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(
          context.rs(16),
          context.rs(12),
          context.rs(16),
          0,
        ),
        children: [
          // 1) حجز صيانة للسيارة النشطة — brand-filled hero card.
          SizedBox(
            width: context.rs(168),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => showMaintenanceBookingSheet(context, car: active),
                child: Ink(
                  padding: EdgeInsets.all(context.rs(12)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        scheme.primary,
                        Color.lerp(scheme.primary, Colors.black, 0.25)!,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: context.rs(24),
                            height: context.rs(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.build_rounded,
                              size: 14,
                              color: scheme.onPrimary,
                            ),
                          ),
                          SizedBox(width: context.rs(7)),
                          Expanded(
                            child: Text(
                              t.ghBookMaintenance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.rf(12),
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              active.displayName(lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.rf(9.5),
                                height: 1.3,
                                color: scheme.onPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.rs(10),
                              vertical: context.rs(5),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              t.homeViewAll,
                              style: TextStyle(
                                fontSize: context.rf(9.5),
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
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
          ),
          SizedBox(width: context.rs(10)),
          // 2) تتبع الصيانة — light card.
          _TrioLightCard(
            icon: Icons.car_repair_rounded,
            title: t.trackTitle,
            subtitle: active.displayName(lang),
            onTap: () => context.push(Routes.tracking),
          ),
          SizedBox(width: context.rs(10)),
          // 3) طلباتي — light card, the orders hub.
          _TrioLightCard(
            icon: Icons.assignment_outlined,
            title: t.acMyOrders,
            subtitle: active.displayName(lang),
            onTap: () => context.push(Routes.tracking),
          ),
        ],
      ),
    );
  }
}

final class _TrioLightCard extends StatelessWidget {
  const _TrioLightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: context.rs(158),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(context.rs(12)),
            decoration: softCardDecoration(context, radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: context.rs(24),
                      height: context.rs(24),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 14, color: scheme.primary),
                    ),
                    SizedBox(width: context.rs(7)),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(12),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(9.5),
                          height: 1.3,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: scheme.primary,
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

/* ─────────────────────────── Greeting ─────────────────────────── */

/// Time-aware greeting on a LIVE brand panel: a primary-color gradient
/// that slowly "breathes" (its focus drifts side to side), the customer's
/// first name as the hero line, and a time-of-day icon roundel. The
/// animation only repaints this panel (AnimatedBuilder + RepaintBoundary;
/// the text/icon subtree is built once and passed as `child`), so it costs
/// a small gradient fill per frame — nothing else in the page rebuilds.
final class _Greeting extends StatefulWidget {
  const _Greeting({required this.lang});

  final String lang;

  @override
  State<_Greeting> createState() => _GreetingState();
}

final class _GreetingState extends State<_Greeting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = context.select((AuthBloc b) => b.state.user);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final (greeting, timeIcon) = hour < 12
        ? (t.acGoodMorning, Icons.light_mode_rounded)
        : hour < 17
            ? (t.acGoodAfternoon, Icons.wb_sunny_rounded)
            : (t.acGoodEvening, Icons.dark_mode_rounded);
    final first =
        (user?.displayName(widget.lang) ?? '').split(' ').firstOrNull ?? '';

    // Static subtree — built ONCE, animated gradient paints behind it.
    final content = Padding(
      padding: EdgeInsets.all(context.rs(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: context.rf(12.5),
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                if (first.isNotEmpty) ...[
                  SizedBox(height: context.rs(2)),
                  Text(
                    first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rf(22),
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
                SizedBox(height: context.rs(4)),
                Text(
                  t.acGreetingSub,
                  style: TextStyle(
                    fontSize: context.rf(11.5),
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rs(12)),
          // Time-of-day roundel on solid brand color.
          Container(
            width: context.rs(46),
            height: context.rs(46),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(timeIcon, size: 22, color: scheme.onPrimary),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rs(16),
        context.rs(14),
        context.rs(16),
        context.rs(4),
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _glow,
          child: content,
          builder: (context, child) {
            // Breathing brand wash: the gradient origin drifts across the
            // panel and back. Flat — no shadow, no border.
            final v = _glow.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: AlignmentDirectional(-1 + v * 1.2, -1),
                  end: AlignmentDirectional(1, 1 - v * 0.6),
                  colors: isDark
                      ? [
                          scheme.primary.withValues(alpha: 0.24),
                          const Color(0xFF15171C),
                        ]
                      : [
                          scheme.primary.withValues(alpha: 0.16),
                          scheme.primary.withValues(alpha: 0.03),
                        ],
                ),
              ),
              child: child,
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 320.ms, curve: Curves.easeOut).slideY(
        begin: 0.05, end: 0, duration: 340.ms, curve: Curves.easeOutCubic);
  }
}

/* ─────────────────────── Dynamic action card ─────────────────────── */

final class _DynamicCard extends StatelessWidget {
  const _DynamicCard({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rs(16),
        context.rs(12),
        context.rs(16),
        0,
      ),
      child: switch (home.cardKind) {
        'workorder' when home.workOrder != null => WorkOrderCard(
          order: home.workOrder!,
          lang: lang,
        ),
        'booking' when home.booking != null => _BookingCard(
          booking: home.booking!,
          lang: lang,
        ),
        'car' when home.car != null => _ActiveCarCard(home: home, lang: lang),
        _ => const _AddCarCard(),
      },
    );
  }
}

/// The 'car' dynamic card, but for the SELECTED garage car: when the user
/// taps another car the card follows it — refetching that car's next-PM
/// instead of showing the server-picked first car's plan.
final class _ActiveCarCard extends StatefulWidget {
  const _ActiveCarCard({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  State<_ActiveCarCard> createState() => _ActiveCarCardState();
}

final class _ActiveCarCardState extends State<_ActiveCarCard> {
  NextPm? _pm;
  String? _pmVin;

  @override
  Widget build(BuildContext context) {
    final brandKey = context.watch<settings.ThemeCubit>().state.brandKey;
    final activeVin = context.watch<ActiveCarCubit>().state;
    final active =
        resolveActiveCar(widget.home.garage, brandKey, activeVin) ??
        widget.home.car!;

    // Server already resolved the first car's plan; reuse it when it matches.
    if (active.vin == widget.home.car?.vin) {
      return _CarCard(
        car: active,
        nextPm: widget.home.nextPm,
        lang: widget.lang,
      );
    }
    if (_pmVin != active.vin) {
      _pmVin = active.vin;
      _pm = null;
      final user = sl<AuthBloc>().state.user;
      AccountRepository(sl<ApiClient>())
          .nextPm(
            vin: active.vin ?? '',
            modelCode: active.modelCode ?? '',
            userId: user?.userId,
          )
          .then((pm) {
            if (mounted && _pmVin == active.vin) setState(() => _pm = pm);
          });
    }
    return _CarCard(car: active, nextPm: _pm, lang: widget.lang);
  }
}

/// Live service tracking card — the ERP stage bar (verified statuses:
/// Open → InProcess → Under Test → Ready to Release → SentForPayment).
final class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.order, required this.lang});

  final WorkOrder order;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final stageLabels = [
      t.acStageReceived,
      t.acStageInProgress,
      t.acStageQuality,
      t.acStageReady,
      t.acStagePayment,
    ];
    final idx = order.stageIndex;
    final onBrand = scheme.onPrimary;

    return Container(
      padding: EdgeInsets.all(context.rs(18)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.2)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.car_repair_rounded, size: 16, color: onBrand),
              SizedBox(width: context.rs(7)),
              Expanded(
                child: Text(
                  order.readyToPay ? t.acCarReady : t.acCarInService,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rf(10.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: onBrand,
                  ),
                ),
              ),
              if ((order.plateNo ?? '').isNotEmpty)
                Text(
                  order.plateNo!,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: context.rf(11),
                    fontWeight: FontWeight.w700,
                    color: onBrand.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
          if (order.description(lang).isNotEmpty) ...[
            SizedBox(height: context.rs(12)),
            Text(
              order.description(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rf(16),
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: onBrand,
              ),
            ),
          ],
          SizedBox(height: context.rs(14)),
          StageBar(labels: stageLabels, activeIndex: idx, onBrand: true),
          if (order.readyToPay && (order.grandTotal ?? 0) > 0) ...[
            SizedBox(height: context.rs(12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.acAmountDue,
                  style: TextStyle(
                    fontSize: context.rf(12),
                    fontWeight: FontWeight.w700,
                    color: onBrand.withValues(alpha: 0.85),
                  ),
                ),
                PriceText(
                  price: (order.remaining ?? order.grandTotal)!,
                  currency: '',
                  contactForPrice: '',
                  fontSize: context.rf(16),
                  color: onBrand,
                ),
              ],
            ),
            if ((order.sadadNumber ?? '').isNotEmpty) ...[
              SizedBox(height: context.rs(4)),
              Text(
                '${t.acSadad}: ${order.sadadNumber}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: context.rf(11),
                  color: onBrand.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
          // بطاقة العمل + الدفع — the website JobCard cycle as an in-app
          // sheet (gateways: كامل المبلغ/تابي/تمارا/سداد).
          if ((order.guid ?? '').isNotEmpty) ...[
            SizedBox(height: context.rs(12)),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: scheme.primary,
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(
                    fontSize: context.rf(12.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () =>
                    showJobCardPaySheet(context, guid: order.guid!),
                icon: Icon(
                  order.readyToPay
                      ? Icons.payments_rounded
                      : Icons.receipt_long_rounded,
                  size: 17,
                ),
                label: Text(order.readyToPay ? t.jdPayNow : t.acJobCard),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact stage progress bar (dots + connectors + labels).
final class StageBar extends StatelessWidget {
  const StageBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    this.onBrand = false,
  });

  final List<String> labels;
  final int activeIndex;

  /// White-on-brand variant for the gradient hero card.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = onBrand ? scheme.onPrimary : scheme.primary;
    final inactive = onBrand
        ? scheme.onPrimary.withValues(alpha: 0.3)
        : scheme.outline.withValues(alpha: 0.4);
    final check = onBrand ? scheme.primary : scheme.onPrimary;
    final labelActive = active;
    final labelInactive = onBrand
        ? scheme.onPrimary.withValues(alpha: 0.55)
        : scheme.onSurface.withValues(alpha: 0.45);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              Container(
                width: context.rs(18),
                height: context.rs(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= activeIndex ? active : inactive,
                ),
                child: i < activeIndex
                    ? Icon(Icons.check, size: 12, color: check)
                    : null,
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2.4,
                    color: i < activeIndex ? active : inactive,
                  ),
                ),
            ],
          ],
        ),
        SizedBox(height: context.rs(6)),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == labels.length - 1
                      ? TextAlign.end
                      : TextAlign.center,
                  style: TextStyle(
                    fontSize: context.rf(8.5),
                    fontWeight: i == activeIndex
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: i <= activeIndex ? labelActive : labelInactive,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

final class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.lang});

  final UpcomingBooking booking;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final onBrand = scheme.onPrimary;
    final date = booking.orderdate == null
        ? ''
        : booking.orderdate!.toIso8601String().substring(0, 10);

    // "Friday, July 30, 2026 • 18:00" — localized long date like the mock.
    final longDate = booking.orderdate == null
        ? date
        : DateFormat('EEEE, d MMMM yyyy', lang).format(booking.orderdate!);
    final when = [
      longDate,
      (booking.ordertime ?? '').trim(),
    ].where((s) => s.isNotEmpty).join(' • ');

    // Note line (mock's "Traction control system update"): the booked
    // car's name resolved via chassis, else the booking reference.
    final garage = context.read<RegisteredHomeCubit>().state.home.garage;
    final bookedCar = garage
        .where(
          (c) =>
              (c.vin ?? '').isNotEmpty &&
              (booking.chassis ?? '').isNotEmpty &&
              c.vin == booking.chassis,
        )
        .firstOrNull;
    final note = bookedCar != null
        ? '${bookedCar.displayName(lang)} ${bookedCar.year ?? ''}'.trim()
        : (booking.receptionId ?? '').trim();

    return Container(
      padding: EdgeInsets.all(context.rs(20)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.24)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge line — icon + small bold uppercase label (mock style).
          Row(
            children: [
              Icon(Icons.event_repeat_rounded, size: 17, color: onBrand),
              SizedBox(width: context.rs(8)),
              Expanded(
                child: Text(
                  t.acUpcomingBooking.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rf(11),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: onBrand,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(14)),
          Text(
            booking.description(lang),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.rf(20),
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: onBrand,
            ),
          ),
          SizedBox(height: context.rs(10)),
          Text(
            when,
            style: TextStyle(
              fontSize: context.rf(13),
              fontWeight: FontWeight.w500,
              color: onBrand.withValues(alpha: 0.8),
            ),
          ),
          if (note.isNotEmpty) ...[
            SizedBox(height: context.rs(8)),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: onBrand.withValues(alpha: 0.85),
                ),
                SizedBox(width: context.rs(7)),
                Expanded(
                  child: Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rf(12.5),
                      fontWeight: FontWeight.w600,
                      color: onBrand.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: context.rs(18)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: onBrand,
                foregroundColor: scheme.primary,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TextStyle(
                  fontSize: context.rf(13.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () {
                final car =
                    resolveActiveCar(
                      garage,
                      sl<settings.ThemeCubit>().state.brandKey,
                      sl<ActiveCarCubit>().state,
                    ) ??
                    garage.firstOrNull;
                if (car != null) {
                  showMaintenanceBookingSheet(context, car: car);
                }
              },
              child: Text(t.ghBookMaintenance),
            ),
          ),
        ],
      ),
    );
  }
}

/// Appointment-card style (reference mock): white floating surface, a row of
/// status chips on top, avatar-style car thumb + bold name + info chips in
/// the middle, and soft-tinted pill actions at the bottom. Fully static
/// widgets — no per-frame work, cheap to rebuild.
final class _CarCard extends StatelessWidget {
  const _CarCard({required this.car, required this.nextPm, required this.lang});

  final GarageCar car;
  final NextPm? nextPm;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: softCardDecoration(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status chips row (Booked / Outpatient / Arrived analog) ──
          Row(
            children: [
              _StatusPill(
                icon: Icons.directions_car_filled_rounded,
                label: (car.year ?? '').isEmpty ? t.pfMyCars : car.year!,
                foreground: scheme.onSurface.withValues(alpha: 0.8),
                background: scheme.onSurface.withValues(
                  alpha: isDark ? 0.12 : 0.06,
                ),
              ),
              if (car.plate(lang).isNotEmpty) ...[
                SizedBox(width: context.rs(6)),
                _StatusPill(
                  label: car.maskedPlate(lang),
                  ltr: true,
                  foreground: const Color(0xFFB77400),
                  background: const Color(
                    0xFFB77400,
                  ).withValues(alpha: isDark ? 0.2 : 0.11),
                ),
              ],
              SizedBox(width: context.rs(6)),
              _StatusPill(
                label: t.acChipReady,
                foreground: const Color(0xFF1F9D55),
                background: const Color(
                  0xFF1F9D55,
                ).withValues(alpha: isDark ? 0.2 : 0.11),
              ),
            ],
          ),
          SizedBox(height: context.rs(14)),
          // ── Avatar-style thumb + name + info chips ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: context.rs(62),
                height: context.rs(62),
                padding: EdgeInsets.all(context.rs(7)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.7 : 1,
                  ),
                ),
                child: HomeImage(
                  url: car.image,
                  fit: BoxFit.contain,
                  logicalWidth: 62,
                ),
              ),
              SizedBox(width: context.rs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.displayName(lang)} ${car.year ?? ''}'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rf(15.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(14)),
          // ── Soft-tinted pill actions (the "View Details" look) ──
          Row(
            children: [
              Expanded(
                child: _SoftPillButton(
                  label: t.ghBookMaintenance,
                  foreground: scheme.primary,
                  background: scheme.primary.withValues(
                    alpha: isDark ? 0.2 : 0.09,
                  ),
                  onTap: () => showMaintenanceBookingSheet(context, car: car),
                ),
              ),
              SizedBox(width: context.rs(8)),
              Expanded(
                child: _SoftPillButton(
                  label: t.acCarDetails,
                  foreground: scheme.onSurface.withValues(alpha: 0.85),
                  background: scheme.onSurface.withValues(
                    alpha: isDark ? 0.12 : 0.05,
                  ),
                  onTap: () => showVehicleHubSheet(
                    context,
                    car: car,
                    onChanged: context.read<RegisteredHomeCubit>().load,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small tinted status/info chip (the mock's Booked/Outpatient/Arrived and
/// clinic/date chips).
final class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    this.ltr = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  /// Force LTR for plate numbers / odometer readings inside RTL text.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10),
        vertical: context.rs(5.5),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.rs(12), color: foreground),
            SizedBox(width: context.rs(4)),
          ],
          Text(
            label,
            textDirection: ltr ? TextDirection.ltr : null,
            style: TextStyle(
              fontSize: context.rf(10.5),
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-rounded soft-tinted action pill — the mock's "View Details" button.
final class _SoftPillButton extends StatelessWidget {
  const _SoftPillButton({
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: context.rs(44),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rf(12.5),
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _AddCarCard extends StatelessWidget {
  const _AddCarCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.rs(18)),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.directions_car_filled_outlined,
            size: 36,
            color: scheme.primary,
          ),
          SizedBox(height: context.rs(10)),
          Text(
            t.acNoCarsTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.rf(14.5),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: context.rs(4)),
          Text(
            t.acNoCarsSub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.rf(11.5),
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: context.rs(14)),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: const StadiumBorder(),
            ),
            onPressed: () => showAddCarSheet(
              context,
              onAdded: context.read<RegisteredHomeCubit>().load,
            ),
            child: Text(t.acAddCarCta),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── My garage ───────────────────────── */

final class _GarageSection extends StatelessWidget {
  const _GarageSection({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<RegisteredHomeCubit>();
    // Brand-scoped garage (Lexus theme → Lexus cars) + selectable active car.
    final brandKey = context.watch<settings.ThemeCubit>().state.brandKey;
    final cars = garageForBrand(home.garage, brandKey);
    final activeVin = context.watch<ActiveCarCubit>().state;
    final active = resolveActiveCar(home.garage, brandKey, activeVin);
    if (cars.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: t.acMyGarage,
          actionLabel: t.acAddCarShort,
          onAction: () => showAddCarSheet(context, onAdded: cubit.load),
        ),
        CardRail(
          height: context.rs(266),
          itemWidth: context.rs(300),
          itemCount: cars.length,
          itemBuilder: (context, i) {
            final car = cars[i];
            final scheme = Theme.of(context).colorScheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isActive = car.vin != null && car.vin == active?.vin;
            final subLine = [
              if ((car.year ?? '').toString().trim().isNotEmpty) '${car.year}',
              car.maskedPlate(lang).isEmpty
                  ? (car.vin ?? '')
                  : car.maskedPlate(lang),
            ].where((s) => s.trim().isNotEmpty).join(' • ');
            // Services-mock item: big rounded photo, roundel + bold name,
            // muted line, soft pill action — card-less, press feedback.
            return Pressable(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Tap = make this the active car (offers + protection
                // follow it). The hub opens from the roundel / pill.
                onTap: () => sl<ActiveCarCubit>().select(car.vin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover photo with ACTIVE badge + details roundel.
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFEDF1F7),
                              child: HomeImage(
                                url: car.image,
                                fit: BoxFit.cover,
                                logicalWidth: 300,
                              ),
                            ),
                            // Services-mock frosted fade into the page bg.
                            GlassBottomFade(height: context.rs(48)),
                            if (isActive)
                              PositionedDirectional(
                                top: context.rs(10),
                                end: context.rs(10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.rs(10),
                                    vertical: context.rs(4.5),
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size: 11,
                                        color: scheme.onPrimary,
                                      ),
                                      SizedBox(width: context.rs(3)),
                                      Text(
                                        t.acActiveBadge,
                                        style: TextStyle(
                                          fontSize: context.rf(9),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: scheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            PositionedDirectional(
                              top: context.rs(10),
                              start: context.rs(10),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => showVehicleHubSheet(
                                  context,
                                  car: car,
                                  onChanged: context
                                      .read<RegisteredHomeCubit>()
                                      .load,
                                ),
                                child: Container(
                                  width: context.rs(30),
                                  height: context.rs(30),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(
                                            0xFF181B21,
                                          ).withValues(alpha: 0.9)
                                        : Colors.white.withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    size: 15,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.rs(4),
                        context.rs(10),
                        context.rs(4),
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: context.rs(26),
                                height: context.rs(26),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(
                                    alpha: isDark ? 0.2 : 0.1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.directions_car_filled_rounded,
                                  size: context.rs(13),
                                  color: scheme.primary,
                                ),
                              ),
                              SizedBox(width: context.rs(8)),
                              Expanded(
                                child: Text(
                                  car.displayName(lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.rf(13.5),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                subLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: context.rf(10),
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rs(10)),
                          _SoftPillButton(
                            label: t.acCarDetails,
                            foreground: scheme.primary,
                            background: scheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.09,
                            ),
                            onTap: () => showVehicleHubSheet(
                              context,
                              car: car,
                              onChanged: context
                                  .read<RegisteredHomeCubit>()
                                  .load,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: (30 * (i % 5)).ms).fadeIn(duration: 240.ms);
          },
        ),
      ],
    );
  }
}

/* ─────────────────────── Quick actions ─────────────────────── */

/// "Quick Links"-style strip — thin wrapper over the shared
/// [QuickLinksPanel] (one white panel, filled primary tile, plain tiles,
/// scroll-progress bar).
final class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<RegisteredHomeCubit>();
    final primaryCar =
        resolveActiveCar(
          home.garage,
          sl<settings.ThemeCubit>().state.brandKey,
          sl<ActiveCarCubit>().state,
        ) ??
        home.garage.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: t.acQuickTitle),
        QuickLinksPanel(
          actions: [
            (
              Icons.build_rounded,
              t.ghBookMaintenance,
              () => primaryCar != null
                  ? showMaintenanceBookingSheet(context, car: primaryCar)
                  : showAddCarSheet(context, onAdded: cubit.load),
            ),
            (
              Icons.directions_car_rounded,
              t.acBuyCar,
              () => context.push(Routes.onlineStore),
            ),
            (
              Icons.settings_rounded,
              t.ghSpareParts,
              () => context.push(Routes.parts),
            ),
            (
              Icons.assignment_outlined,
              t.acMyOrders,
              () => context.push(Routes.tracking),
            ),
          ],
        ),
      ],
    );
  }
}

/* ─────────────────────── Active journeys ─────────────────────── */

final class _JourneysList extends StatelessWidget {
  const _JourneysList({required this.journeys, required this.lang});

  final List<Journey> journeys;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    (IconData, String) kindOf(Journey j) => switch (j.kind) {
      'workorder' => (Icons.car_repair_rounded, t.acJourneyService),
      'booking' => (Icons.event_available_rounded, t.acJourneyBooking),
      'finance' => (Icons.account_balance_outlined, t.acJourneyFinance),
      _ => (Icons.local_shipping_outlined, t.acJourneyOrder),
    };

    // Bilingual status text (orders carry statusAr/En in the payload).
    String statusOf(Journey j) {
      if (j.kind == 'order' && j.payload != null) {
        return (lang == 'ar' ? j.payload!['statusAr'] : j.payload!['statusEn'])
                ?.toString() ??
            j.status ??
            '';
      }
      return j.status ?? '';
    }

    // Credits-card style (wallet mock): bold kind title + tinted roundel
    // top-end, the order reference as the big line, and a bottom row of a
    // soft status pill + a dark square arrow button.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardRail(
      height: context.rs(140),
      itemWidth: context.rs(224),
      itemCount: journeys.take(8).length,
      itemBuilder: (context, i) {
        final j = journeys[i];
        final (icon, kindLabel) = kindOf(j);
        final status = statusOf(j);
        return HomeCard(
          onTap: () => _open(context, j),
          child: Padding(
            padding: EdgeInsets.all(context.rs(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // "HMG Wallet" position: bold kind label.
                    Expanded(
                      child: Text(
                        kindLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(13),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: context.rs(32),
                      height: context.rs(32),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 16, color: scheme.primary),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(6)),
                // The wallet's big value line → the order title/reference.
                Text(
                  j.title(lang).isEmpty ? kindLabel : j.title(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rf(12.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((j.reference ?? '').isNotEmpty) ...[
                  SizedBox(height: context.rs(2)),
                  Text(
                    j.reference!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: context.rf(9.5),
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                const Spacer(),
                // Bottom: soft status pill ("Add Funds" look) + dark arrow.
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: context.rs(32),
                        decoration: BoxDecoration(
                          color: j.needsAction
                              ? scheme.primary
                              : scheme.primary.withValues(
                                  alpha: isDark ? 0.2 : 0.09,
                                ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              j.needsAction
                                  ? Icons.priority_high_rounded
                                  : Icons.check_circle_rounded,
                              size: 13,
                              color: j.needsAction
                                  ? scheme.onPrimary
                                  : scheme.primary,
                            ),
                            SizedBox(width: context.rs(5)),
                            Flexible(
                              child: Text(
                                j.needsAction
                                    ? t.acActionNeeded
                                    : (status.isEmpty ? kindLabel : status),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.rf(10),
                                  fontWeight: FontWeight.w800,
                                  color: j.needsAction
                                      ? scheme.onPrimary
                                      : scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: context.rs(7)),
                    Container(
                      width: context.rs(32),
                      height: context.rs(32),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFF1A1C21),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, Journey j) =>
      _showJourneyDetailsSheet(context, j, lang);
}

/// Journey details sheet — one sheet for every kind: header + status chip,
/// key facts, then the kind-specific body (work-order stage bar + amounts,
/// store-order tracking timeline + pay-now, booking date/time, finance
/// status) with a follow-up action where one exists.
void _showJourneyDetailsSheet(BuildContext context, Journey j, String lang) {
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => _JourneyDetailsSheet(journey: j, lang: lang),
  );
}

final class _JourneyDetailsSheet extends StatelessWidget {
  const _JourneyDetailsSheet({required this.journey, required this.lang});

  final Journey journey;
  final String lang;

  String _p(String key) => (journey.payload?[key] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final j = journey;

    final (icon, kindLabel) = switch (j.kind) {
      'workorder' => (Icons.car_repair_rounded, t.acJourneyService),
      'booking' => (Icons.event_available_rounded, t.acJourneyBooking),
      'finance' => (Icons.account_balance_outlined, t.acJourneyFinance),
      _ => (Icons.local_shipping_outlined, t.acJourneyOrder),
    };
    final status = j.kind == 'order'
        ? ((lang == 'ar' ? _p('statusAr') : _p('statusEn')).isNotEmpty
              ? (lang == 'ar' ? _p('statusAr') : _p('statusEn'))
              : (j.status ?? ''))
        : (j.status ?? '');
    final date = j.date == null
        ? ''
        : j.date!.toIso8601String().substring(0, 10);

    Widget row(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        children: [
          const Center(child: SheetHandle()),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: scheme.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kindLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      j.title(lang).isEmpty ? kindLabel : j.title(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: j.needsAction
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: j.needsAction ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Key facts ──
          if ((j.reference ?? '').isNotEmpty)
            row(t.jdReference, j.reference!, ltr: true),
          if (date.isNotEmpty) row(t.jdDate, date, ltr: true),
          if (status.isNotEmpty) row(t.jdStatus, status),

          // ── Kind-specific body ──
          ...switch (j.kind) {
            'workorder' => _workOrderBody(context, t, scheme),
            'order' => _orderBody(context, t, scheme, row),
            'booking' => _bookingBody(t, row),
            'finance' => _financeBody(context, t),
            _ => const <Widget>[],
          },
        ],
      ),
    );
  }

  List<Widget> _workOrderBody(
    BuildContext context,
    AppLocalizations t,
    ColorScheme scheme,
  ) {
    final wo = journey.payload == null
        ? null
        : WorkOrder.fromJson(journey.payload!);
    if (wo == null) return const [];
    return [
      const SizedBox(height: 10),
      StageBar(
        labels: [
          t.acStageReceived,
          t.acStageInProgress,
          t.acStageQuality,
          t.acStageReady,
          t.acStagePayment,
        ],
        activeIndex: wo.stageIndex,
      ),
      if (wo.readyToPay && (wo.grandTotal ?? 0) > 0) ...[
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.acAmountDue,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            PriceText(
              price: (wo.remaining ?? wo.grandTotal)!,
              currency: '',
              contactForPrice: '',
              fontSize: 16,
            ),
          ],
        ),
        if ((wo.sadadNumber ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${t.acSadad}: ${wo.sadadNumber}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
      const SizedBox(height: 18),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: const StadiumBorder(),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          context.push(Routes.tracking);
        },
        icon: const Icon(Icons.podcasts_rounded, size: 17),
        label: Text(t.trackTitle),
      ),
    ];
  }

  List<Widget> _orderBody(
    BuildContext context,
    AppLocalizations t,
    ColorScheme scheme,
    Widget Function(String, String, {bool ltr}) row,
  ) {
    final total = _p('total');
    final sadad = _p('sadadNumber');
    final payUrl = _p('urlPayment');
    final cartId = int.tryParse(journey.reference ?? '');
    return [
      if (total.isNotEmpty && (double.tryParse(total) ?? 0) > 0)
        row(t.jdTotal, formatPrice(double.parse(total)), ltr: true),
      if (sadad.isNotEmpty) row(t.acSadad, sadad, ltr: true),
      if (payUrl.isNotEmpty) ...[
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: const StadiumBorder(),
          ),
          onPressed: () => launchUrl(
            Uri.parse(payUrl),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.payments_outlined, size: 17),
          label: Text(t.jdPayNow),
        ),
      ],
      const SizedBox(height: 16),
      Text(
        t.acOrderTracking,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      if (cartId == null)
        Center(child: Text(t.acNoTracking))
      else
        _OrderTimeline(cartId: cartId, lang: lang),
    ];
  }

  List<Widget> _bookingBody(
    AppLocalizations t,
    Widget Function(String, String, {bool ltr}) row,
  ) {
    final b = journey.payload == null
        ? null
        : UpcomingBooking.fromJson(journey.payload!);
    if (b == null) return const [];
    return [
      if ((b.ordertime ?? '').isNotEmpty)
        row(t.mbStep3Title, (b.ordertime ?? '').trim(), ltr: true),
      if ((b.price ?? 0) > 0) row(t.jdTotal, formatPrice(b.price!), ltr: true),
      if ((b.receptionId ?? '').isNotEmpty)
        row(t.jdReference, b.receptionId!, ltr: true),
    ];
  }

  List<Widget> _financeBody(BuildContext context, AppLocalizations t) => [
    const SizedBox(height: 12),
    FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        shape: const StadiumBorder(),
      ),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.push(Routes.financeRequests);
      },
      icon: const Icon(Icons.request_quote_outlined, size: 17),
      label: Text(t.finReqTitle),
    ),
  ];
}

/// Store-order tracking timeline (Site_GetTrackingOFCart) — the same event
/// list the website renders.
final class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.cartId, required this.lang});

  final int cartId;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<OrderTrackingStep>>(
      future: AccountRepository(sl<ApiClient>()).orderTracking(cartId),
      builder: (context, snap) {
        final steps = snap.data ?? const <OrderTrackingStep>[];
        if (snap.connectionState != ConnectionState.done) {
          return SkeletonList(itemCount: 3, itemHeight: context.rs(56));
        }
        if (steps.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Center(child: Text(t.acNoTracking)),
          );
        }
        return Column(
          children: [
            for (final (i, s) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == steps.length - 1
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Container(
                            width: 2,
                            height: 26,
                            color: scheme.outline.withValues(alpha: 0.4),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.description(lang),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (s.createdAt != null)
                            Text(
                              s.createdAt!
                                  .toIso8601String()
                                  .substring(0, 16)
                                  .replaceAll('T', ' '),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/* ────────────── Protection packages for MY car (home) ────────────── */

final class _ProtCarCubit extends Cubit<(int, List<ProtectionPackage>, bool)> {
  _ProtCarCubit(this._cars) : super((0, const [], true)) {
    if (_cars.isNotEmpty) select(0);
  }

  final List<GarageCar> _cars;

  Future<void> select(int i) async {
    final car = _cars.elementAtOrNull(i);
    if (car == null || (car.type ?? '').isEmpty) return;
    emit((i, const [], true));
    final result = await ProtectionRepository(
      sl<ApiClient>(),
    ).protectionByModel(car.type!, car.brandDbId ?? '1');
    if (isClosed) return;
    emit((i, result?.services ?? const [], false));
  }
}

/// Car picker for the protection section's brand-pill dropdown.
void _pickProtectionCar(
  BuildContext context,
  List<GarageCar> cars,
  int sel,
  String lang,
  void Function(int) onPick,
) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 10),
          for (final (i, c) in cars.indexed)
            ListTile(
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                onPick(i);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              title: Text(
                '${c.displayName(lang)} ${c.year ?? ''}'.trim(),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: i == sel
                  ? Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: scheme.primary,
                    )
                  : null,
            ),
        ],
      ),
    ),
  );
}

/// "باقات الحماية لسيارتك" — the catalog resolved from the selected garage
/// car's productTypeID; tap opens the detail + pay cycle.
final class _ProtectionForCar extends StatelessWidget {
  const _ProtectionForCar({required this.garage, required this.lang});

  final List<GarageCar> garage;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Brand-scoped + the ACTIVE garage car leads (its packages by default).
    final brandKey = context.watch<settings.ThemeCubit>().state.brandKey;
    final activeVin = context.watch<ActiveCarCubit>().state;
    final active = resolveActiveCar(garage, brandKey, activeVin);
    final cars =
        garageForBrand(
          garage,
          brandKey,
        ).where((c) => (c.type ?? '').isNotEmpty).toList()..sort(
          (a, b) => (b.vin == active?.vin ? 1 : 0).compareTo(
            a.vin == active?.vin ? 1 : 0,
          ),
        );
    return BlocProvider(
      key: ValueKey('prot-${cars.length}-${active?.vin}'),
      create: (_) => _ProtCarCubit(cars),
      child: Builder(
        builder: (context) {
          final (sel, packages, loading) = context.watch<_ProtCarCubit>().state;
          final cubit = context.read<_ProtCarCubit>();
          final car = cars.elementAtOrNull(sel);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: t.homeProtForCar,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.protection),
              ),
              // Car selector — the mock's solid brand pill dropdown.
              if (car != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.rs(16),
                    0,
                    context.rs(16),
                    0,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: cars.length < 2
                          ? null
                          : () => _pickProtectionCar(
                              context,
                              cars,
                              sel,
                              lang,
                              cubit.select,
                            ),
                      child: Ink(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(14),
                          vertical: context.rs(12),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Color.lerp(
                                Theme.of(context).colorScheme.primary,
                                Colors.black,
                                0.2,
                              )!,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: context.rs(30),
                              height: context.rs(30),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_car_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: context.rs(10)),
                            Expanded(
                              child: Text(
                                '${car.displayName(lang)} ${car.year ?? ''}'
                                    .trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.rf(13),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (cars.length > 1)
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: context.rs(14)),
              if (loading)
                SkeletonRail(
                  height: context.rs(248),
                  itemWidth: context.rs(236),
                )
              else if (packages.isEmpty)
                Padding(
                  padding: EdgeInsets.all(context.rs(20)),
                  child: Center(child: Text(t.protNoPackages)),
                )
              else
                CardRail(
                  height: context.rs(248),
                  itemWidth: context.rs(236),
                  itemCount: packages.length,
                  itemBuilder: (context, i) {
                    final p = packages[i];
                    final scheme = Theme.of(context).colorScheme;
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    // Tier palette from the package NAME (gold ذهبية, silver
                    // فضية, bronze برونزية, diamond ماسية) — drives the card
                    // wash, roundel, badge and CTA.
                    final tier = packageTierColors(p.name(lang), scheme);
                    void open() => showProtectionDetailSheet(
                      context,
                      package: p,
                      vehicleLabel: car == null
                          ? null
                          : '${car.displayName(lang)} ${car.year ?? ''}'.trim(),
                      vin: car?.vin,
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
                            // Clipped to the rounded shape: the watermark
                            // below is deliberately bled past the corner.
                            clipBehavior: Clip.antiAlias,
                            // Tier-colored overlay wash over the card surface.
                            decoration: softCardDecoration(
                              context,
                              radius: 20,
                              tint: tier.color,
                            ),
                            child: Stack(
                              // Tight constraints on the content column so it
                              // fills the card exactly as it did before the
                              // watermark layer was introduced.
                              fit: StackFit.expand,
                              children: [
                                // Brand emblem — LARGE, vertically centered,
                                // bleeding off the far edge (left in Arabic)
                                // at a whisper of opacity.
                                PositionedDirectional(
                                  end: -context.rs(30),
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: BrandMark(
                                      size: context.rs(150),
                                      color: tier.deep,
                                      opacity: isDark ? 0.08 : 0.06,
                                    ),
                                  ),
                                ),
                                Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name leads the card and the shield moves to
                                // the far side: the old layout burned a whole
                                // band on an icon before the customer ever
                                // read which package they were looking at.
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name(lang),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: context.rf(13.5),
                                              fontWeight: FontWeight.w800,
                                              height: 1.25,
                                            ),
                                          ),
                                          if (i == 0) ...[
                                            SizedBox(height: context.rs(5)),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: context.rs(8),
                                                vertical: context.rs(3),
                                              ),
                                              decoration: BoxDecoration(
                                                color: tier.color.withValues(
                                                  alpha: isDark ? 0.3 : 0.18,
                                                ),
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
                                                      : tier.deep,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: context.rs(8)),
                                    Container(
                                      width: context.rs(34),
                                      height: context.rs(34),
                                      decoration: BoxDecoration(
                                        color: tier.color.withValues(
                                          alpha: isDark ? 0.3 : 0.18,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        packageTierIcon(p.name(lang)),
                                        size: 17,
                                        color: isDark ? tier.color : tier.deep,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: context.rs(8)),
                                Expanded(
                                  child: Text(
                                    p.description(lang).replaceAll('\n', ' '),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: context.rf(11),
                                      height: 1.45,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                ),
                                PriceText(
                                  price: p.price,
                                  currency: '',
                                  contactForPrice: t.homeContactForPrice,
                                  fontSize: context.rf(15),
                                  color: isDark ? tier.color : tier.deep,
                                ),
                                SizedBox(height: context.rs(10)),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      // CTA follows the package tier color.
                                      backgroundColor: tier.color,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(64, 42),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: context.rf(12),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    onPressed: open,
                                    child: Text(t.protSelectPackage),
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
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/* ───────────────────────── Offers tabs ───────────────────────── */

/// "لك | عروض السيارات | عروض الصيانة" — one /offers payload, tabbed.
/// "For you" personalizes by the user's own car brand (spec R1 level).
final class _OffersTabs extends StatelessWidget {
  const _OffersTabs({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final offersState = context.watch<OffersCubit>().state;
    if (offersState.status != OffersStatus.ready ||
        offersState.offers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Visibility follows the ACTIVE THEME brand (Toyota theme → Toyota
    // offers), exactly like the offers page; the user's car only powers the
    // "لسيارتك" badge + ordering.
    final themeBrand = context.select(
      (settings.ThemeCubit c) => c.state.brandKey == 'lexus' ? '2' : '1',
    );
    // "لك" matches against ALL the user's cars: an offer shows only when
    // one of their cars is in its supported list.
    final cars = home.garage;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: OffersRepository(sl<ApiClient>()).supportedMap(),
      builder: (context, snap) {
        final matched = <int>{};
        for (final row in snap.data ?? const <Map<String, dynamic>>[]) {
          final offerId = int.tryParse('${row['offerId'] ?? row['OfferId']}');
          if (offerId == null) continue;
          final type = '${row['productTypeId'] ?? row['ProductTypeId'] ?? ''}';
          final group = '${row['groupId'] ?? row['GroupId'] ?? ''}';
          final brand = '${row['brandId'] ?? row['BrandId'] ?? ''}';
          final hit = cars.any(
            (car) =>
                (type.isNotEmpty && type == car.type) ||
                (group.isNotEmpty && group == car.productGroupId) ||
                (type.isEmpty && group.isEmpty && brand == car.brandDbId),
          );
          if (hit) matched.add(offerId);
        }
        return _OffersTabsBody(
          offers: offersState.offers,
          now: offersState.now ?? DateTime.now(),
          carBrandDbId: themeBrand,
          matchedOfferIds: matched,
          lang: lang,
          title: t.acOffersForYou,
        );
      },
    );
  }
}

final class _OffersTabsBody extends StatelessWidget {
  const _OffersTabsBody({
    required this.offers,
    required this.now,
    required this.carBrandDbId,
    required this.lang,
    required this.title,
    this.matchedOfferIds = const {},
  });

  final List<SiteOffer> offers;
  final DateTime now;
  final String? carBrandDbId;
  final Set<int> matchedOfferIds;
  final String lang;
  final String title;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => _TabCubit(),
      child: Builder(
        builder: (context) {
          final tab = context.watch<_TabCubit>().state;
          final filtered =
              offers.where((o) {
                  final visible =
                      carBrandDbId == null || o.visibleForBrand(carBrandDbId);
                  return switch (tab) {
                    1 => o.typeId == 2 && visible,
                    2 => o.typeId == 3 && visible,
                    // "لك": ONLY offers whose supported cars include one of mine.
                    _ => visible && matchedOfferIds.contains(o.id),
                  };
                }).toList()
                // "لك": offers matching my car float to the front.
                ..sort(
                  (a, b) => (matchedOfferIds.contains(b.id) ? 1 : 0).compareTo(
                    matchedOfferIds.contains(a.id) ? 1 : 0,
                  ),
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: title,
                actionLabel: t.homeViewAll,
                onAction: () => context.push(Routes.offers),
              ),
              FilterChipsRow(
                labels: [t.acTabForYou, t.homeVehicleOffers, t.ghMaintOffers],
                selectedIndex: tab,
                onSelected: context.read<_TabCubit>().set,
              ),
              SizedBox(height: context.rs(12)),
              if (filtered.isEmpty)
                Padding(
                  padding: EdgeInsets.all(context.rs(24)),
                  child: Center(child: Text(t.offersEmpty)),
                )
              else
                CardRail(
                  // Trimmed with the reserved excerpt slot in OfferCard so
                  // the countdown sits just under the text instead of after
                  // a dead gap.
                  height: context.rs(368),
                  itemWidth: context.rs(310),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => OfferCard(
                    offer: filtered[i],
                    lang: lang,
                    now: now,
                    forMyCar: matchedOfferIds.contains(filtered[i].id),
                    expand: true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

final class _TabCubit extends Cubit<int> {
  _TabCubit() : super(0);
  void set(int i) => emit(i);
}
