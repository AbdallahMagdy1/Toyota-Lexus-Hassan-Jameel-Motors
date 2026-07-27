import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/brand_switch_fab.dart';
import '../../finance/presentation/finance_calc_sheet.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../offers/presentation/offer_detail_sheet.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/guest_home_cubit.dart';
import '../domain/guest_home_models.dart';

/// The guest home: hero → quick actions → browse-by-type cards →
/// finance-offers carousel → services → benefit login prompt.
/// Everything browsable without an account; account-only actions surface a
/// benefit prompt instead of a hard wall.
final class GuestHomeView extends StatelessWidget {
  const GuestHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    return BlocProvider(
      key: ValueKey('guest-home-$brandKey'),
      create: (_) => GuestHomeCubit(sl(), brandKey: brandKey),
      child: const _GuestHomeBody(),
    );
  }
}

/// Benefit prompt for account-only actions (booking, finance, tracking).
void showLoginPrompt(BuildContext context) {
  final t = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_person_outlined, size: 38, color: scheme.primary),
          const SizedBox(height: 12),
          Text(t.ghLoginRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder()),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              context.go(Routes.signIn);
            },
            child: Text(t.authSignIn),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              context.go(Routes.signUp);
            },
            child: Text(t.authSignUp),
          ),
        ],
      ),
    ),
  );
}

final class _GuestHomeBody extends StatelessWidget {
  const _GuestHomeBody();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<GuestHomeCubit>().state;
    final cubit = context.read<GuestHomeCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: switch (state.status) {
            GuestHomeStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            GuestHomeStatus.error => Center(
                child: TextButton(
                    onPressed: cubit.load, child: Text(t.homeErrorRetry))),
            GuestHomeStatus.ready => RefreshIndicator(
                onRefresh: cubit.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: context.rs(140)),
                  children: [
                    _Hero(data: state.data, lang: lang),
                    _QuickActions(lang: lang),
                    if (state.data.categories.isNotEmpty) ...[
                      SectionHeader(
                        title: t.ghBrowseByType,
                        actionLabel: t.homeViewAll,
                        onAction: () => context.push(Routes.models),
                      ),
                      _CategoryRail(
                          categories: state.data.categories, lang: lang),
                    ],
                    if (state.data.vehicleOffers.isNotEmpty) ...[
                      SectionHeader(title: t.ghFinanceOffers),
                      _OffersCarousel(
                          offers: state.data.vehicleOffers, lang: lang),
                    ],
                    if (state.data.maintenanceOffers.isNotEmpty) ...[
                      SectionHeader(title: t.ghMaintOffers),
                      _OffersCarousel(
                          offers: state.data.maintenanceOffers, lang: lang),
                    ],
                    SectionHeader(title: t.ghServices),
                    _ServicesGrid(lang: lang),
                    _LoginPrompt(lang: lang),
                  ],
                ),
              ),
          },
        ),
      ],
    );
  }
}

/* ───────────────────────────── Hero ───────────────────────────── */

final class _Hero extends StatelessWidget {
  const _Hero({required this.data, required this.lang});

  final GuestHome data;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final slide = data.hero.isEmpty ? null : data.hero.first;
    final title = slide?.title(lang) ?? '';
    final subtitle = slide?.subtitle(lang) ?? '';
    final image = optimizedImageUrl(
      slide?.mediaType == 'image' ? slide?.mediaUrl : null,
      width: (MediaQuery.sizeOf(context).width *
              MediaQuery.devicePixelRatioOf(context))
          .round(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(12), context.rs(16), 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: context.rs(220),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.network(image,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: scheme.primary))
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, const Color(0xFF15171C)],
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.2, 1.0],
                    colors: [Color(0x33000000), Color(0xB3000000)],
                  ),
                ),
              ),
              // Toyota ⇄ Lexus switch — inline on the hero (replaces the
              // old floating FAB).
              PositionedDirectional(
                top: context.rs(12),
                end: context.rs(12),
                child: const BrandSwitchCapsule(),
              ),
              Padding(
                padding: EdgeInsets.all(context.rs(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title.isEmpty ? t.ghHeroTitle : title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.rf(20),
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: context.rs(4)),
                    Text(
                      subtitle.isEmpty ? t.ghHeroSubtitle : subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: context.rf(12),
                      ),
                    ),
                    SizedBox(height: context.rs(12)),
                    Row(
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: context.rs(16),
                                vertical: context.rs(10)),
                            minimumSize: Size.zero,
                            textStyle: TextStyle(
                                fontSize: context.rf(12),
                                fontWeight: FontWeight.w800),
                          ),
                          onPressed: () => context.push(Routes.models),
                          child: Text(t.ghBrowseCars),
                        ),
                        SizedBox(width: context.rs(8)),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF141519),
                            padding: EdgeInsets.symmetric(
                                horizontal: context.rs(16),
                                vertical: context.rs(10)),
                            minimumSize: Size.zero,
                            textStyle: TextStyle(
                                fontSize: context.rf(12),
                                fontWeight: FontWeight.w800),
                          ),
                          onPressed: () => showFinanceCalcSheet(context),
                          child: Text(t.ghCalcFinance),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/* ─────────────────────────── Quick actions ─────────────────────────── */

final class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final actions = <(IconData, String, VoidCallback)>[
      // Booking needs an account — benefit prompt, not a hard wall.
      (Icons.build_circle_outlined, t.ghBookMaintenance,
          () => showLoginPrompt(context)),
      // The offers page shows BOTH sections (vehicle + maintenance offers),
      // like the website's /offers; the type param just pre-filters.
      (Icons.local_offer_outlined, t.ghCarOffers,
          () => context.push(Routes.offers)),
      (Icons.car_repair_outlined, t.ghMaintOffers,
          () => context.push('${Routes.offers}?type=3')),
      (Icons.settings_suggest_outlined, t.ghSpareParts,
          () => context.push(Routes.parts)),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(16), context.rs(16), 0),
      child: Row(
        children: [
          for (final (icon, label, onTap) in actions)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(4)),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: context.rs(12)),
                      decoration: softCardDecoration(context, radius: 16),
                      child: Column(
                        children: [
                          Icon(icon, size: 22, color: scheme.primary),
                          SizedBox(height: context.rs(6)),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: context.rf(9.5),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Category cards ───────────────────────── */

final class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.categories, required this.lang});

  final List<VehicleCategory> categories;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CardRail(
      height: context.rs(150),
      itemWidth: context.rs(170),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final c = categories[i];
        return HomeCard(
          onTap: () =>
              context.push('${Routes.models}?category=${c.descEn ?? ''}'),
          child: Padding(
            padding: EdgeInsets.all(context.rs(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: HomeImage(
                        url: c.image(lang),
                        fit: BoxFit.contain,
                        logicalWidth: 170),
                  ),
                ),
                Text(
                  c.name(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(13.5), fontWeight: FontWeight.w800),
                ),
                Text(
                  t.ghCarsCount(c.carsCount),
                  style: TextStyle(
                    fontSize: context.rf(10.5),
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (30 * (i % 6)).ms).fadeIn(duration: 260.ms);
      },
    );
  }
}

/* ─────────────────────── Offers carousel ─────────────────────── */

final class _OffersCarousel extends StatelessWidget {
  const _OffersCarousel({required this.offers, required this.lang});

  final List<AppOffer> offers;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CardRail(
      height: context.rs(210),
      itemWidth: context.rs(260),
      itemCount: offers.length,
      itemBuilder: (context, i) {
        final o = offers[i];
        final days = o.daysLeft;
        return HomeCard(
          onTap: () => showOfferDetailSheet(context, o.slug),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  HomeImage(
                      url: o.image(lang), aspectRatio: 16 / 8, logicalWidth: 260),
                  if (days != null)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(8), vertical: context.rs(4)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t.homeDaysLeft(days),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: context.rf(9.5),
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(context.rs(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.title(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(13),
                            fontWeight: FontWeight.w800,
                            height: 1.25),
                      ),
                      const Spacer(),
                      Text(
                        o.typeName(lang),
                        style: TextStyle(
                          fontSize: context.rf(10.5),
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: (30 * (i % 6)).ms).fadeIn(duration: 260.ms);
      },
    );
  }
}

/* ───────────────────────── Services grid ───────────────────────── */

final class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final services = <(IconData, String, VoidCallback)>[
      (Icons.build_outlined, t.ghSvcMaintenance, () => showLoginPrompt(context)),
      (Icons.shield_outlined, t.ghSvcProtection,
          () => context.push(Routes.protection)),
      (Icons.settings_outlined, t.ghSvcParts,
          () => context.push(Routes.parts)),
      (Icons.account_balance_outlined, t.ghSvcFinance,
          () => context.push(Routes.finance)),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: context.rs(10),
        crossAxisSpacing: context.rs(10),
        childAspectRatio: 2.6,
        children: [
          for (final (icon, label, onTap) in services)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.rs(14)),
                  decoration: softCardDecoration(context, radius: 16),
                  child: Row(
                    children: [
                      Container(
                        width: context.rs(34),
                        height: context.rs(34),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 17, color: scheme.primary),
                      ),
                      SizedBox(width: context.rs(10)),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w700),
                        ),
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

/* ─────────────────────── Benefit login prompt ─────────────────────── */

final class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(24), context.rs(16), 0),
      child: Container(
        padding: EdgeInsets.all(context.rs(18)),
        decoration:
            softCardDecoration(context, tint: scheme.primary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.ghLoginBenefit,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.rf(13), height: 1.5, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: context.rs(14)),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(shape: const StadiumBorder()),
                    onPressed: () => context.go(Routes.signIn),
                    child: Text(t.authSignIn),
                  ),
                ),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: scheme.primary),
                      foregroundColor: scheme.primary,
                    ),
                    onPressed: () => context.go(Routes.signUp),
                    child: Text(t.authSignUp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
