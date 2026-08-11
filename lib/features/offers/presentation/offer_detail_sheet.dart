import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../guest_home/presentation/guest_home_view.dart' show showLoginPrompt;
import '../../home/presentation/widgets/home_bits.dart';
import '../../online_store/data/online_store_repository.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/offer_form_cubit.dart';
import '../bloc/offers_cubit.dart';
import '../data/offers_repository.dart';
import '../domain/offer_models.dart';

/// Opens the offer detail (website /offers/{slug}) as a hero bottom sheet.
void showOfferDetailSheet(BuildContext context, String? slug) {
  if (slug == null || slug.isEmpty) return;
  showHeroBottomSheet<void>(
    context,
    builder: (_) => OfferDetailSheet(slug: slug),
  );
}

final class OfferDetailSheet extends StatelessWidget {
  const OfferDetailSheet({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OfferDetailCubit(OffersRepository(sl<ApiClient>()), slug),
      child: const _DetailView(),
    );
  }
}

final class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<OfferDetailCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    final wantedDbId = brandKey == 'lexus' ? '2' : '1';
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: switch (state.status) {
          OfferDetailStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          OfferDetailStatus.error => Center(child: Text(t.homeErrorRetry)),
          OfferDetailStatus.ready => _DetailBody(
              detail: state.detail!,
              vehicles: state.vehicles(wantedDbId),
              activePackageId: state.activePackageId,
              selectedVehicle: state.selectedVehicle,
              lang: lang,
            ),
        },
      ),
    );
  }
}

final class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.vehicles,
    required this.activePackageId,
    required this.selectedVehicle,
    required this.lang,
  });

  final OfferDetail detail;
  final List<OfferVehicle> vehicles;
  final int? activePackageId;
  final OfferVehicle? selectedVehicle;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<OfferDetailCubit>();
    final o = detail.offer;
    final paragraphs = detail
        .description(lang)
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final terms = detail.terms(lang).trim();

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: HomeImage(
                          url: detail.banner(lang),
                          aspectRatio: 16 / 9,
                          logicalWidth: 480),
                    ),
                    const Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(child: SheetHandle()),
                    ),
                    PositionedDirectional(
                      bottom: 10,
                      start: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(10), vertical: context.rs(5)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          o.typeName(lang),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: context.rf(10.5),
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.all(context.rs(18)),
                sliver: SliverList.list(children: [
                  Text(
                    o.title(lang),
                    style: TextStyle(
                        fontSize: context.rf(20),
                        fontWeight: FontWeight.w800,
                        height: 1.25),
                  ),
                  SizedBox(height: context.rs(6)),
                  if ((o.totalDays ?? 0) > 0)
                    Row(children: [
                      Icon(Icons.schedule_rounded,
                          size: 15, color: scheme.primary),
                      SizedBox(width: context.rs(5)),
                      Text(
                        t.homeDaysLeft(o.totalDays!),
                        style: TextStyle(
                            fontSize: context.rf(11.5),
                            fontWeight: FontWeight.w700,
                            color: scheme.primary),
                      ),
                    ]),
                  if (detail.isFinanceOffer) ...[
                    SizedBox(height: context.rs(14)),
                    _BankStrip(detail: detail, lang: lang),
                  ],
                  if (paragraphs.isNotEmpty) ...[
                    SizedBox(height: context.rs(14)),
                    for (final p in paragraphs)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.rs(8)),
                        child: Text(
                          p,
                          style: TextStyle(
                              fontSize: context.rf(13),
                              height: 1.6,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.8)),
                        ),
                      ),
                  ],
                  if (!detail.reservationOnly &&
                      detail.packages.isNotEmpty) ...[
                    SizedBox(height: context.rs(10)),
                    Text(t.offersPackages,
                        style: TextStyle(
                            fontSize: context.rf(16),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rs(10)),
                    for (final pkg in detail.packages)
                      _PackageCard(
                        pkg: pkg,
                        lang: lang,
                        selected: pkg.id == activePackageId,
                        onTap: () => cubit.selectPackage(pkg.id),
                      ),
                  ],
                  if (vehicles.isNotEmpty) ...[
                    SizedBox(height: context.rs(16)),
                    Text(t.offersSupportedVehicles,
                        style: TextStyle(
                            fontSize: context.rf(16),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rs(10)),
                    SizedBox(
                      height: context.rs(120),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: vehicles.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(width: context.rs(10)),
                        itemBuilder: (context, i) {
                          final v = vehicles[i];
                          return _VehicleCard(
                            vehicle: v,
                            selected: v == selectedVehicle,
                            onTap: () => cubit.selectVehicle(v),
                          );
                        },
                      ),
                    ),
                  ],
                  if (terms.isNotEmpty) ...[
                    SizedBox(height: context.rs(16)),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(t.offersTerms,
                            style: TextStyle(
                                fontSize: context.rf(15),
                                fontWeight: FontWeight.w800)),
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              terms,
                              style: TextStyle(
                                  fontSize: context.rf(12),
                                  height: 1.7,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.65)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: context.rs(12)),
                ]),
              ),
            ],
          ),
        ),
        // Sticky CTA — reserve is the app's registered-only action: guests
        // get the benefit prompt, signed-in users get the website form.
        Container(
          padding: EdgeInsets.fromLTRB(
              context.rs(18), context.rs(10), context.rs(18), context.rs(12)),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
                top: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.4))),
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
              textStyle: TextStyle(
                  fontSize: context.rf(14), fontWeight: FontWeight.w800),
            ),
            // With a supported-vehicles rail the request is only valid for
            // one of those cars — the CTA stays disabled (grey) until the
            // user taps a card. Offers without a rail submit as before.
            onPressed: vehicles.isEmpty || selectedVehicle != null
                ? () => _onReserve(context)
                : null,
            child: Text(
              detail.isFinanceOffer
                  ? t.offersApplyFinance
                  : detail.isMaintenanceOffer
                      ? t.offersReserve
                      : t.offersRequest,
            ),
          ),
        ),
      ],
    );
  }

  void _onReserve(BuildContext context) {
    final auth = sl<AuthBloc>().state;
    if (auth.status != AuthStatus.authenticated) {
      // The website lets anonymous visitors apply; the app requires an
      // account for any reservation/application — benefit prompt instead.
      showLoginPrompt(context);
      return;
    }
    final kind = detail.isFinanceOffer
        ? OfferFormKind.finance
        : detail.isMaintenanceOffer
            ? OfferFormKind.reserve
            : OfferFormKind.contact;
    showOfferFormSheet(context,
        detail: detail, kind: kind, vehicle: selectedVehicle);
  }
}

/// Rail card — tappable, mirroring the trim cards in the vehicles model
/// sheet: brand ring + check badge when selected, one at a time.
final class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final OfferVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: context.rs(150),
        padding: EdgeInsets.all(context.rs(8)),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.07)
              : (isDark ? const Color(0xFF181B21) : scheme.surface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: isDark ? 0.5 : 0.45),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: HomeImage(
                        url: vehicle.image,
                        fit: BoxFit.contain,
                        logicalWidth: 150),
                  ),
                ),
                Text(
                  '${vehicle.groupEn ?? ''} ${vehicle.year ?? ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(11),
                      fontWeight: FontWeight.w800,
                      color: selected ? scheme.primary : scheme.onSurface),
                ),
              ],
            ),
            if (selected)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _BankStrip extends StatelessWidget {
  const _BankStrip({required this.detail, required this.lang});

  final OfferDetail detail;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.rs(12)),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if ((detail.bankLogo ?? '').isNotEmpty)
            SizedBox(
              width: context.rs(44),
              height: context.rs(44),
              child: HomeImage(url: detail.bankLogo, fit: BoxFit.contain, logicalWidth: 44),
            ),
          SizedBox(width: context.rs(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.bankName(lang),
                    style: TextStyle(
                        fontSize: context.rf(13),
                        fontWeight: FontWeight.w800)),
                if (detail.financeRate != null)
                  Text(
                    t.offersRate('${detail.financeRate!.toStringAsFixed(2)}%'),
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        color: scheme.primary,
                        fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.pkg,
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final OfferPackage pkg;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(8)),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.06)
            : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.all(context.rs(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.6),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.title(lang),
                          style: TextStyle(
                              fontSize: context.rf(13),
                              fontWeight: FontWeight.w800)),
                      if (pkg.description(lang).isNotEmpty) ...[
                        SizedBox(height: context.rs(3)),
                        Text(
                          pkg.description(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(11),
                              color:
                                  scheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.rs(10)),
                PriceText(
                    price: pkg.price,
                    currency: '',
                    contactForPrice: t.homeContactForPrice,
                    fontSize: context.rf(14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── Application form sheet ───────────────────────── */

void showOfferFormSheet(
  BuildContext context, {
  required OfferDetail detail,
  required OfferFormKind kind,
  OfferVehicle? vehicle,
}) {
  final lang = sl<LocaleCubit>().state.languageCode;
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => BlocProvider(
      create: (_) => OfferFormCubit(
        kind: kind,
        detail: detail,
        vehicle: vehicle,
        offersRepo: OffersRepository(sl<ApiClient>()),
        onlineRepo: sl<OnlineStoreRepository>(),
        user: sl<AuthBloc>().state.user,
        lang: lang,
      ),
      child: const _OfferFormView(),
    ),
  );
}

final class _OfferFormView extends StatelessWidget {
  const _OfferFormView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<OfferFormCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final detail = cubit.detail;

    if (state.phase == OfferFormPhase.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 52, color: scheme.primary),
            const SizedBox(height: 14),
            Text(t.offersSubmitted,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder()),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.commonDone),
            ),
          ],
        ),
      );
    }

    final periods = [24, 36, 48, 60]
        .where((p) => p <= (detail.maxFinancePeriod ?? 60))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: 12),
            Text(
              switch (cubit.kind) {
                OfferFormKind.reserve => t.offersReserve,
                OfferFormKind.contact => t.offersRequest,
                OfferFormKind.finance => t.offersApplyFinance,
              },
              style: TextStyle(
                  fontSize: context.rf(18), fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              detail.offer.title(lang),
              style: TextStyle(
                  fontSize: context.rf(12),
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            // The car is fixed to the supported vehicle picked on the detail
            // sheet's rail — shown read-only so the user sees what they're
            // requesting (single source of truth: the rail selection).
            if (cubit.vehicle != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: softCardDecoration(context, radius: 14),
                child: Row(children: [
                  Icon(Icons.directions_car_filled_rounded,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.offersVehicle,
                            style: TextStyle(
                                fontSize: context.rf(10),
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55))),
                        Text(
                          '${cubit.vehicle!.groupEn ?? ''} ${cubit.vehicle!.year ?? ''}'
                              .trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(13),
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: scheme.primary),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            if (cubit.kind == OfferFormKind.reserve &&
                detail.packages.isNotEmpty) ...[
              AppDropdown<int>(
                label: t.offersPackage,
                value: state.packageId,
                items: [
                  for (final p in detail.packages)
                    AppDropdownItem(value: p.id, label: p.title(lang)),
                ],
                onChanged: cubit.selectPackage,
              ),
              const SizedBox(height: 12),
            ],
            _Field(controller: cubit.name, label: t.formFullName),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.phone,
                label: t.formPhone,
                keyboard: TextInputType.phone,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.email,
                label: t.formEmailOptional,
                keyboard: TextInputType.emailAddress,
                ltr: true),
            const SizedBox(height: 12),
            if (cubit.kind == OfferFormKind.reserve) ...[
              Row(children: [
                Expanded(
                    child: _Field(
                        controller: cubit.year,
                        label: t.offersYear,
                        keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _Field(
                        controller: cubit.meter,
                        label: t.offersMeter,
                        keyboard: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              _Field(controller: cubit.vin, label: t.offersVinOptional, ltr: true),
              const SizedBox(height: 12),
              // Preferred slot — goes into the staff email.
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.8)),
                      foregroundColor: scheme.onSurface,
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: state.prefDate ?? now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 60)),
                      );
                      if (d != null) cubit.setPrefDate(d);
                    },
                    icon: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: Text(
                      state.prefDate == null
                          ? t.protPickDate
                          : state.prefDate!
                              .toIso8601String()
                              .substring(0, 10),
                      style: TextStyle(fontSize: context.rf(11.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.8)),
                      foregroundColor: scheme.onSurface,
                    ),
                    onPressed: () async {
                      final tm = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (tm != null) {
                        cubit.setPrefTime(
                            '${tm.hour.toString().padLeft(2, '0')}:${tm.minute.toString().padLeft(2, '0')}');
                      }
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(
                      state.prefTime ?? t.offersPickTime,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: context.rf(11.5)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
            ],
            if (cubit.kind == OfferFormKind.finance) ...[
              _Field(
                  controller: cubit.identity,
                  label: t.formIdentity,
                  keyboard: TextInputType.number,
                  ltr: true),
              const SizedBox(height: 12),
              _Field(
                  controller: cubit.income,
                  label: t.offersIncome,
                  keyboard: TextInputType.number),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(t.offersPeriod,
                    style: TextStyle(
                        fontSize: context.rf(12),
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.7))),
              ),
              const SizedBox(height: 8),
              Row(children: [
                for (final p in periods)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: context.rs(8)),
                    child: ChoiceChip(
                      label: Text('$p'),
                      selected: state.period == p,
                      onSelected: (_) => cubit.selectPeriod(p),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
            ],
            _Field(controller: cubit.note, label: t.formNoteOptional, maxLines: 2),
            const SizedBox(height: 18),
            if (state.phase == OfferFormPhase.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(t.offersSubmitFailed,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: scheme.error, fontSize: context.rf(12))),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(
                      fontSize: context.rf(14), fontWeight: FontWeight.w800)),
              onPressed: state.phase == OfferFormPhase.busy
                  ? null
                  : () => context.read<OfferFormCubit>().submit(lang),
              child: state.phase == OfferFormPhase.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(t.commonSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboard,
    this.maxLines = 1,
    this.ltr = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final int maxLines;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      textDirection: ltr ? TextDirection.ltr : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
