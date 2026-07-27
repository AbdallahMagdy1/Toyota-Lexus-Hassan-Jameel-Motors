import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/car_sheet_cubit.dart';
import 'widgets/method_forms.dart';

/// Opens the purchase bottom sheet for a car — NZ-style sheet (92% height,
/// 300ms slide) with the card image flying in via Hero.
Future<void> openCarSheet(BuildContext context, OnlineVehicle vehicle) {
  final brandKey = context.read<ThemeCubit>().state.brandKey;
  return showHeroBottomSheet(
    context,
    builder: (_) => BlocProvider(
      create: (_) => CarSheetCubit(sl(), vehicle, brandKey: brandKey),
      child: CarSheet(vehicle: vehicle),
    ),
  );
}

final class CarSheet extends StatelessWidget {
  const CarSheet({super.key, required this.vehicle});

  final OnlineVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CarSheetCubit>().state;
    return Column(
      children: [
        const SheetHandle(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(anim),
                child: child,
              ),
            ),
            child: switch (state.page) {
              SheetPage.overview =>
                _Overview(key: const ValueKey('overview'), vehicle: vehicle),
              SheetPage.methods =>
                _MethodsPage(key: const ValueKey('methods'), vehicle: vehicle),
              SheetPage.form =>
                MethodFormPage(key: const ValueKey('form'), vehicle: vehicle),
              SheetPage.success =>
                SheetSuccess(key: const ValueKey('success'), vehicle: vehicle),
            },
          ),
        ),
      ],
    );
  }
}

/// Sheet top bar: back chevron + centered title + trailing dots.
final class SheetTopBar extends StatelessWidget {
  const SheetTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(10)),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            ),
            icon: Icon(Icons.chevron_left_rounded, size: 24, color: scheme.onSurface),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: context.rf(15.5), fontWeight: FontWeight.w800),
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/* ───────────────── Overview — Tesla-style "Select Your Car" ───────────────── */

final class _Overview extends StatelessWidget {
  const _Overview({super.key, required this.vehicle});

  final OnlineVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<CarSheetCubit>();
    final state = context.watch<CarSheetCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final detail = state.detail;

    return Column(
      children: [
        SheetTopBar(
          title: '${vehicle.name(lang)} ${vehicle.year ?? ''}'.trim(),
          onBack: () => Navigator.of(context).maybePop(),
          trailing: IconButton(
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(t.homeComingSoonFeature))),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
            children: [
              // Image + right-aligned specs stack (top speed / range style).
              SizedBox(
                height: context.rs(210),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      start: 0,
                      top: context.rs(10),
                      bottom: 0,
                      width: MediaQuery.sizeOf(context).width * 0.62,
                      child: Hero(
                        tag: 'car-${vehicle.slug}',
                        child: HomeImage(
                          url: vehicle.image,
                          fit: BoxFit.contain,
                          logicalWidth: MediaQuery.sizeOf(context).width * 0.7,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      top: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (detail?.hp != null)
                            _SpecStat(value: '${detail!.hp!.round()}', label: t.specHp),
                          if (detail?.petrol != null && detail!.petrol!.isNotEmpty)
                            _SpecStat(value: detail.petrol!, label: t.specFuel),
                          if (detail?.seatsNumber != null)
                            _SpecStat(value: '${detail!.seatsNumber}', label: t.specSeats),
                          if (detail?.cylinders != null)
                            _SpecStat(
                                value: '${detail!.cylinders}', label: t.specCylinders),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 120.ms)
                          .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rs(14)),
              Text(
                t.sheetSelectYourCar,
                style: TextStyle(
                    fontSize: context.rf(22),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4),
              ),
              if (vehicle.subtitle(lang).isNotEmpty) ...[
                SizedBox(height: context.rs(6)),
                Text(
                  vehicle.subtitle(lang),
                  style: TextStyle(
                    fontSize: context.rf(12.5),
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
              SizedBox(height: context.rs(16)),

              // Variant-style color rows: selected row = filled dark pill with
              // the price, like the Tesla trim selector.
              if (state.loading && vehicle.uniqueColors.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final c in vehicle.uniqueColors)
                  _ColorRow(
                    color: c,
                    selected: state.color?.exteriorCode == c.exteriorCode,
                    price: vehicle.minPrice,
                    lang: lang,
                    onTap: () => cubit.selectColor(c),
                  ),
              SizedBox(height: context.rs(90)),
            ],
          ),
        ),

        // Bottom bar: big price + NEXT.
        Container(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(12), context.rs(20), context.rs(14)),
          decoration: BoxDecoration(
            color: scheme.surface,
            border:
                Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.color != null)
                      Text(
                        state.color!.name(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(10.5),
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    PriceText(
                      price: vehicle.minPrice,
                      currency: t.currency,
                      contactForPrice: t.homeContactForPrice,
                      fontSize: context.rf(20),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: cubit.goToMethods,
                style: FilledButton.styleFrom(
                  minimumSize: Size(context.rs(130), context.rs(50)),
                  textStyle: TextStyle(
                    fontSize: context.rf(13.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                child: Text(t.sheetNext),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}

/// Big right-aligned stat: value bold, label muted underneath.
final class _SpecStat extends StatelessWidget {
  const _SpecStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: context.rf(19),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: context.rf(10.5),
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tesla trim-row style color selector: selected = filled dark pill with the
/// price; unselected = outlined row with the swatch + name.
final class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.color,
    required this.selected,
    required this.price,
    required this.lang,
    required this.onTap,
  });

  final CarColor color;
  final bool selected;
  final double? price;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Filled row is near-black in light mode, near-white in dark — the
    // Tesla-style high-contrast pill, theme-aware.
    final fillColor = isDark ? Colors.white : const Color(0xFF141519);
    final fillFg = isDark ? const Color(0xFF141519) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(10)),
      child: Material(
        color: selected ? fillColor : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
                horizontal: context.rs(14), vertical: context.rs(13)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : scheme.outline.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: context.rs(24),
                    height: context.rs(24),
                    child: HomeImage(url: color.image, logicalWidth: 24),
                  ),
                ),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Text(
                    color.name(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rf(13),
                      fontWeight: FontWeight.w700,
                      color: selected ? fillFg : scheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: context.rs(8)),
                PriceText(
                  price: price,
                  currency: '',
                  contactForPrice:
                      AppLocalizations.of(context).homeContactForPrice,
                  fontSize: context.rf(12.5),
                  color:
                      selected ? fillFg : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────────── Methods page — the website's three-way checkout ───────────── */

final class _MethodsPage extends StatelessWidget {
  const _MethodsPage({super.key, required this.vehicle});

  final OnlineVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<CarSheetCubit>();
    final state = context.watch<CarSheetCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SheetTopBar(title: t.sheetHowToBuy, onBack: cubit.backToOverview),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
            children: [
              SizedBox(height: context.rs(6)),
              MethodCard(
                method: PurchaseMethod.reserve,
                selected: state.method == PurchaseMethod.reserve,
                title: t.methodReserveTitle,
                badge: t.methodReserveBadge,
                authBadge: t.methodSignIn,
                price: Text.rich(
                  TextSpan(children: [
                    riyalSpan(
                        fontSize: context.rf(11.5), color: scheme.primary),
                    TextSpan(
                        text:
                            '${formatPrice(cubit.downPayment)} · ${t.methodRefundable}'),
                  ]),
                  textDirection: TextDirection.ltr,
                ),
                bullets: [t.methodReserveB1, t.methodReserveB2, t.methodReserveB3],
                onTap: () => cubit.selectMethod(PurchaseMethod.reserve),
              ),
              MethodCard(
                method: PurchaseMethod.finance,
                selected: state.method == PurchaseMethod.finance,
                title: t.methodFinanceTitle,
                price: Text(t.methodFree),
                bullets: [t.methodFinanceB1, t.methodFinanceB2, t.methodFinanceB3],
                onTap: () => cubit.selectMethod(PurchaseMethod.finance),
              ),
              MethodCard(
                method: PurchaseMethod.contact,
                selected: state.method == PurchaseMethod.contact,
                title: t.methodContactTitle,
                price: Text(t.methodFree),
                bullets: [t.methodContactB1, t.methodContactB2],
                onTap: () => cubit.selectMethod(PurchaseMethod.contact),
              ),
              SizedBox(height: context.rs(20)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(10), context.rs(20), context.rs(14)),
          decoration: BoxDecoration(
            color: scheme.surface,
            border:
                Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: state.accepted,
                  onChanged: (v) => cubit.toggleAccepted(v ?? false),
                ),
              ),
              Expanded(
                child: Text(
                  t.sheetTerms,
                  style: TextStyle(
                    fontSize: context.rf(10.5),
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              SizedBox(width: context.rs(10)),
              FilledButton(
                onPressed: state.accepted ? cubit.continueToForm : null,
                style: FilledButton.styleFrom(
                  minimumSize: Size(context.rs(122), context.rs(46)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.sheetContinue),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 220.ms);
  }
}
