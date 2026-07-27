import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../../core/constants/api_paths.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart' show SheetHandle;
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/brand_switch_fab.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../offers/bloc/offers_cubit.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/domain/offer_models.dart';
import '../../offers/presentation/offers_screen.dart' show OfferCard;
import '../../protection/data/protection_repository.dart';
import '../../protection/domain/protection_models.dart';
import '../../protection/presentation/protection_detail_sheet.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart' as settings;
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
            create: (_) => OffersCubit(OffersRepository(sl<ApiClient>()))),
      ],
      child: const _Body(),
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<RegisteredHomeCubit>().state;
    final cubit = context.read<RegisteredHomeCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: switch (state.status) {
            RegisteredHomeStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            RegisteredHomeStatus.error => Center(
                child: TextButton(
                    onPressed: cubit.load, child: Text(t.homeErrorRetry))),
            RegisteredHomeStatus.ready => RefreshIndicator(
                onRefresh: cubit.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: context.rs(140)),
                  children: [
                    _Greeting(lang: lang),
                    _DynamicCard(home: state.home, lang: lang)
                        .animate()
                        .fadeIn(duration: 280.ms),
                    _GarageSection(home: state.home, lang: lang),
                    _QuickActions(home: state.home, lang: lang),
                    // "All services" — a permanent titled section (no
                    // expander), per the spec revision.
                    SectionHeader(
                        title: t.acAllServices, subtitle: t.acAllServicesSub),
                    _AllServicesGrid(lang: lang),
                    if (state.home.journeys.isNotEmpty) ...[
                      SectionHeader(
                        title: t.acJourneys,
                        actionLabel: t.homeViewAll,
                        onAction: () => context.push(Routes.tracking),
                      ),
                      _JourneysList(
                          journeys: state.home.journeys, lang: lang),
                    ],
                    // Protection & shading packages resolved for MY car.
                    if (state.home.garage
                        .any((c) => (c.type ?? '').isNotEmpty))
                      _ProtectionForCar(
                          garage: state.home.garage, lang: lang),
                    _OffersTabs(home: state.home, lang: lang),
                  ],
                ),
              ),
          },
        ),
      ],
    );
  }
}

/* ─────────────────────────── Greeting ─────────────────────────── */

final class _Greeting extends StatelessWidget {
  const _Greeting({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = context.select((AuthBloc b) => b.state.user);
    final scheme = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? t.acGoodMorning
        : hour < 17
            ? t.acGoodAfternoon
            : t.acGoodEvening;
    final first = (user?.displayName(lang) ?? '').split(' ').firstOrNull ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(16), context.rs(20), context.rs(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  first.isEmpty ? greeting : '$greeting،\n$first',
                  style: TextStyle(
                      fontSize: context.rf(21),
                      height: 1.2,
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: context.rs(4)),
                Text(
                  t.acGreetingSub,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rs(10)),
          // Toyota ⇄ Lexus switch — the design's stacked header control
          // (replaces the old floating FAB).
          const BrandSwitchCapsule(),
        ],
      ),
    );
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
          context.rs(16), context.rs(12), context.rs(16), 0),
      child: switch (home.cardKind) {
        'workorder' when home.workOrder != null =>
          WorkOrderCard(order: home.workOrder!, lang: lang),
        'booking' when home.booking != null =>
          _BookingCard(booking: home.booking!, lang: lang),
        'car' when home.car != null =>
          _CarCard(car: home.car!, nextPm: home.nextPm, lang: lang),
        _ => const _AddCarCard(),
      },
    );
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
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
                    color: onBrand),
              ),
            ),
            if ((order.plateNo ?? '').isNotEmpty)
              Text(order.plateNo!,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: context.rf(11),
                      fontWeight: FontWeight.w700,
                      color: onBrand.withValues(alpha: 0.75))),
          ]),
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
                  color: onBrand),
            ),
          ],
          SizedBox(height: context.rs(14)),
          StageBar(labels: stageLabels, activeIndex: idx, onBrand: true),
          if (order.readyToPay && (order.grandTotal ?? 0) > 0) ...[
            SizedBox(height: context.rs(12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.acAmountDue,
                    style: TextStyle(
                        fontSize: context.rf(12),
                        fontWeight: FontWeight.w700,
                        color: onBrand.withValues(alpha: 0.85))),
                PriceText(
                    price: (order.remaining ?? order.grandTotal)!,
                    currency: '',
                    contactForPrice: '',
                    fontSize: context.rf(16),
                    color: onBrand),
              ],
            ),
            if ((order.sadadNumber ?? '').isNotEmpty) ...[
              SizedBox(height: context.rs(4)),
              Text('${t.acSadad}: ${order.sadadNumber}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: context.rf(11),
                      color: onBrand.withValues(alpha: 0.7))),
            ],
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
                    fontWeight:
                        i == activeIndex ? FontWeight.w800 : FontWeight.w600,
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
    final when = [longDate, (booking.ordertime ?? '').trim()]
        .where((s) => s.isNotEmpty)
        .join(' • ');

    // Note line (mock's "Traction control system update"): the booked
    // car's name resolved via chassis, else the booking reference.
    final garage = context.read<RegisteredHomeCubit>().state.home.garage;
    final bookedCar = garage
        .where((c) =>
            (c.vin ?? '').isNotEmpty &&
            (booking.chassis ?? '').isNotEmpty &&
            c.vin == booking.chassis)
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
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge line — icon + small bold uppercase label (mock style).
          Row(children: [
            Icon(Icons.event_repeat_rounded, size: 17, color: onBrand),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: Text(t.acUpcomingBooking.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: onBrand)),
            ),
          ]),
          SizedBox(height: context.rs(14)),
          Text(
            booking.description(lang),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: context.rf(20),
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: onBrand),
          ),
          SizedBox(height: context.rs(10)),
          Text(
            when,
            style: TextStyle(
                fontSize: context.rf(13),
                fontWeight: FontWeight.w500,
                color: onBrand.withValues(alpha: 0.8)),
          ),
          if (note.isNotEmpty) ...[
            SizedBox(height: context.rs(8)),
            Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: onBrand.withValues(alpha: 0.85)),
              SizedBox(width: context.rs(7)),
              Expanded(
                child: Text(note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w600,
                        color: onBrand.withValues(alpha: 0.92))),
              ),
            ]),
          ],
          SizedBox(height: context.rs(18)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: onBrand,
                foregroundColor: scheme.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: TextStyle(
                    fontSize: context.rf(13.5), fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                final car = garage.firstOrNull;
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

final class _CarCard extends StatelessWidget {
  const _CarCard({required this.car, required this.nextPm, required this.lang});

  final GarageCar car;
  final NextPm? nextPm;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.rs(16)),
      decoration:
          softCardDecoration(context, tint: scheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.displayName(lang)} ${car.year ?? ''}'.trim(),
                      style: TextStyle(
                          fontSize: context.rf(16),
                          fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: context.rs(3)),
                    Row(children: [
                      if (car.plate(lang).isNotEmpty) ...[
                        Icon(Icons.pin_outlined,
                            size: 13,
                            color:
                                scheme.onSurface.withValues(alpha: 0.45)),
                        SizedBox(width: context.rs(3)),
                        Text(car.maskedPlate(lang),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: context.rf(11),
                                color: scheme.onSurface
                                    .withValues(alpha: 0.6))),
                        SizedBox(width: context.rs(10)),
                      ],
                      if (car.meterReading != null) ...[
                        Icon(Icons.speed_rounded,
                            size: 13,
                            color:
                                scheme.onSurface.withValues(alpha: 0.45)),
                        SizedBox(width: context.rs(3)),
                        Text(
                            '${formatPrice(car.meterReading!.toDouble())} KM',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: context.rf(11),
                                color: scheme.onSurface
                                    .withValues(alpha: 0.6))),
                      ],
                    ]),
                  ],
                ),
              ),
              SizedBox(
                width: context.rs(110),
                height: context.rs(64),
                child: HomeImage(
                    url: car.image, fit: BoxFit.contain, logicalWidth: 110),
              ),
            ],
          ),
          SizedBox(height: context.rs(12)),
          if (nextPm != null) NextPmLine(pm: nextPm!, car: car),
          SizedBox(height: context.rs(12)),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding:
                        EdgeInsets.symmetric(vertical: context.rs(11)),
                    textStyle: TextStyle(
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w800)),
                onPressed: () =>
                    showMaintenanceBookingSheet(context, car: car),
                child: Text(t.ghBookMaintenance),
              ),
            ),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding:
                        EdgeInsets.symmetric(vertical: context.rs(11)),
                    side: BorderSide(color: scheme.primary),
                    foregroundColor: scheme.primary,
                    textStyle: TextStyle(
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w800)),
                onPressed: () => showVehicleHubSheet(context, car: car),
                child: Text(t.acCarDetails),
              ),
            ),
          ]),
        ],
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
          Icon(Icons.directions_car_filled_outlined,
              size: 36, color: scheme.primary),
          SizedBox(height: context.rs(10)),
          Text(t.acNoCarsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.rf(14.5), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(4)),
          Text(t.acNoCarsSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
          SizedBox(height: context.rs(14)),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: const StadiumBorder()),
            onPressed: () => showAddCarSheet(context,
                onAdded: context.read<RegisteredHomeCubit>().load),
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
    if (home.garage.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: t.acMyGarage,
          actionLabel: t.acAddCarShort,
          onAction: () => showAddCarSheet(context, onAdded: cubit.load),
        ),
        CardRail(
          height: context.rs(244),
          itemWidth: context.rs(300),
          itemCount: home.garage.length,
          itemBuilder: (context, i) {
            final car = home.garage[i];
            final scheme = Theme.of(context).colorScheme;
            final isDark =
                Theme.of(context).brightness == Brightness.dark;
            final subLine = [
              if ((car.year ?? '').toString().trim().isNotEmpty)
                '${car.year}',
              car.maskedPlate(lang).isEmpty
                  ? (car.vin ?? '')
                  : car.maskedPlate(lang),
            ].where((s) => s.trim().isNotEmpty).join(' • ');
            return HomeCard(
              onTap: () => showVehicleHubSheet(context, car: car),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full-bleed cover photo with the ACTIVE badge on the
                  // top-end corner (first car = primary vehicle).
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
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
                                logicalWidth: 300),
                          ),
                          if (i == 0)
                            PositionedDirectional(
                              top: context.rs(10),
                              end: context.rs(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: context.rs(10),
                                    vertical: context.rs(4.5)),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF181B21)
                                          .withValues(alpha: 0.9)
                                      : Colors.white
                                          .withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  t.acActiveBadge,
                                  style: TextStyle(
                                      fontSize: context.rf(9),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: scheme.onSurface),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.rs(14),
                        context.rs(12), context.rs(14), context.rs(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.displayName(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(13.5),
                              fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: context.rs(3)),
                        Text(
                          subLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: context.rf(10.5),
                            fontWeight: FontWeight.w600,
                            color:
                                scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: (30 * (i % 5)).ms).fadeIn(duration: 240.ms);
          },
        ),
      ],
    );
  }
}

/* ─────────────────────── Quick actions ─────────────────────── */

final class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.home, required this.lang});

  final HomeState home;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<RegisteredHomeCubit>();
    final primaryCar = home.garage.firstOrNull;

    // The spec's four: book service, buy a car, spare parts, my orders —
    // each with its own pastel tint like the reference kit.
    final actions = <(IconData, Color, String, VoidCallback)>[
      (
        Icons.build_rounded,
        scheme.primary,
        t.ghBookMaintenance,
        () => primaryCar != null
            ? showMaintenanceBookingSheet(context, car: primaryCar)
            : showAddCarSheet(context, onAdded: cubit.load)
      ),
      (Icons.directions_car_rounded, const Color(0xFF8A7B4F), t.acBuyCar,
          () => context.push(Routes.onlineStore)),
      (Icons.settings_rounded, const Color(0xFF64748B), t.ghSpareParts,
          () => context.push(Routes.parts)),
      (Icons.assignment_outlined, const Color(0xFFC26A7A), t.acMyOrders,
          () => context.push(Routes.tracking)),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(16), context.rs(18), context.rs(16), 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: context.rs(12),
        crossAxisSpacing: context.rs(12),
        childAspectRatio: 1.12,
        children: [
          for (final (icon, tint, label, onTap) in actions)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: EdgeInsets.all(context.rs(14)),
                  decoration: softCardDecoration(context, radius: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: context.rs(46),
                        height: context.rs(46),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: tint),
                      ),
                      SizedBox(height: context.rs(11)),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(12),
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _AllServicesGrid extends StatelessWidget {
  const _AllServicesGrid({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Built-in defaults per fixed ServiceKey (icon, title, subtitle, route) —
    // the dashboard rows override title/subtitle/order and add the photo.
    final defaults = <String, (IconData, String, String, String)>{
      'protection': (Icons.shield_outlined, t.ghSvcProtection,
          t.svcProtectionSub, Routes.protection),
      'finance': (Icons.account_balance_outlined, t.ghSvcFinance,
          t.svcFinanceSub, Routes.finance),
      'offers': (Icons.local_offer_outlined, t.offersTitle, t.svcOffersSub,
          Routes.offers),
      'store': (Icons.storefront_outlined, t.homeOnlineStore, t.svcStoreSub,
          Routes.onlineStore),
      'models': (Icons.directions_car_outlined, t.homeMeetTheModels,
          t.svcModelsSub, Routes.models),
      'tracking': (Icons.car_repair_rounded, t.trackTitle, t.svcTrackingSub,
          Routes.tracking),
      'finance_requests': (Icons.request_quote_outlined, t.finReqTitle,
          t.svcFinReqSub, Routes.financeRequests),
      'favorites': (Icons.favorite_border_rounded, t.favTitle,
          t.svcFavoritesSub, Routes.favorites),
      'news': (Icons.newspaper_outlined, t.newsTitle, t.svcNewsSub,
          Routes.news),
      'contact': (Icons.support_agent_outlined, t.contactTitle,
          t.svcContactSub, Routes.contact),
    };

    return FutureBuilder<List<_HomeServiceCfg>>(
      future: _HomeServiceCfg.load(),
      builder: (context, snap) {
        final cfg = snap.data ?? const <_HomeServiceCfg>[];
        // (icon, title, subtitle, route, photo)
        final rows = <(IconData, String, String, String, String?)>[];
        if (cfg.isEmpty) {
          for (final d in defaults.values) {
            rows.add((d.$1, d.$2, d.$3, d.$4, null));
          }
        } else {
          for (final c in cfg) {
            final d = defaults[c.key];
            if (d == null) continue;
            rows.add((
              d.$1,
              c.title(lang) ?? d.$2,
              c.subtitle(lang) ?? d.$3,
              d.$4,
              c.image,
            ));
          }
        }

        // The mock's tile: small red icon + title + one-line subtitle, with
        // a large faint watermark (dashboard photo when assigned, else the
        // service's outline icon) on the bottom-end corner.
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: context.rs(12),
            crossAxisSpacing: context.rs(12),
            childAspectRatio: 1.5,
            children: [
              for (final (icon, label, sub, route, photo) in rows)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => context.push(route),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      decoration: softCardDecoration(context, radius: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(children: [
                          PositionedDirectional(
                            bottom: context.rs(-4),
                            end: context.rs(6),
                            child: photo == null || photo.isEmpty
                                ? Icon(icon,
                                    size: 52,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.07))
                                : ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: Opacity(
                                      opacity: 0.85,
                                      child: Image.network(
                                        optimizedImageUrl(photo,
                                                width: 144) ??
                                            photo,
                                        width: context.rs(48),
                                        height: context.rs(40),
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        errorBuilder: (_, _, _) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(context.rs(13)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon,
                                    size: 18, color: scheme.primary),
                                SizedBox(height: context.rs(9)),
                                Text(label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: context.rf(12),
                                        height: 1.2,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(height: context.rs(2)),
                                Text(sub,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: context.rf(9.5),
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Dashboard-managed "All Services" row config (App_Home_Services via
/// /api/app/home/services), memoized per app session for instant paint.
final class _HomeServiceCfg {
  const _HomeServiceCfg({
    required this.key,
    this.titleAr,
    this.titleEn,
    this.subAr,
    this.subEn,
    this.image,
  });

  final String key;
  final String? titleAr;
  final String? titleEn;
  final String? subAr;
  final String? subEn;
  final String? image;

  String? title(String lang) {
    final v = lang == 'ar' ? titleAr : titleEn;
    return (v == null || v.trim().isEmpty) ? null : v;
  }

  String? subtitle(String lang) {
    final v = lang == 'ar' ? subAr : subEn;
    return (v == null || v.trim().isEmpty) ? null : v;
  }

  static Future<List<_HomeServiceCfg>>? _memo;
  static Future<List<_HomeServiceCfg>> load() => _memo ??= _fetch();

  static Future<List<_HomeServiceCfg>> _fetch() async {
    try {
      final res =
          await sl<ApiClient>().get<List<dynamic>>(ApiPaths.homeServices);
      return (res.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map((j) => _HomeServiceCfg(
                key: '${j['serviceKey'] ?? ''}',
                titleAr: j['titleAr'] as String?,
                titleEn: j['titleEn'] as String?,
                subAr: j['subtitleAr'] as String?,
                subEn: j['subtitleEn'] as String?,
                image: j['imageUrl'] as String?,
              ))
          .toList();
    } catch (_) {
      _memo = null; // retry next build if the fetch failed
      return const [];
    }
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

    // The mock's "Active Orders" rail: icon tile + status chip on top,
    // reference + line, and a footer hint with a chevron.
    return CardRail(
      height: context.rs(128),
      itemWidth: context.rs(206),
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
                Row(children: [
                  Container(
                    width: context.rs(30),
                    height: context.rs(30),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 15, color: scheme.primary),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(8),
                        vertical: context.rs(3.5)),
                    decoration: BoxDecoration(
                      color: j.needsAction
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      j.needsAction
                          ? t.acActionNeeded
                          : (status.isEmpty ? kindLabel : status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: j.needsAction
                              ? scheme.onPrimary
                              : scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ]),
                SizedBox(height: context.rs(10)),
                Text(
                  j.title(lang).isEmpty ? kindLabel : j.title(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: context.rs(2)),
                Text(
                  [kindLabel, if ((j.reference ?? '').isNotEmpty) j.reference!]
                      .join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(9.5),
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
                const Spacer(),
                Row(children: [
                  Expanded(
                    child: Text(
                      status.isEmpty ? kindLabel : status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(9),
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.45)),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 15,
                      color: scheme.onSurface.withValues(alpha: 0.35)),
                ]),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5))),
              ),
              Expanded(
                child: Text(value,
                    textDirection: ltr ? TextDirection.ltr : null,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
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
          Row(children: [
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
                  Text(kindLabel,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.5))),
                  Text(
                    j.title(lang).isEmpty ? kindLabel : j.title(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (status.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      color: j.needsAction
                          ? scheme.onPrimary
                          : scheme.primary),
                ),
              ),
          ]),
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
      BuildContext context, AppLocalizations t, ColorScheme scheme) {
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
            Text(t.acAmountDue,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
            PriceText(
                price: (wo.remaining ?? wo.grandTotal)!,
                currency: '',
                contactForPrice: '',
                fontSize: 16),
          ],
        ),
        if ((wo.sadadNumber ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${t.acSadad}: ${wo.sadadNumber}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.6))),
          ),
      ],
      const SizedBox(height: 18),
      FilledButton.icon(
        style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder()),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          context.push(Routes.tracking);
        },
        icon: const Icon(Icons.podcasts_rounded, size: 17),
        label: Text(t.trackTitle),
      ),
    ];
  }

  List<Widget> _orderBody(BuildContext context, AppLocalizations t,
      ColorScheme scheme, Widget Function(String, String, {bool ltr}) row) {
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
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder()),
          onPressed: () =>
              launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.payments_outlined, size: 17),
          label: Text(t.jdPayNow),
        ),
      ],
      const SizedBox(height: 16),
      Text(t.acOrderTracking,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (cartId == null)
        Center(child: Text(t.acNoTracking))
      else
        _OrderTimeline(cartId: cartId, lang: lang),
    ];
  }

  List<Widget> _bookingBody(
      AppLocalizations t, Widget Function(String, String, {bool ltr}) row) {
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
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder()),
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
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (steps.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Center(child: Text(t.acNoTracking)),
          );
        }
        return Column(children: [
          for (final (i, s) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [
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
                          color: scheme.outline.withValues(alpha: 0.4)),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.description(lang),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        if (s.createdAt != null)
                          Text(
                            s.createdAt!
                                .toIso8601String()
                                .substring(0, 16)
                                .replaceAll('T', ' '),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.5)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ]);
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
    final result = await ProtectionRepository(sl<ApiClient>())
        .protectionByModel(car.type!, car.brandDbId ?? '1');
    if (isClosed) return;
    emit((i, result?.services ?? const [], false));
  }
}

/// Car picker for the protection section's brand-pill dropdown.
void _pickProtectionCar(BuildContext context, List<GarageCar> cars, int sel,
    String lang, void Function(int) onPick) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  borderRadius: BorderRadius.circular(14)),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_car_rounded,
                    size: 18, color: scheme.primary),
              ),
              title: Text('${c.displayName(lang)} ${c.year ?? ''}'.trim(),
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              trailing: i == sel
                  ? Icon(Icons.check_circle_rounded,
                      size: 20, color: scheme.primary)
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
    final cars =
        garage.where((c) => (c.type ?? '').isNotEmpty).toList();
    return BlocProvider(
      key: ValueKey('prot-${cars.length}'),
      create: (_) => _ProtCarCubit(cars),
      child: Builder(builder: (context) {
        final (sel, packages, loading) =
            context.watch<_ProtCarCubit>().state;
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
                    context.rs(16), 0, context.rs(16), 0),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: cars.length < 2
                        ? null
                        : () => _pickProtectionCar(
                            context, cars, sel, lang, cubit.select),
                    child: Ink(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rs(14),
                          vertical: context.rs(12)),
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
                                0.2)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: context.rs(30),
                          height: context.rs(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car_rounded,
                              size: 16, color: Colors.white),
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
                                color: Colors.white),
                          ),
                        ),
                        if (cars.length > 1)
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 20, color: Colors.white),
                      ]),
                    ),
                  ),
                ),
              ),
            SizedBox(height: context.rs(14)),
            if (loading)
              const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()))
            else if (packages.isEmpty)
              Padding(
                padding: EdgeInsets.all(context.rs(20)),
                child: Center(child: Text(t.protNoPackages)),
              )
            else
              CardRail(
                height: context.rs(268),
                itemWidth: context.rs(236),
                itemCount: packages.length,
                itemBuilder: (context, i) {
                  final p = packages[i];
                  final scheme = Theme.of(context).colorScheme;
                  // Gold / silver / bronze tier roundels like the mock.
                  final (tintBg, tintFg) = switch (i % 3) {
                    0 => (const Color(0xFFF3E7C6), const Color(0xFF7A6524)),
                    1 => (const Color(0xFFE8EBF0), const Color(0xFF667080)),
                    _ => (const Color(0xFFF0E1D6), const Color(0xFF8A5A3B)),
                  };
                  void open() => showProtectionDetailSheet(
                        context,
                        package: p,
                        vehicleLabel: car == null
                            ? null
                            : '${car.displayName(lang)} ${car.year ?? ''}'
                                .trim(),
                        vin: car?.vin,
                      );
                  return HomeCard(
                    onTap: open,
                    child: Padding(
                      padding: EdgeInsets.all(context.rs(15)),
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
                                    color: tintBg, shape: BoxShape.circle),
                                child: Icon(Icons.verified_user_rounded,
                                    size: 19, color: tintFg),
                              ),
                              const Spacer(),
                              if (i == 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: context.rs(9),
                                      vertical: context.rs(4)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E7C6),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    t.protPopular,
                                    style: TextStyle(
                                        fontSize: context.rf(8.5),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: const Color(0xFF7A6524)),
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
                              currency: '',
                              contactForPrice: t.homeContactForPrice,
                              fontSize: context.rf(15)),
                          SizedBox(height: context.rs(10)),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
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
                  );
                },
              ),
          ],
        );
      }),
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
        (settings.ThemeCubit c) => c.state.brandKey == 'lexus' ? '2' : '1');
    final car = home.garage.firstOrNull;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: OffersRepository(sl<ApiClient>()).supportedMap(),
      builder: (context, snap) {
        final matched = <int>{};
        if (car != null) {
          for (final row in snap.data ?? const <Map<String, dynamic>>[]) {
            final offerId =
                int.tryParse('${row['offerId'] ?? row['OfferId']}');
            if (offerId == null) continue;
            final type = '${row['productTypeId'] ?? row['ProductTypeId'] ?? ''}';
            final group = '${row['groupId'] ?? row['GroupId'] ?? ''}';
            final brand = '${row['brandId'] ?? row['BrandId'] ?? ''}';
            final hit = (type.isNotEmpty && type == car.type) ||
                (group.isNotEmpty && group == car.productGroupId) ||
                (type.isEmpty && group.isEmpty && brand == car.brandDbId);
            if (hit) matched.add(offerId);
          }
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
      child: Builder(builder: (context) {
        final tab = context.watch<_TabCubit>().state;
        final filtered = offers.where((o) {
          final visible =
              carBrandDbId == null || o.visibleForBrand(carBrandDbId);
          return switch (tab) {
            1 => o.typeId == 2 && visible,
            2 => o.typeId == 3 && visible,
            _ => visible,
          };
        }).toList()
          // "لك": offers matching my car float to the front.
          ..sort((a, b) => (matchedOfferIds.contains(b.id) ? 1 : 0)
              .compareTo(matchedOfferIds.contains(a.id) ? 1 : 0));

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
                height: context.rs(438),
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
      }),
    );
  }
}

final class _TabCubit extends Cubit<int> {
  _TabCubit() : super(0);
  void set(int i) => emit(i);
}
