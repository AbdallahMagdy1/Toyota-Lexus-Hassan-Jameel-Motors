import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/slope_hero.dart';
import '../../finance/data/finance_repository.dart';
import '../../finance/domain/finance_math.dart';
import '../../finance/domain/finance_models.dart';
import '../../finance/presentation/finance_lead_sheet.dart';
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
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Reference-mock header: curved slope blob (car_bg match →
              // model shared Background → brand gradient) with the eyebrow +
              // model name on it and the car overlapping its bottom curve. ──
              SlopeHero(
                eyebrow: [
                  (vehicle.brandEn ?? '').trim().toUpperCase(),
                  (vehicle.year ?? '').trim(),
                ].where((s) => s.isNotEmpty).join(' · '),
                title: vehicle.name(lang),
                modelKey: vehicle.groupEn,
                year: vehicle.year,
                background: vehicle.background(lang),
                topBar: Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.rs(12), context.rs(8), context.rs(12), 0),
                  child: Row(children: [
                    SlopeBarButton(
                      // Auto-mirrors in RTL — no manual flip.
                      icon: Icons.chevron_left_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    SlopeBarButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text(t.homeComingSoonFeature))),
                    ),
                  ]),
                ),
                car: Hero(
                  tag: 'car-${vehicle.slug}',
                  child: HomeImage(
                    url: vehicle.image,
                    fit: BoxFit.contain,
                    logicalWidth: MediaQuery.sizeOf(context).width,
                  ),
                ),
              ),
              // ── Content resumes under the overlapping car. ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.rs(12)),
                    if (detail != null)
                      Wrap(
                        spacing: context.rs(8),
                        runSpacing: context.rs(8),
                        children: [
                          if (detail.hp != null)
                            _SpecStat(
                                value: '${detail.hp!.round()}',
                                label: t.specHp),
                          if ((detail.petrol ?? '').isNotEmpty)
                            _SpecStat(value: detail.petrol!, label: t.specFuel),
                          if (detail.seatsNumber != null)
                            _SpecStat(
                                value: '${detail.seatsNumber}',
                                label: t.specSeats),
                          if (detail.cylinders != null)
                            _SpecStat(
                                value: '${detail.cylinders}',
                                label: t.specCylinders),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 100.ms)
                          .slideY(
                              begin: 0.08,
                              end: 0,
                              curve: Curves.easeOutCubic),
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

                    // Variant-style color rows: selected row = filled dark
                    // pill with the price, like the Tesla trim selector.
                    if (state.loading && vehicle.uniqueColors.isEmpty)
                      SkeletonList(itemCount: 3, itemHeight: context.rs(52))
                    else
                      for (final c in vehicle.uniqueColors)
                        _ColorRow(
                          color: c,
                          selected:
                              state.color?.exteriorCode == c.exteriorCode,
                          price: vehicle.minPrice,
                          lang: lang,
                          onTap: () => cubit.selectColor(c),
                        ),
                    SizedBox(height: context.rs(90)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom bar: finance CTA (online-buyable cars only) + price + NEXT.
        Container(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(12), context.rs(20), context.rs(14)),
          decoration: BoxDecoration(
            color: scheme.surface,
            border:
                Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.5))),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _StoreFinanceCta(vehicle: vehicle),
            SizedBox(height: context.rs(10)),
            Row(
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
          ]),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}

/// طلب تمويل — moved here from the models sheet: finance requests are only
/// for online-buyable cars. Cheapest bank (FinanceBenefitReport sort) then
/// the same finance sheet.
final class _StoreFinanceCta extends StatefulWidget {
  const _StoreFinanceCta({required this.vehicle});

  final OnlineVehicle vehicle;

  @override
  State<_StoreFinanceCta> createState() => _StoreFinanceCtaState();
}

final class _StoreFinanceCtaState extends State<_StoreFinanceCta> {
  bool _busy = false;

  Future<void> _open() async {
    final price = widget.vehicle.minPrice ?? 0;
    if (price <= 0) return;
    setState(() => _busy = true);
    final repo = FinanceRepository(sl());
    final results = await Future.wait([repo.banks(), repo.filters()]);
    if (!mounted) return;
    setState(() => _busy = false);
    final banks = results[0] as List<FinanceBank>;
    final filters = results[1] as FinanceFilters;
    if (banks.isEmpty) return;
    final sorted = [...banks]..sort((a, b) =>
        computeFinance(price, a, a.defaultFinancePeriod)
            .monthly
            .compareTo(
                computeFinance(price, b, b.defaultFinancePeriod).monthly));
    final v = widget.vehicle;
    showFinanceLeadSheet(
      context,
      bank: sorted.first,
      car: FinanceVehicle(
        slug: v.slug,
        productId: v.productId,
        year: v.year,
        groupAr: v.groupAr ?? v.groupEn,
        groupEn: v.groupEn,
        minPrice: price,
      ),
      custGroups: filters.custGroups,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
          foregroundColor: scheme.primary,
          textStyle: TextStyle(
              fontSize: context.rf(13), fontWeight: FontWeight.w800),
        ),
        onPressed: _busy ? null : _open,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.account_balance_rounded, size: 17),
        label: Text(t.finReqTitle),
      ),
    );
  }
}

/// Compact stat chip (hairline border, no shadow): value bold, label muted.
final class _SpecStat extends StatelessWidget {
  const _SpecStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(13), vertical: context.rs(8)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: context.rf(14.5),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: context.rf(9.5),
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

/// The website's OnlineCheckout method picker, 1:1: three selectable cards
/// (Quick reservation — BEST CHOICE, down payment + "Refundable"; Apply for
/// finance — FREE; Request a callback — FREE) each with its benefit bullet
/// list, then the T&C checkbox (tappable policy links) and Continue. Cars not
/// buyable online collapse to the callback card only, like the website.
final class _MethodsPage extends StatelessWidget {
  const _MethodsPage({super.key, required this.vehicle});

  final OnlineVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<CarSheetCubit>();
    final state = context.watch<CarSheetCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    // Website: cars NOT available online only offer the callback method.
    final availableOnline = state.detail?.buyOnline ?? true;
    if (!availableOnline && state.method != PurchaseMethod.contact) {
      // Keep the cubit selection legal for the collapsed card set.
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => cubit.selectMethod(PurchaseMethod.contact));
    }

    final downPayment = Text.rich(
      TextSpan(children: [
        TextSpan(children: [
          riyalSpan(fontSize: context.rf(13), color: scheme.primary),
          TextSpan(text: formatPrice(cubit.downPayment)),
        ]),
        TextSpan(
            text: '\n${t.methodRefundable}',
            style: TextStyle(
                fontSize: context.rf(9.5),
                fontStyle: FontStyle.normal,
                color: scheme.onSurface.withValues(alpha: 0.6))),
      ]),
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr,
      style: TextStyle(
          fontSize: context.rf(13),
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          color: scheme.primary),
    );

    Widget free() => _FreeBadge(text: t.methodFree);

    return Column(
      children: [
        SheetTopBar(title: t.sheetHowToBuy, onBack: cubit.backToOverview),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                context.rs(20), context.rs(8), context.rs(20), context.rs(16)),
            children: [
              if (availableOnline) ...[
                MethodCard(
                  method: PurchaseMethod.reserve,
                  selected: state.method == PurchaseMethod.reserve,
                  title: t.methodReserveTitle,
                  badge: t.methodReserveBadge,
                  authBadge: t.methodSignIn,
                  price: downPayment,
                  bullets: [
                    t.methodReserveB1,
                    t.methodReserveB2,
                    t.methodReserveB3,
                  ],
                  onTap: () => cubit.selectMethod(PurchaseMethod.reserve),
                ),
                MethodCard(
                  method: PurchaseMethod.finance,
                  selected: state.method == PurchaseMethod.finance,
                  title: t.methodFinanceTitle,
                  price: free(),
                  bullets: [
                    t.methodFinanceB1,
                    t.methodFinanceB2,
                    t.methodFinanceB3,
                  ],
                  onTap: () => cubit.selectMethod(PurchaseMethod.finance),
                ),
              ],
              MethodCard(
                method: PurchaseMethod.contact,
                selected: state.method == PurchaseMethod.contact,
                title: t.methodContactTitle,
                price: free(),
                bullets: [t.methodContactB1, t.methodContactB2],
                onTap: () => cubit.selectMethod(PurchaseMethod.contact),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(10), context.rs(20), context.rs(14)),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
                top: BorderSide(color: scheme.outline.withValues(alpha: 0.5))),
          ),
          child: Column(children: [
            Row(children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: state.accepted,
                  onChanged: (v) => cubit.toggleAccepted(v ?? false),
                ),
              ),
              const Expanded(child: TermsText()),
            ]),
            SizedBox(height: context.rs(8)),
            FilledButton(
              onPressed: state.accepted ? cubit.continueToForm : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                textStyle: TextStyle(
                    fontSize: context.rf(13.5), fontWeight: FontWeight.w800),
              ),
              child: Text(t.sheetContinue),
            ),
          ]),
        ),
      ],
    ).animate().fadeIn(duration: 220.ms);
  }
}

final class _FreeBadge extends StatelessWidget {
  const _FreeBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: context.rf(10),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: scheme.primary,
        ),
      ),
    );
  }
}

/// "I have read the [terms & conditions] and [privacy policy]." — the
/// website's checkbox label with both policies as tappable links.
final class TermsText extends StatelessWidget {
  const TermsText({super.key});

  static const _termsUrl = 'https://hassanjameel.com.sa/website-policy';
  static const _privacyUrl = 'https://hassanjameel.com.sa/privacy';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    TextStyle link() => TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary,
        );
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: context.rf(10.5),
          height: 1.45,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
        children: [
          TextSpan(text: t.termsPrefix),
          TextSpan(
            text: t.linkTerms,
            style: link(),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse(_termsUrl),
                  mode: LaunchMode.externalApplication),
          ),
          TextSpan(text: t.termsJoin),
          TextSpan(
            text: t.linkPrivacy,
            style: link(),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse(_privacyUrl),
                  mode: LaunchMode.externalApplication),
          ),
          TextSpan(text: t.termsSuffix),
        ],
      ),
    );
  }
}
