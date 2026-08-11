import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/di/injector.dart';
import '../../core/utils/responsive.dart';
import '../../features/home/presentation/widgets/home_bits.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/onboarding/domain/onboarding_slide.dart';
import '../../features/settings/bloc/theme_cubit.dart';

/// The teal-mock "slope" clip: a full-width solid block whose bottom edge is
/// one gentle downward arc. Mirrored for RTL so the low side always trails
/// the reading direction.
final class SlopeClipper extends CustomClipper<Path> {
  const SlopeClipper({required this.rtl});

  final bool rtl;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    double x(double v) => rtl ? w - v : v;
    return Path()
      ..moveTo(x(0), 0)
      ..lineTo(x(0), h * 0.88)
      ..quadraticBezierTo(x(w * 0.45), h * 1.04, x(w), h * 0.70)
      ..lineTo(x(w), 0)
      ..close();
  }

  @override
  bool shouldReclip(SlopeClipper oldClipper) => oldClipper.rtl != rtl;
}

/// The reference-mock sheet header: a solid curved "slope" blob filled with
/// the model's resolved background — dashboard 'car_bg' placement match →
/// the model's shared Background artwork → brand gradient — carrying the
/// eyebrow + big model name, with the car image overlapping the slope's
/// bottom curve (~55% inside / 45% below).
final class SlopeHero extends StatefulWidget {
  const SlopeHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.car,
    this.modelKey,
    this.year,
    this.background,
    this.topBar,
    this.slopeHeight = 240,
    this.carHeight = 190,
  });

  /// Small overline ('BRAND · YEAR') drawn above the title.
  final String eyebrow;

  /// The big model name on the slope.
  final String title;

  /// The car image block (caller keeps its Hero / color-following wiring).
  final Widget car;

  /// Model name key matched against the dashboard 'car_bg' placement
  /// (TitleEn = lowercase "model year" key). Falls back to [title].
  final String? modelKey;
  final String? year;

  /// The model's shared Background artwork (already language-resolved) —
  /// used when no 'car_bg' placement matches.
  final String? background;

  /// Optional bar pinned to the top of the slope (back / actions, white).
  final Widget? topBar;

  final double slopeHeight;
  final double carHeight;

  /// Fraction of the car that hangs BELOW the slope's bottom curve.
  static const double carOverlap = 0.45;

  @override
  State<SlopeHero> createState() => _SlopeHeroState();
}

final class _SlopeHeroState extends State<SlopeHero> {
  /// Dashboard 'car_bg' slides per brand — fetched once per session.
  static final Map<String, List<OnboardingSlide>> _bgCache = {};

  List<OnboardingSlide> _bgs = const [];

  @override
  void initState() {
    super.initState();
    final brandKey = sl<ThemeCubit>().state.brandKey;
    final cached = _bgCache[brandKey];
    if (cached != null) {
      _bgs = cached;
      return;
    }
    sl<OnboardingRepository>().fetch(brandKey, placement: 'car_bg').then((s) {
      _bgCache[brandKey] = s;
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final slopeH = context.rs(widget.slopeHeight);
    final carH = context.rs(widget.carHeight);
    final bg = _bgFor(
            (widget.modelKey ?? widget.title).trim(), widget.year) ??
        ((widget.background ?? '').trim().isEmpty ? null : widget.background);

    return RepaintBoundary(
      child: SizedBox(
        height: slopeH + carH * SlopeHero.carOverlap,
        child: Stack(
          children: [
            // ── The slope blob: image/GIF backdrop or brand gradient ──
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              height: slopeH,
              child: ClipPath(
                clipper: SlopeClipper(rtl: rtl),
                child: Stack(fit: StackFit.expand, children: [
                  if (bg != null) ...[
                    HomeImage(url: bg, fit: BoxFit.cover, logicalWidth: 480),
                    // Subtle dark scrim so the white text stays legible.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [
                            Color.lerp(scheme.primary, Colors.black, 0.2)!,
                            Color.lerp(scheme.primary, Colors.black, 0.55)!,
                          ],
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            // ── Eyebrow + big model name on the slope ──
            PositionedDirectional(
              top: context.rs(widget.topBar == null ? 22 : 58),
              start: context.rs(24),
              end: context.rs(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rf(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(height: context.rs(6)),
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rf(30),
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 260.ms)
                  .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
            ),
            // ── Optional top bar (back / actions) pinned over the slope ──
            if (widget.topBar != null)
              PositionedDirectional(
                  top: 0, start: 0, end: 0, child: widget.topBar!),
            // ── The car, overlapping the slope's bottom curve ──
            PositionedDirectional(
              start: context.rs(12),
              end: context.rs(12),
              top: slopeH - carH * (1 - SlopeHero.carOverlap),
              height: carH,
              child: widget.car
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 80.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round white-on-slope icon button for [SlopeHero.topBar].
final class SlopeBarButton extends StatelessWidget {
  const SlopeBarButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: context.rs(34),
        height: context.rs(34),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
