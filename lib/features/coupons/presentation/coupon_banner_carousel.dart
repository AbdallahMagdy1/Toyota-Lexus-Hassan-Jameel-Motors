import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_dots.dart';
import '../../home/presentation/widgets/home_bits.dart' show HomeImage;
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../data/coupons_repository.dart';
import '../domain/coupon_models.dart';

/// Home coupon banners — the mobile take on the website's
/// CouponBannerCarousel: same content order (eyebrow → title → subtitle →
/// details → tap-to-copy code chip → supported vehicles) as a swipeable
/// card carousel that auto-advances every 6 s. Renders nothing when the
/// brand has no "show on home" coupons.
final class CouponBannerCarousel extends StatefulWidget {
  const CouponBannerCarousel({super.key});

  @override
  State<CouponBannerCarousel> createState() => _CouponBannerCarouselState();
}

final class _CouponBannerCarouselState extends State<CouponBannerCarousel> {
  final _page = PageController(viewportFraction: 0.92);
  List<CouponBanner> _banners = const [];
  int _index = 0;
  String? _copied;
  String? _fetchedFor;
  Timer? _auto;
  Timer? _copyReset;

  @override
  void dispose() {
    _auto?.cancel();
    _copyReset?.cancel();
    _page.dispose();
    super.dispose();
  }

  Future<void> _load(String brandKey) async {
    final list = await CouponsRepository(sl<ApiClient>())
        .homeBanners(brand: brandKey == 'lexus' ? 2 : 1);
    if (!mounted) return;
    setState(() {
      _banners = list.where((b) => b.renderable).toList();
      _index = 0;
    });
    if (_page.hasClients) _page.jumpToPage(0);
    _restartAuto();
  }

  void _restartAuto() {
    _auto?.cancel();
    if (_banners.length < 2) return;
    _auto = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_page.hasClients || _banners.length < 2) return;
      _page.animateToPage(
        (_index + 1) % _banners.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = code);
    _copyReset?.cancel();
    _copyReset = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = null);
    });
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).cpnCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final brandKey = context.watch<ThemeCubit>().state.brandKey;
    if (brandKey != _fetchedFor) {
      _fetchedFor = brandKey;
      _load(brandKey);
    }
    if (_banners.isEmpty) return const SizedBox.shrink();

    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsetsDirectional.only(
          top: context.rs(14), bottom: context.rs(4)),
      child: Column(children: [
        SizedBox(
          height: context.rs(185),
          child: PageView.builder(
            controller: _page,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding:
                  EdgeInsetsDirectional.symmetric(horizontal: context.rs(5)),
              child: _BannerCard(
                banner: _banners[i],
                lang: lang,
                copied: _copied,
                onCopy: _copy,
              ),
            ),
          ),
        ),
        if (_banners.length > 1)
          Padding(
            padding: EdgeInsetsDirectional.only(top: context.rs(10)),
            child: PageDots(
              count: _banners.length,
              index: _index,
              activeColor: scheme.primary,
            ),
          ),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}

/// One coupon card — dark immersive surface: the admin banner image (with a
/// 45% black overlay for legibility) or the brand-glow gradient fallback the
/// registered-home hero uses. All text on the card is white.
final class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.lang,
    required this.copied,
    required this.onCopy,
  });

  final CouponBanner banner;
  final String lang;
  final String? copied;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasImage = (banner.bannerImageUrl ?? '').isNotEmpty;
    // Brand accent lifted toward white so it stays legible on the dark card.
    final accent = Color.lerp(scheme.primary, Colors.white, 0.35)!;
    final code = (banner.code ?? '').trim();
    final subtitle = banner.subtitle(lang);
    final details = banner.details(lang);
    final vehicles = banner.vehicles.take(6).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF121317),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Stack(fit: StackFit.expand, children: [
        // ── Backdrop: admin banner media, else brand radial glow ──
        if (hasImage) ...[
          HomeImage(
            url: banner.bannerImageUrl,
            fit: BoxFit.cover,
            logicalWidth: 400,
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
        ] else ...[
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const AlignmentDirectional(-0.7, -0.9),
                  radius: 1.3,
                  colors: [
                    scheme.primary.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
        // ── Content ──
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
              context.rs(14), context.rs(12), context.rs(14), context.rs(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow.
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.confirmation_number_outlined,
                    size: 13, color: accent),
                SizedBox(width: context.rs(5)),
                Text(
                  t.cpnExclusive.toUpperCase(),
                  style: TextStyle(
                    fontSize: context.rf(9.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: accent,
                  ),
                ),
              ]),
              SizedBox(height: context.rs(3)),
              // Title / subtitle / details.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      banner.title(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rf(15),
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: context.rs(2)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(11),
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                    if (details.isNotEmpty) ...[
                      SizedBox(height: context.rs(2)),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(10),
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Tap-to-copy code chip (dashed-look border, LTR).
              if (code.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onCopy(code),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.symmetric(vertical: context.rs(4)),
                    child: Container(
                      padding: EdgeInsetsDirectional.symmetric(
                          horizontal: context.rs(12), vertical: context.rs(5)),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accent, width: 1.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.ltr,
                        children: [
                          Icon(
                            copied == code
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            size: 13,
                            color: accent,
                          ),
                          SizedBox(width: context.rs(6)),
                          Text(
                            code,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Supported vehicles.
              if (vehicles.isNotEmpty) ...[
                SizedBox(height: context.rs(6)),
                SizedBox(
                  height: context.rs(28),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) => SizedBox(width: context.rs(6)),
                    itemBuilder: (context, i) =>
                        _VehicleChip(vehicle: vehicles[i], lang: lang),
                  ),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

final class _VehicleChip extends StatelessWidget {
  const _VehicleChip({required this.vehicle, required this.lang});

  final CouponVehicle vehicle;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final years = vehicle.yearRange;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.rs(8), vertical: context.rs(2)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if ((vehicle.image ?? '').isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 36,
              height: 24,
              child: HomeImage(
                  url: vehicle.image, fit: BoxFit.contain, logicalWidth: 36),
            ),
          ),
          SizedBox(width: context.rs(6)),
        ],
        Text(
          '${vehicle.brand(lang)} ${vehicle.group(lang)}'.trim(),
          style: TextStyle(
            fontSize: context.rf(10),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (years.isNotEmpty) ...[
          SizedBox(width: context.rs(5)),
          Text(
            years,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: context.rf(9.5),
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ]),
    );
  }
}
