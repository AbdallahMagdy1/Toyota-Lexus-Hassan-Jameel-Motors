import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../offers/presentation/offer_detail_sheet.dart';
import '../../../online_store/presentation/car_sheet.dart';
import '../../../vehicles/presentation/model_sheet.dart';
import '../../../settings/bloc/locale_cubit.dart';
import '../../bloc/home_cubit.dart';
import '../../domain/home_models.dart';
import 'home_bits.dart';

void _soon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).homeComingSoonFeature)));
}

/* ------------------------- 2 — Online store ------------------------- */

/// Tesla-app-style editorial cards: alternating dark/light panels, car image
/// on top, bold model name + price, "Learn more" + brand arrow block.
final class OnlineStoreRail extends StatelessWidget {
  const OnlineStoreRail({super.key, required this.vehicles, required this.lang});

  final List<OnlineVehicle> vehicles;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CardRail(
      height: context.rs(316),
      itemWidth: context.rs(216),
      itemCount: vehicles.length,
      itemBuilder: (context, i) {
        final v = vehicles[i];
        // Alternate panels: brand-primary card / neutral card (لون ولون) —
        // the primary follows the active brand theme in light AND dark mode.
        final primaryPanel = i.isEven;
        final bg = primaryPanel
            ? scheme.primary
            : (isDark ? const Color(0xFF23252B) : const Color(0xFFEDEEF0));
        final fg = primaryPanel
            ? scheme.onPrimary
            : (isDark ? Colors.white : const Color(0xFF141519));
        // Arrow block contrasts with its panel.
        final arrowBg = primaryPanel ? scheme.onPrimary : scheme.primary;
        final arrowFg = primaryPanel ? scheme.primary : scheme.onPrimary;

        return Material(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openCarSheet(context, v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(context.rs(10)),
                    child: Hero(
                      tag: 'car-${v.slug}',
                      child: HomeImage(
                        url: v.image,
                        fit: BoxFit.contain,
                        logicalWidth: 216,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.rs(14), 0, context.rs(14), context.rs(4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(21),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: fg,
                        ),
                      ),
                      SizedBox(height: context.rs(2)),
                      PriceText(
                        price: v.minPrice,
                        currency: t.currency,
                        contactForPrice: t.homeContactForPrice,
                        fontSize: context.rf(12.5),
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.rs(10)),
                // Bottom row: "Learn more" + brand arrow block, edge-to-edge.
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: context.rs(14)),
                      child: Text(
                        t.sheetLearnMore,
                        style: TextStyle(
                          fontSize: context.rf(11.5),
                          fontWeight: FontWeight.w700,
                          color: fg.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: context.rs(56),
                      height: context.rs(40),
                      color: arrowBg,
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20,
                        color: arrowFg,
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

}

/* --------------------- 3 — Vehicles (Meet the models) --------------------- */

final class VehiclesRail extends StatelessWidget {
  const VehiclesRail({super.key, required this.vehicles, required this.lang});

  final List<SliderVehicle> vehicles;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CardRail(
      height: context.rs(252),
      itemWidth: context.rs(236),
      itemCount: vehicles.length,
      itemBuilder: (context, i) {
        final v = vehicles[i];
        return HomeCard(
          onTap: () => openModelSheet(context, v),
          child: Padding(
            padding: EdgeInsets.all(context.rs(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Center(
                        child: Hero(
                            tag: 'model-${v.slug}',
                            child: HomeImage(
                                url: v.image(lang),
                                fit: BoxFit.contain,
                                logicalWidth: 236)))),
                SizedBox(height: context.rs(8)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.name(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(15.5), fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (v.year != null)
                      Text(
                        v.year!,
                        style: TextStyle(
                          fontSize: context.rf(11.5),
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: context.rs(4)),
                if (v.showPrice && v.minPrice != null)
                  Row(
                    children: [
                      Text(
                        '${t.homeFrom} ',
                        style: TextStyle(
                          fontSize: context.rf(11),
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      PriceText(
                        price: v.minPrice,
                        currency: t.currency,
                        contactForPrice: t.homeContactForPrice,
                        fontSize: context.rf(14),
                      ),
                    ],
                  ),
                SizedBox(height: context.rs(8)),
                Row(
                  children: [
                    if (v.hp != null) _Spec(icon: Icons.speed_rounded, value: '${v.hp!.round()} HP'),
                    if (v.cylinders != null)
                      _Spec(icon: Icons.settings_rounded, value: '${v.cylinders}'),
                    if (v.seatsNumber != null)
                      _Spec(icon: Icons.airline_seat_recline_normal_rounded, value: '${v.seatsNumber}'),
                    if (v.hybrid) _Spec(icon: Icons.eco_rounded, value: 'HEV'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: context.rs(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.rs(13), color: scheme.primary),
          SizedBox(width: context.rs(3)),
          Text(
            value,
            style: TextStyle(
              fontSize: context.rf(10.5),
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------- 4 — Protection & shading --------------------- */

final class ProtectionCard extends StatelessWidget {
  const ProtectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<HomeCubit>().state;
    final cubit = context.read<HomeCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    final groups = state.feed.protectionGroupOptions;
    final models = state.protectionModels;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(26), context.rs(20), 0),
      child: HomeCard(
        padding: EdgeInsets.all(context.rs(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.homeProtection,
                style:
                    TextStyle(fontSize: context.rf(19), fontWeight: FontWeight.w800)),
            SizedBox(height: context.rs(6)),
            Text(
              t.homeProtectionDesc,
              style: TextStyle(
                fontSize: context.rf(12.5),
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: context.rs(16)),
            // Step 1 — car group (Camry 2026, LS 2025…), same as the website.
            AppDropdown<ProtectionGroup>(
              label: t.homeSelectCar,
              value: state.protectionGroup,
              hint: t.homeSelectCar,
              items: [
                for (final g in groups)
                  AppDropdownItem(value: g, label: g.label(lang)),
              ],
              onChanged: cubit.selectProtectionGroup,
            ),
            SizedBox(height: context.rs(14)),
            // Step 2 — trim/model inside the group (productTypeID).
            AppDropdown<ProtectionModel>(
              label: t.homeSelectModel,
              value: state.protectionModel,
              hint: t.homeSelectModel,
              enabled: state.protectionGroup != null,
              items: [
                for (final m in models)
                  AppDropdownItem(value: m, label: m.name(lang)),
              ],
              onChanged: cubit.selectProtectionModel,
            ),
            SizedBox(height: context.rs(14)),
            if (state.protectionLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
              )
            else
              AppDropdown<String>(
                label: t.homeServiceType,
                value: state.protectionService?.id,
                hint: t.homeServiceType,
                items: [
                  for (final s in state.protectionServices)
                    AppDropdownItem(
                      value: s.id ?? '',
                      label: s.name(lang),
                      subtitle:
                          s.price == null ? null : formatPrice(s.price!),
                    ),
                ],
                onChanged: (id) {
                  final s = state.protectionServices.where((x) => x.id == id);
                  if (s.isNotEmpty) cubit.selectProtectionService(s.first);
                },
              ),
            SizedBox(height: context.rs(16)),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // The full catalog lives on the Protection & shading screen.
                onPressed: () => context.push(Routes.protection),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(t.homeCheckAvailability.toUpperCase(),
                    style: TextStyle(
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- 5 — Spare parts --------------------------- */

final class PartsRail extends StatelessWidget {
  const PartsRail({super.key, required this.parts, required this.lang});

  final List<SparePart> parts;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CardRail(
      height: context.rs(228),
      itemWidth: context.rs(164),
      itemCount: parts.length,
      itemBuilder: (context, i) {
        final p = parts[i];
        return HomeCard(
          onTap: () => context.push(Routes.parts),
          child: Padding(
            padding: EdgeInsets.all(context.rs(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: HomeImage(url: p.image, aspectRatio: 1.35, logicalWidth: 164),
                ),
                SizedBox(height: context.rs(8)),
                PriceText(
                  price: p.salesPrice,
                  currency: t.currency,
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(13),
                ),
                SizedBox(height: context.rs(3)),
                Expanded(
                  child: Text(
                    p.name(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(12), fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(Routes.parts),
                  child: Row(
                    children: [
                      Text(
                        t.homeAddToCart,
                        style: TextStyle(
                          fontSize: context.rf(10.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(width: context.rs(4)),
                      Icon(Icons.add_shopping_cart_rounded,
                          size: context.rs(13), color: scheme.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ---------------------------- 6 — Used cars ---------------------------- */

final class UsedCarsRail extends StatelessWidget {
  const UsedCarsRail({super.key, required this.cars});

  final List<UsedCar> cars;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CardRail(
      height: context.rs(240),
      itemWidth: context.rs(220),
      itemCount: cars.length,
      itemBuilder: (context, i) {
        final c = cars[i];
        return HomeCard(
          onTap: () => _soon(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  HomeImage(url: c.coverImage, aspectRatio: 16 / 10, logicalWidth: 220),
                  if (c.inspectionBadge != null && c.inspectionBadge!.isNotEmpty)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(8), vertical: context.rs(4)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18A957),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t.homeInspected,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rf(9.5),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (c.carYear != null)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(8), vertical: context.rs(4)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${c.carYear}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rf(10.5),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.rs(12), context.rs(10), context.rs(12), context.rs(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(14.5), fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PriceText(
                            price: c.price,
                            currency: t.currency,
                            contactForPrice: t.homeContactForPrice,
                            fontSize: context.rf(14),
                          ),
                          if (c.mileage != null)
                            Text(
                              '${c.mileage} km',
                              style: TextStyle(
                                fontSize: context.rf(11),
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                        ],
                      ),
                    ],
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

/// Empty-state for the used-cars section (no approved listings yet) with the
/// website's "List your car" CTA.
final class UsedCarsEmptyCard extends StatelessWidget {
  const UsedCarsEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
      child: HomeCard(
        padding: EdgeInsets.all(context.rs(20)),
        child: Row(
          children: [
            Icon(Icons.directions_car_filled_outlined,
                size: context.rs(34), color: scheme.primary),
            SizedBox(width: context.rs(14)),
            Expanded(
              child: Text(
                t.homeUsedCarsEmpty,
                style: TextStyle(
                  fontSize: context.rf(12.5),
                  height: 1.4,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
            SizedBox(width: context.rs(10)),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(
                    horizontal: context.rs(14), vertical: context.rs(10)),
                textStyle: TextStyle(
                    fontSize: context.rf(12), fontWeight: FontWeight.w700),
              ),
              onPressed: () => _soon(context),
              child: Text(t.homeListYourCar),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------- 7 & 8 — Offer rails (maint + vehicles) ------------------- */

final class OffersRail extends StatelessWidget {
  const OffersRail({
    super.key,
    required this.offers,
    required this.lang,
    required this.ctaLabel,
  });

  final List<HomeOffer> offers;
  final String lang;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CardRail(
      height: context.rs(238),
      itemWidth: context.rs(258),
      itemCount: offers.length,
      itemBuilder: (context, i) {
        final o = offers[i];
        final days = o.daysLeft;
        return HomeCard(
          onTap: () => showOfferDetailSheet(context, o.slugEn),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeImage(url: o.image(lang), aspectRatio: 16 / 8.4, logicalWidth: 258),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.rs(12), context.rs(10), context.rs(12), context.rs(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.title(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(13.5),
                            fontWeight: FontWeight.w800,
                            height: 1.25),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (days != null)
                            Text(
                              t.homeDaysLeft(days),
                              style: TextStyle(
                                fontSize: context.rf(10.5),
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          SizedBox(
                            height: context.rs(32),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.symmetric(horizontal: context.rs(14)),
                                textStyle: TextStyle(
                                    fontSize: context.rf(11.5),
                                    fontWeight: FontWeight.w700),
                              ),
                              onPressed: () =>
                                  showOfferDetailSheet(context, o.slugEn),
                              child: Text(ctaLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
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
