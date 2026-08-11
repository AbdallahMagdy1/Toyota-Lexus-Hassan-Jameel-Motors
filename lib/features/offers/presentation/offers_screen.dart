import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/offers_cubit.dart';
import '../data/offers_repository.dart';
import '../domain/offer_models.dart';
import 'offer_detail_sheet.dart';

/// The offers page — the website's /offers, section for section: one call
/// returns all active offers + the type catalog, and each type with offers
/// becomes a section (vehicle offers, maintenance offers, …). Brand filter
/// follows the app's Toyota/Lexus switch via BrandList, like the website.
final class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key, this.initialTypeId});

  /// Deep-link filter (e.g. maintenance offers quick action).
  final int? initialTypeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OffersCubit(
        OffersRepository(sl<ApiClient>()),
        initialTypeId: initialTypeId,
      ),
      child: const _OffersView(),
    );
  }
}

final class _OffersView extends StatelessWidget {
  const _OffersView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<OffersCubit>().state;
    final cubit = context.read<OffersCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    final wantedDbId = brandKey == 'lexus' ? '2' : '1';

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: switch (state.status) {
            OffersStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            OffersStatus.error => Center(
                child: TextButton(
                    onPressed: cubit.load, child: Text(t.homeErrorRetry))),
            OffersStatus.ready => _Body(
                state: state,
                lang: lang,
                wantedDbId: wantedDbId,
              ),
          },
        ),
      ],
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.lang,
    required this.wantedDbId,
  });

  final OffersState state;
  final String lang;
  final String wantedDbId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<OffersCubit>();
    final sections = state.sections(wantedDbId);

    // Type chips: All + only the types that actually have offers.
    final chipTypes = state.types
        .where((ty) => state.offers.any(
            (o) => o.typeId == ty.id && o.visibleForBrand(wantedDbId)))
        .toList();
    final selectedIndex = state.selectedTypeId == null
        ? 0
        : chipTypes.indexWhere((ty) => ty.id == state.selectedTypeId) + 1;

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(18), context.rs(20), context.rs(10)),
              child: Text(
                t.offersTitle,
                style: TextStyle(
                    fontSize: context.rf(24), fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FilterChipsRow(
              labels: [t.homeAll, ...chipTypes.map((ty) => ty.name(lang))],
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onSelected: (i) =>
                  cubit.selectType(i == 0 ? null : chipTypes[i - 1].id),
            ),
          ),
          if (sections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(t.offersEmpty)),
            ),
          for (final (type, offers) in sections) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(22),
                    context.rs(20), context.rs(10)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        type.name(lang),
                        style: TextStyle(
                            fontSize: context.rf(18),
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rs(9), vertical: context.rs(3)),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${offers.length}',
                        style: TextStyle(
                          fontSize: context.rf(11),
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList.separated(
              itemCount: offers.length,
              separatorBuilder: (_, _) => SizedBox(height: context.rs(14)),
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
                child: OfferCard(
                  offer: offers[i],
                  lang: lang,
                  now: state.now ?? DateTime.now(),
                ).animate(delay: (40 * (i % 4)).ms).fadeIn(duration: 240.ms),
              ),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: context.rs(140))),
        ],
      ),
    );
  }
}

/// Offer card — image, type tag, title, excerpt, live countdown and the
/// "View offer" pill, like the website's OfferCard.
final class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.lang,
    required this.now,
    this.forMyCar = false,
    this.expand = false,
  });

  final SiteOffer offer;
  final String lang;
  final DateTime now;

  /// The customer's own car is among this offer's supported vehicles.
  final bool forMyCar;

  /// Fixed-height rail mode: the countdown + CTA anchor to the card bottom
  /// so short excerpts never leave a dead gap in the middle.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return HomeCard(
      onTap: () => showOfferDetailSheet(context, offer.slug),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              HomeImage(
                  url: offer.image(lang), aspectRatio: 16 / 8, logicalWidth: 400),
              // "FOR YOUR VEHICLE" — the mock's solid red pill, top-start.
              if (forMyCar)
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(10), vertical: context.rs(5)),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.directions_car_filled_rounded,
                          size: 11, color: scheme.onPrimary),
                      SizedBox(width: context.rs(5)),
                      Text(
                        t.offersForYourCar,
                        style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: context.rf(9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6),
                      ),
                    ]),
                  ),
                )
              else
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(10), vertical: context.rs(4)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      offer.typeName(lang),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rf(10),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          _content(context, t, scheme),
        ],
      ),
    );
  }

  /// Title + excerpt, then the countdown strip and the claim CTA. In [expand]
  /// mode (fixed-height rail) a Spacer pushes the strip + CTA to the bottom
  /// so cards stay aligned no matter how long the excerpt is.
  Widget _content(BuildContext context, AppLocalizations t, ColorScheme scheme) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          offer.title(lang),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: context.rf(16),
              fontWeight: FontWeight.w800,
              height: 1.3),
        ),
        if (offer.excerpt(lang).isNotEmpty) ...[
          SizedBox(height: context.rs(5)),
          Text(
            offer.excerpt(lang),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.rf(11.5),
              color: scheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
        if (expand) const Spacer() else SizedBox(height: context.rs(12)),
        // Full-width countdown strip (mock's DAYS/HRS/MIN/SEC panel).
        OfferCountdown(endDate: offer.endDate, now: now),
        SizedBox(height: context.rs(12)),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: TextStyle(
                  fontSize: context.rf(12.5), fontWeight: FontWeight.w800),
            ),
            onPressed: () => showOfferDetailSheet(context, offer.slug),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.offersClaim),
                SizedBox(width: context.rs(7)),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final padded = Padding(
      padding: EdgeInsets.all(context.rs(16)),
      child: column,
    );
    return expand ? Expanded(child: padded) : padded;
  }
}

/// DAY/HOUR/MIN/SEC countdown tiles driven by the cubit's 1s clock — the
/// website's OfferCard timer, mobile-sized.
final class OfferCountdown extends StatelessWidget {
  const OfferCountdown({super.key, required this.endDate, required this.now});

  final DateTime? endDate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final remaining =
        endDate == null ? Duration.zero : endDate!.difference(now);
    final ms = remaining.isNegative ? Duration.zero : remaining;
    if (ms == Duration.zero) {
      return Text(
        t.offersEnded,
        style: TextStyle(
            fontSize: context.rf(11),
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.5)),
      );
    }
    final tiles = <(String, String)>[
      ('${ms.inDays}', t.offersDay),
      ('${ms.inHours % 24}', t.offersHour),
      ('${ms.inMinutes % 60}', t.offersMin),
      ('${ms.inSeconds % 60}', t.offersSec),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The mock's full-width light panel: red numbers over tiny gray labels.
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.rs(10)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          for (final (value, label) in tiles)
            Expanded(
              child: Column(
                children: [
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.rf(15),
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(height: context.rs(1)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.rf(8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
