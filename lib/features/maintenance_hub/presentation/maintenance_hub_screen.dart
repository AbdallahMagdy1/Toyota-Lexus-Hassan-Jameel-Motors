import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/page_dots.dart';
import '../../account/bloc/active_car_cubit.dart';
import '../../account/data/account_repository.dart';
import '../../account/domain/account_models.dart';
import '../../account/presentation/garage_sheets.dart' show showAddCarSheet;
import '../../account/presentation/maintenance_booking_sheet.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../offers/bloc/offers_cubit.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/offers_screen.dart' show OfferCard;
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/maintenance_hub_cubit.dart';
import '../data/maintenance_hub_repository.dart';
import '../domain/maintenance_hub_models.dart';

/// The website's WhatsApp advisor line (wa.me on /maintenance).
const _kWhatsAppUrl = 'https://wa.me/966920018996';

/// خدمات الصيانة — the mobile mirror of toyotahj.com/maintenance (and its
/// /maintenance/periodic sub-page): hero + stats, the 4-step journey,
/// maintenance offers, the "why Hassan Jameel" comparison + guest feedback,
/// the periodic km schedule and the final booking CTA.
final class MaintenanceHubScreen extends StatelessWidget {
  const MaintenanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => MaintenanceHubCubit(
                MaintenanceHubRepository(sl<ApiClient>()))),
        BlocProvider(
            create: (_) => OffersCubit(OffersRepository(sl<ApiClient>()))),
      ],
      child: const _HubView(),
    );
  }
}

/// Opens the existing 3-step booking sheet for the user's ACTIVE car; empty
/// garage → the add-car sheet; guests → the sheet's own manual car cascade.
Future<void> _book(BuildContext context) async {
  final user = sl<AuthBloc>().state.user;
  if (user == null) {
    showMaintenanceBookingSheet(context);
    return;
  }
  final repo = AccountRepository(sl<ApiClient>());
  var garage =
      (await repo.cachedHomeDisk(user.userId))?.garage ?? const <GarageCar>[];
  if (garage.isEmpty) garage = await repo.garage(user.userId);
  if (!context.mounted) return;
  final car = resolveActiveCar(
      garage, sl<ThemeCubit>().state.brandKey, sl<ActiveCarCubit>().state);
  if (car != null) {
    showMaintenanceBookingSheet(context, car: car);
  } else {
    showAddCarSheet(context);
  }
}

final class _HubView extends StatefulWidget {
  const _HubView();

  @override
  State<_HubView> createState() => _HubViewState();
}

final class _HubViewState extends State<_HubView> {
  final _periodicKey = GlobalKey();

  void _jumpToPeriodic() {
    final ctx = _periodicKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const AppHeader(),
      Expanded(
        child: ListView(
          padding: EdgeInsets.only(bottom: context.rs(140)),
          children: [
            _Hero(onPeriodic: _jumpToPeriodic),
            const _Stats(),
            const _Journey(),
            const _HubOffers(),
            const _WhyUs(),
            const _Feedback(),
            _PeriodicSchedule(key: _periodicKey),
            const _BottomCta(),
          ],
        ),
      ),
    ]);
  }
}

/* ───────────────────────────── Hero ───────────────────────────── */

final class _Hero extends StatelessWidget {
  const _Hero({required this.onPeriodic});

  final VoidCallback onPeriodic;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget chip(IconData icon, String label) => Container(
          padding: EdgeInsets.symmetric(
              horizontal: context.rs(10), vertical: context.rs(6)),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: scheme.primary),
            SizedBox(width: context.rs(5)),
            Text(label,
                style: TextStyle(
                    fontSize: context.rf(9.5),
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.75))),
          ]),
        );

    // Floating maintenance icon chips — the website hero's signature motion,
    // scaled down: three soft roundels drifting gently behind the copy.
    Widget floatChip(IconData icon, double size, double delayMs) =>
        RepaintBoundary(
          child: Container(
            width: context.rs(size),
            height: context.rs(size),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.rs(size) * 0.3),
              border:
                  Border.all(color: scheme.primary.withValues(alpha: 0.25)),
            ),
            child:
                Icon(icon, size: context.rs(size) * 0.42, color: scheme.primary),
          )
              .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                  delay: delayMs.ms)
              .moveY(
                  begin: -context.rs(5),
                  end: context.rs(5),
                  duration: 2800.ms,
                  curve: Curves.easeInOut),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(16), context.rs(20), 0),
      child: Stack(children: [
        PositionedDirectional(
            end: context.rs(2), top: context.rs(6), child: floatChip(Icons.build_rounded, 52, 0)),
        PositionedDirectional(
            end: context.rs(52),
            top: context.rs(88),
            child: floatChip(Icons.settings_rounded, 38, 400)),
        PositionedDirectional(
            end: context.rs(10),
            top: context.rs(150),
            child: floatChip(Icons.speed_rounded, 30, 800)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          chip(Icons.verified_user_outlined, t.mhHeroBadge)
              .animate()
              .fadeIn(duration: 260.ms),
          SizedBox(height: context.rs(14)),
          // Two-tone oversized title, like the website's "احجز صيانتك / في 10 ثوانٍ".
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '${t.mhHeroTitle}\n'),
              TextSpan(
                  text: t.mhHeroAccent,
                  style: TextStyle(color: scheme.primary)),
            ]),
            style: TextStyle(
              fontSize: context.rf(34),
              height: 1.22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0),
          SizedBox(height: context.rs(10)),
          Text(
            t.mhHeroSub,
            style: TextStyle(
                fontSize: context.rf(12.5),
                height: 1.6,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ).animate(delay: 90.ms).fadeIn(duration: 300.ms),
          SizedBox(height: context.rs(18)),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: TextStyle(
                      fontSize: context.rf(13.5),
                      fontWeight: FontWeight.w800),
                ),
                onPressed: () => _book(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: Text(t.mhReserveNow),
              ),
            ),
            SizedBox(width: context.rs(10)),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.6)),
                  foregroundColor: scheme.primary,
                  textStyle: TextStyle(
                      fontSize: context.rf(13),
                      fontWeight: FontWeight.w800),
                ),
                onPressed: onPeriodic,
                icon: const Icon(Icons.build_circle_outlined, size: 17),
                label: Text(t.mhPeriodic),
              ),
            ),
          ]).animate(delay: 150.ms).fadeIn(duration: 300.ms),
          SizedBox(height: context.rs(14)),
          Wrap(spacing: context.rs(8), runSpacing: context.rs(8), children: [
            chip(Icons.workspace_premium_outlined, t.mhBadgeCertified),
            chip(Icons.check_circle_outline_rounded, t.mhBadgeSaso),
          ]).animate(delay: 200.ms).fadeIn(duration: 300.ms),
        ]),
      ]),
    );
  }
}

/* ─────────────────────────── Stats 2×2 ─────────────────────────── */

final class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    // The website hero's tiles: 60+ years / 400K+ cars / 95%+ / 2 branches.
    final stats = <(IconData, String, String)>[
      (Icons.workspace_premium_outlined, '+60', t.mhYears),
      (Icons.directions_car_filled_outlined, '+400K', t.mhCars),
      (Icons.star_border_rounded, '%95+', t.mhSatisfaction),
      (Icons.location_on_outlined, '2', t.mhBranches),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(22), context.rs(20), 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: context.rs(10),
        crossAxisSpacing: context.rs(10),
        childAspectRatio: 1.55,
        children: [
          for (final (i, (icon, value, label)) in stats.indexed)
            RepaintBoundary(
              child: Container(
                padding: EdgeInsets.all(context.rs(13)),
                decoration: softCardDecoration(context, radius: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.rs(30),
                      height: context.rs(30),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 15, color: scheme.primary),
                    ),
                    const Spacer(),
                    Text(value,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            fontSize: context.rf(20),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(9.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color:
                                scheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ).animate(delay: (60 * i).ms).fadeIn(duration: 280.ms).slideY(
                  begin: 0.06, end: 0, curve: Curves.easeOut),
            ),
        ],
      ),
    );
  }
}

/* ─────────────────────── Journey (4 steps) ─────────────────────── */

final class _Journey extends StatelessWidget {
  const _Journey();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final steps = <(String, String)>[
      (t.mhStep1, t.mhStep1Sub),
      (t.mhStep2, t.mhStep2Sub),
      (t.mhStep3, t.mhStep3Sub),
      (t.mhStep4, t.mhStep4Sub),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: t.mhJourney, subtitle: t.mhJourneySub),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
        child: Column(children: [
          for (final (i, (title, sub)) in steps.indexed)
            RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: i == steps.length - 1 ? 0 : context.rs(10)),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Number bubble + connector (vertical timeline).
                      Column(children: [
                        Container(
                          width: context.rs(34),
                          height: context.rs(34),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: context.rf(14),
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onPrimary)),
                        ),
                        if (i != steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 1.4,
                              margin: EdgeInsets.symmetric(
                                  vertical: context.rs(4)),
                              color:
                                  scheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                      ]),
                      SizedBox(width: context.rs(12)),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(context.rs(13)),
                          decoration:
                              softCardDecoration(context, radius: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: context.rf(13.5),
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: context.rs(3)),
                              Text(sub,
                                  style: TextStyle(
                                      fontSize: context.rf(11),
                                      height: 1.5,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (70 * i).ms).fadeIn(duration: 280.ms).slideX(
                  begin: 0.04, end: 0, curve: Curves.easeOut),
            ),
        ]),
      ),
    ]);
  }
}

/* ─────────────────── Maintenance offers (typeId 3) ─────────────────── */

final class _HubOffers extends StatelessWidget {
  const _HubOffers();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final state = context.watch<OffersCubit>().state;
    final brandDbId = context
        .select((ThemeCubit c) => c.state.brandKey == 'lexus' ? '2' : '1');

    final offers = state.offers
        .where((o) => o.typeId == 3 && o.visibleForBrand(brandDbId))
        .toList();
    if (offers.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: t.mhOffers),
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
    ]);
  }
}

/* ───────────── Why us: comparison table (us ✓ / others ✗) ───────────── */

final class _WhyUs extends StatelessWidget {
  const _WhyUs();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // (feature, us, others) — the website's exact comparison rows.
    final rows = <(String, bool, bool)>[
      (t.mhRowParts, true, false),
      (t.mhRowDiag, true, false),
      (t.mhRowTeam, true, true),
      (t.mhRowReport, true, false),
      (t.mhRowTech, true, false),
    ];

    Widget mark(bool on) => Container(
          width: context.rs(24),
          height: context.rs(24),
          decoration: BoxDecoration(
            color: on
                ? scheme.primary.withValues(alpha: 0.12)
                : const Color(0xFFEF4444).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            on ? Icons.check_rounded : Icons.close_rounded,
            size: 14,
            color: on
                ? scheme.primary
                : const Color(0xFFEF4444).withValues(alpha: 0.8),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: t.mhWhyTitle, subtitle: t.mhWhySub),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: softCardDecoration(context, radius: 18),
          child: Column(children: [
            // Header row: المزايا | نحن | غيرنا
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(14), vertical: context.rs(11)),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : scheme.onSurface.withValues(alpha: 0.03),
              child: Row(children: [
                Expanded(
                  child: Text(t.mhFeatures,
                      style: TextStyle(
                          fontSize: context.rf(10),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: scheme.onSurface
                              .withValues(alpha: 0.55))),
                ),
                SizedBox(
                  width: context.rs(52),
                  child: Text(t.mhUs,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: context.rf(10),
                          fontWeight: FontWeight.w900,
                          color: scheme.primary)),
                ),
                SizedBox(
                  width: context.rs(52),
                  child: Text(t.mhOthers,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: context.rf(10),
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface
                              .withValues(alpha: 0.55))),
                ),
              ]),
            ),
            for (final (i, (label, us, them)) in rows.indexed) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outline.withValues(alpha: 0.25)),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.rs(14), vertical: context.rs(11)),
                child: Row(children: [
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: context.rf(11.5),
                            fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(
                      width: context.rs(52),
                      child: Center(child: mark(us))),
                  SizedBox(
                      width: context.rs(52),
                      child: Center(child: mark(them))),
                ]),
              ),
            ],
          ]),
        ).animate().fadeIn(duration: 300.ms).slideY(
            begin: 0.05, end: 0, curve: Curves.easeOut),
      ),
    ]);
  }
}

/* ─────────────── Guest feedback (swipeable PageView) ─────────────── */

final class _Feedback extends StatefulWidget {
  const _Feedback();

  @override
  State<_Feedback> createState() => _FeedbackState();
}

final class _FeedbackState extends State<_Feedback> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final reviews =
        context.select((MaintenanceHubCubit c) => c.state.testimonials);
    if (reviews.isEmpty) return const SizedBox.shrink();

    const palette = [Color(0xFF23CC4F), Color(0xFFF59E0B), Color(0xFF3B82F6)];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: t.mhFeedback),
      SizedBox(
        height: context.rs(150),
        child: PageView.builder(
          controller: _controller,
          itemCount: reviews.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) {
            final r = reviews[i];
            final name = r.name(lang);
            final initial = name.isEmpty ? '؟' : name.characters.first;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(5)),
              child: RepaintBoundary(
                child: Container(
                  padding: EdgeInsets.all(context.rs(14)),
                  decoration: softCardDecoration(context, radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          radius: context.rs(17),
                          backgroundColor:
                              palette[i % palette.length].withValues(alpha: 0.9),
                          child: Text(initial,
                              style: TextStyle(
                                  fontSize: context.rf(13),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        SizedBox(width: context.rs(9)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: context.rf(12.5),
                                      fontWeight: FontWeight.w800)),
                              Row(children: [
                                for (var s = 0; s < 5; s++)
                                  Icon(Icons.star_rounded,
                                      size: 13,
                                      color: const Color(0xFFF59E0B)),
                              ]),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(8),
                              vertical: context.rs(4)),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_rounded,
                                size: 11, color: scheme.primary),
                            SizedBox(width: context.rs(3)),
                            Text(t.mhVerified,
                                style: TextStyle(
                                    fontSize: context.rf(9),
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary)),
                          ]),
                        ),
                      ]),
                      SizedBox(height: context.rs(10)),
                      Expanded(
                        child: Text(
                          r.content(lang),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(11.5),
                              height: 1.55,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.65)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      if (reviews.length > 1) ...[
        SizedBox(height: context.rs(9)),
        Center(
          child: PageDots(
            count: reviews.length.clamp(0, 10),
            index: _page.clamp(0, 9),
            activeColor: scheme.primary,
          ),
        ),
      ],
    ]);
  }
}

/* ───────────────── Periodic schedule (km tabs + panels) ───────────────── */

final class _PeriodicSchedule extends StatelessWidget {
  const _PeriodicSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<MaintenanceHubCubit>().state;
    final cubit = context.read<MaintenanceHubCubit>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: t.mhPeriodicTitle, subtitle: t.mhPeriodicSub),
      switch (state.status) {
        PeriodicStatus.loading =>
          SkeletonList(itemCount: 3, itemHeight: context.rs(80)),
        PeriodicStatus.error => AppErrorState(
            title: t.mhPeriodicEmpty,
            retryLabel: t.stateRetry,
            onRetry: cubit.load,
            compact: true,
          ),
        PeriodicStatus.ready when state.details.isEmpty => Padding(
            padding: EdgeInsets.all(context.rs(24)),
            child: Center(
              child: Text(t.mhPeriodicEmpty,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            ),
          ),
        PeriodicStatus.ready => const _PeriodicBody(),
      },
    ]);
  }
}

final class _PeriodicBody extends StatelessWidget {
  const _PeriodicBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final state = context.watch<MaintenanceHubCubit>().state;
    final cubit = context.read<MaintenanceHubCubit>();

    final active = state.activeTab;
    if (active == null) return const SizedBox.shrink();
    final sections =
        parsePeriodicSections(active.content(lang), active.mileageGrouped);
    final title = active.title(lang);
    final subTitle = active.subTitle(lang);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // km filter chips from the endpoint data.
      FilterChipsRow(
        labels: [for (final d in state.details) d.tab(lang)],
        selectedIndex: state.tabIndex,
        onSelected: cubit.selectTab,
      ),
      SizedBox(height: context.rs(12)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
        child: Column(
          key: ValueKey('periodic-tab-${active.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title,
                  style: TextStyle(
                      fontSize: context.rf(15),
                      fontWeight: FontWeight.w800)),
            if (subTitle.isNotEmpty) ...[
              SizedBox(height: context.rs(3)),
              Text(subTitle,
                  style: TextStyle(
                      fontSize: context.rf(11),
                      height: 1.55,
                      color: scheme.onSurface.withValues(alpha: 0.6))),
            ],
            SizedBox(height: context.rs(12)),
            for (final (i, sec) in sections.indexed)
              _SectionPanel(
                key: ValueKey('sec-${active.id}-$i'),
                section: sec,
                open: state.openSection == i,
                onToggle: () => cubit.toggleSection(i),
                index: i,
              ),
            // The four footnote blocks under the accordion (website parity).
            for (final n in state.notes) _NoteBlock(note: n, lang: lang),
          ],
        ).animate().fadeIn(duration: 240.ms),
      ),
    ]);
  }
}

/// One expandable section panel — softCardDecoration + brand icon, single
/// column bullets on mobile.
final class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    super.key,
    required this.section,
    required this.open,
    required this.onToggle,
    required this.index,
  });

  final PeriodicSection section;
  final bool open;
  final VoidCallback onToggle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget bullet(String text) => Padding(
          padding: EdgeInsets.only(bottom: context.rs(7)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsetsDirectional.only(
                  top: context.rs(6), end: context.rs(8)),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    color: scheme.primary, shape: BoxShape.circle),
              ),
            ),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: context.rf(11.5),
                      height: 1.55,
                      color: scheme.onSurface.withValues(alpha: 0.72))),
            ),
          ]),
        );

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: context.rs(10)),
        clipBehavior: Clip.antiAlias,
        decoration: softCardDecoration(context, radius: 18).copyWith(
          border: Border.all(
            color: open
                ? scheme.primary.withValues(alpha: 0.55)
                : scheme.outline.withValues(alpha: 0.45),
          ),
        ),
        child: Column(children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(14), vertical: context.rs(13)),
              child: Row(children: [
                Container(
                  width: context.rs(32),
                  height: context.rs(32),
                  decoration: BoxDecoration(
                    color: open
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.checklist_rounded,
                      size: 16,
                      color: open ? scheme.onPrimary : scheme.primary),
                ),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Text(
                    section.title.isEmpty ? '${index + 1}' : section.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rf(12.5),
                      fontWeight: FontWeight.w800,
                      color: open ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: scheme.onSurface.withValues(alpha: 0.45)),
                ),
              ]),
            ),
          ),
          // Expanding body — AnimatedSize keeps it cheap and smooth.
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(context.rs(14),
                        context.rs(2), context.rs(14), context.rs(13)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.subgroups.isNotEmpty)
                          for (final (si, sg)
                              in section.subgroups.indexed) ...[
                            if (sg.title.isNotEmpty) ...[
                              if (si > 0) SizedBox(height: context.rs(8)),
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: context.rs(7)),
                                child: Text(sg.title,
                                    style: TextStyle(
                                        fontSize: context.rf(10.5),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                        color: scheme.primary)),
                              ),
                            ],
                            for (final item in sg.items) bullet(item),
                          ]
                        else
                          for (final item in section.items) bullet(item),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

/// The footnote blocks under the accordion — same Id dispatch the website
/// uses: 1 = title/details table, 2/3 = bullet grid, 4 = highlighted box.
final class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.note, required this.lang});

  final PeriodicRow note;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final title = note.title(lang);
    final content = note.content(lang);
    if (content.isEmpty) return const SizedBox.shrink();

    Widget heading() => Padding(
          padding: EdgeInsets.only(
              top: context.rs(14), bottom: context.rs(10)),
          child: Row(children: [
            Container(
              width: context.rs(30),
              height: context.rs(30),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.info_outline_rounded, size: 15, color: scheme.primary),
            ),
            SizedBox(width: context.rs(9)),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: context.rf(13.5),
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        );

    if (note.id == 1) {
      final rows = parsePeriodicNoteTable(content);
      if (rows.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading(),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: softCardDecoration(context, radius: 16),
          child: Column(children: [
            for (final (i, (rowTitle, details)) in rows.indexed) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outline.withValues(alpha: 0.25)),
              Padding(
                padding: EdgeInsets.all(context.rs(13)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rowTitle,
                        style: TextStyle(
                            fontSize: context.rf(12),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rs(6)),
                    for (final d in details)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.rs(4)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('—  ',
                                  style: TextStyle(
                                      fontSize: context.rf(11),
                                      color: scheme.primary)),
                              Expanded(
                                child: Text(d,
                                    style: TextStyle(
                                        fontSize: context.rf(11),
                                        height: 1.5,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.65))),
                              ),
                            ]),
                      ),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ]);
    }

    if (note.id == 2 || note.id == 3) {
      final lines = content
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => l.replaceFirst(RegExp(r'^[-•]\s*'), ''))
          .toList();
      if (lines.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading(),
        for (final l in lines)
          Container(
            margin: EdgeInsets.only(bottom: context.rs(8)),
            padding: EdgeInsets.all(context.rs(12)),
            decoration: softCardDecoration(context, radius: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                    top: context.rs(5), end: context.rs(8)),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: scheme.primary, shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Text(l,
                    style: TextStyle(
                        fontSize: context.rf(11.5), height: 1.5)),
              ),
            ]),
          ),
      ]);
    }

    if (note.id == 4) {
      return Container(
        margin: EdgeInsets.only(top: context.rs(14)),
        padding: EdgeInsets.all(context.rs(16)),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: scheme.primary.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.mhImportant,
              style: TextStyle(
                  fontSize: context.rf(9.5),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: scheme.primary)),
          SizedBox(height: context.rs(5)),
          if (title.isNotEmpty)
            Text(title,
                style: TextStyle(
                    fontSize: context.rf(13.5),
                    fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(6)),
          Text(content,
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  height: 1.6,
                  color: scheme.onSurface.withValues(alpha: 0.75))),
        ]),
      );
    }

    return const SizedBox.shrink();
  }
}

/* ───────────────────────── Bottom CTA ───────────────────────── */

final class _BottomCta extends StatelessWidget {
  const _BottomCta();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final onBrand = scheme.onPrimary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(26), context.rs(20), 0),
      child: Container(
        padding: EdgeInsets.all(context.rs(18)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, Colors.black, 0.3)!,
            ],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.rs(9), vertical: context.rs(4)),
            decoration: BoxDecoration(
              color: onBrand.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bolt_rounded, size: 12, color: onBrand),
              SizedBox(width: context.rs(4)),
              Text(t.mhHeroAccent,
                  style: TextStyle(
                      fontSize: context.rf(9.5),
                      fontWeight: FontWeight.w800,
                      color: onBrand)),
            ]),
          ),
          SizedBox(height: context.rs(10)),
          Text(t.mhReady,
              style: TextStyle(
                  fontSize: context.rf(21),
                  fontWeight: FontWeight.w900,
                  color: onBrand)),
          SizedBox(height: context.rs(5)),
          Text(t.mhReadySub,
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  height: 1.55,
                  color: onBrand.withValues(alpha: 0.85))),
          SizedBox(height: context.rs(12)),
          // The website CTA's four ✓ bullets.
          for (final b in [t.mhRowParts, t.mhRowDiag, t.mhRowTech, t.mhRowReport])
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(6)),
              child: Row(children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: onBrand.withValues(alpha: 0.9)),
                SizedBox(width: context.rs(7)),
                Expanded(
                  child: Text(b,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(11),
                          fontWeight: FontWeight.w600,
                          color: onBrand.withValues(alpha: 0.92))),
                ),
              ]),
            ),
          SizedBox(height: context.rs(12)),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: onBrand,
                  foregroundColor: scheme.primary,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: TextStyle(
                      fontSize: context.rf(13),
                      fontWeight: FontWeight.w800),
                ),
                onPressed: () => _book(context),
                child: Text(t.mhBookService),
              ),
            ),
            SizedBox(width: context.rs(9)),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                      color: onBrand.withValues(alpha: 0.6)),
                  foregroundColor: onBrand,
                  textStyle: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w800),
                ),
                onPressed: () => launchUrl(Uri.parse(_kWhatsAppUrl),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: Text(t.mhWhatsApp),
              ),
            ),
          ]),
        ]),
      ).animate().fadeIn(duration: 320.ms).slideY(
          begin: 0.05, end: 0, curve: Curves.easeOut),
    );
  }
}
