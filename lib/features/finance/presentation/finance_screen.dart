import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_header.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/finance_cubit.dart';
import '../data/finance_repository.dart';
import '../domain/finance_math.dart';
import '../domain/finance_models.dart';
import 'finance_lead_sheet.dart';

/// The finance page — the website's /finance for mobile: financier cards,
/// the three search modes (monthly sliders / by model / by budget), refine
/// facets and the bank-priced car list with a live monthly estimate.
final class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinanceCubit(FinanceRepository(sl<ApiClient>())),
      child: const _FinanceView(),
    );
  }
}

final class _FinanceView extends StatelessWidget {
  const _FinanceView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<FinanceCubit>().state;
    final cubit = context.read<FinanceCubit>();

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: switch (state.status) {
            FinanceStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            FinanceStatus.error => Center(
                child: TextButton(
                    onPressed: cubit.load, child: Text(t.homeErrorRetry))),
            FinanceStatus.ready => const _Body(),
          },
        ),
      ],
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<FinanceCubit>().state;
    final cubit = context.read<FinanceCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    final wantedDbId = brandKey == 'lexus' ? '2' : '1';
    final scheme = Theme.of(context).colorScheme;
    final bank = state.activeBank!;
    final cars = state.visible(wantedDbId);

    // Refine facets, derived like the website: categories present in the
    // lineup + group chips resolved to names.
    final brandCars = state.brandVehicles(wantedDbId);
    final cats = FinanceState.bodyCats
        .where((c) =>
            brandCars.any((v) => (v.category ?? '').toUpperCase() == c))
        .toList();
    final groupChips = <String, String>{}; // carGroupId → display name
    for (final v in brandCars) {
      if ((v.carGroupId ?? '').isEmpty) continue;
      groupChips.putIfAbsent(v.carGroupId!, () => v.group(lang));
    }
    final (minP, maxP) = state.priceBounds(wantedDbId);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(20), context.rs(18), context.rs(20), 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.finTitle,
                    style: TextStyle(
                        fontSize: context.rf(24),
                        fontWeight: FontWeight.w800)),
                SizedBox(height: context.rs(2)),
                Text(t.finSubtitle,
                    style: TextStyle(
                        fontSize: context.rf(12),
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ),

        // ── Financier cards ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: context.rs(14)),
            child: SizedBox(
              height: context.rs(92),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                scrollDirection: Axis.horizontal,
                itemCount: state.banks.length,
                separatorBuilder: (_, _) => SizedBox(width: context.rs(10)),
                itemBuilder: (context, i) {
                  final b = state.banks[i];
                  final selected = i == state.activeBankIndex;
                  return GestureDetector(
                    onTap: () => cubit.selectBank(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: context.rs(108),
                      padding: EdgeInsets.all(context.rs(8)),
                      decoration:
                          softCardDecoration(context, radius: 16).copyWith(
                        border: selected
                            ? Border.all(
                                color: scheme.primary, width: 1.6)
                            : (Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Border.all(
                                    color: scheme.outline
                                        .withValues(alpha: 0.5))
                                : null),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Center(
                                  child: HomeImage(
                                      url: b.logo,
                                      fit: BoxFit.contain,
                                      logicalWidth: 100),
                                ),
                                if (selected)
                                  PositionedDirectional(
                                    top: 0,
                                    end: 0,
                                    child: Icon(Icons.check_circle_rounded,
                                        size: 16, color: scheme.primary),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: context.rs(4)),
                          Text(
                            b.name(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.rf(9.5),
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Mode tabs + controls ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(16), context.rs(16), context.rs(16), 0),
            child: Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: softCardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    for (final (mode, label) in [
                      (FinanceMode.monthly, t.finModeMonthly),
                      (FinanceMode.model, t.finModeModel),
                      (FinanceMode.budget, t.finModeBudget),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => cubit.setMode(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.symmetric(
                                horizontal: context.rs(3)),
                            padding: EdgeInsets.symmetric(
                                vertical: context.rs(9)),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: state.mode == mode
                                  ? scheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: state.mode == mode
                                    ? scheme.primary
                                    : scheme.outline.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: context.rf(11),
                                fontWeight: FontWeight.w800,
                                color: state.mode == mode
                                    ? scheme.onPrimary
                                    : scheme.onSurface
                                        .withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                  SizedBox(height: context.rs(14)),
                  switch (state.mode) {
                    FinanceMode.monthly => _MonthlySliders(bank: bank),
                    FinanceMode.model => _ModelPicker(
                        wantedDbId: wantedDbId, lang: lang),
                    FinanceMode.budget => TextField(
                        controller: cubit.budgetCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: cubit.setBudget,
                        decoration: InputDecoration(
                          labelText: t.finMaxPrice,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                  },
                ],
              ),
            ),
          ),
        ),

        // ── Refine ──
        if (cats.isNotEmpty || groupChips.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(18), context.rs(20), 0),
              child: Text(t.finRefine,
                  style: TextStyle(
                      fontSize: context.rf(14), fontWeight: FontWeight.w800)),
            ),
          ),
        if (cats.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: context.rs(10)),
              child: FilterChipsRow(
                labels: [t.homeAll, ...cats],
                selectedIndex: state.refineCategory == null
                    ? 0
                    : cats.indexOf(state.refineCategory!) + 1,
                onSelected: (i) =>
                    cubit.refineByCategory(i == 0 ? null : cats[i - 1]),
              ),
            ),
          ),
        if (groupChips.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: context.rs(8)),
              child: SizedBox(
                height: context.rs(36),
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final e in groupChips.entries)
                      Padding(
                        padding:
                            EdgeInsetsDirectional.only(end: context.rs(8)),
                        child: FilterChip(
                          label: Text(e.value,
                              style: TextStyle(fontSize: context.rf(11))),
                          selected: state.refineGroupIds.contains(e.key),
                          onSelected: (_) => cubit.toggleRefineGroup(e.key),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (maxP > minP)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(16), context.rs(6), context.rs(16), 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: context.rs(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PriceText(
                            price: (state.priceRange?.start ?? minP),
                            currency: '',
                            contactForPrice: '',
                            fontSize: context.rf(11)),
                        PriceText(
                            price: (state.priceRange?.end ?? maxP),
                            currency: '',
                            contactForPrice: '',
                            fontSize: context.rf(11)),
                      ],
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: RangeSlider(
                      values: RangeValues(
                        (state.priceRange?.start ?? minP)
                            .clamp(minP, maxP),
                        (state.priceRange?.end ?? maxP).clamp(minP, maxP),
                      ),
                      min: minP,
                      max: maxP,
                      onChanged: cubit.setPriceRange,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Cars ──
        if (state.vehiclesLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (cars.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(context.rs(40)),
              child: Center(child: Text(t.finNoCars)),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                context.rs(16), context.rs(16), context.rs(16), 0),
            sliver: SliverList.separated(
              itemCount: cars.length,
              separatorBuilder: (_, _) => SizedBox(height: context.rs(12)),
              itemBuilder: (context, i) => _CarCard(
                car: cars[i],
                bank: bank,
                period: state.period,
                lang: lang,
              ).animate(delay: (30 * (i % 5)).ms).fadeIn(duration: 220.ms),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: context.rs(140))),
      ],
    );
  }
}

final class _MonthlySliders extends StatelessWidget {
  const _MonthlySliders({required this.bank});

  final FinanceBank bank;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<FinanceCubit>().state;
    final cubit = context.read<FinanceCubit>();
    final maxPeriod = bank.maxFinancePeriod < 24 ? 60 : bank.maxFinancePeriod;

    Widget slider({
      required String label,
      required String value,
      required Widget child,
    }) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: context.rf(11),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6))),
                Text(value,
                    style: TextStyle(
                        fontSize: context.rf(13),
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            Directionality(textDirection: TextDirection.ltr, child: child),
          ],
        );

    return Column(
      children: [
        // Website ranges: 500–10000 step 50 / 24–max step 12 / 0–250000 step 5000.
        slider(
          label: t.finMonthlyPayment,
          value: '${formatPrice(state.monthly)} ${t.finSar}',
          child: Slider(
            value: state.monthly.clamp(500, 10000),
            min: 500,
            max: 10000,
            divisions: (10000 - 500) ~/ 50,
            onChanged: cubit.setMonthly,
          ),
        ),
        slider(
          label: t.finPeriodMonths,
          value: '${state.period} ${t.finMo}',
          child: Slider(
            value: state.period.toDouble().clamp(24, maxPeriod.toDouble()),
            min: 24,
            max: maxPeriod.toDouble(),
            divisions: ((maxPeriod - 24) ~/ 12).clamp(1, 100),
            onChanged: (v) => cubit.setPeriod(v.round()),
          ),
        ),
        slider(
          label: t.finFinalPayment,
          value: '${formatPrice(state.lastBatch)} ${t.finSar}',
          child: Slider(
            value: state.lastBatch.clamp(0, 250000),
            min: 0,
            max: 250000,
            divisions: 250000 ~/ 5000,
            onChanged: cubit.setLastBatch,
          ),
        ),
      ],
    );
  }
}

final class _ModelPicker extends StatelessWidget {
  const _ModelPicker({required this.wantedDbId, required this.lang});

  final String wantedDbId;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<FinanceCubit>().state;
    final cubit = context.read<FinanceCubit>();

    // Groups actually present in the current bank lineup for this brand.
    final groups = <String, String>{};
    for (final v in state.brandVehicles(wantedDbId)) {
      if ((v.carGroupId ?? '').isEmpty) continue;
      groups.putIfAbsent(v.carGroupId!, () => v.group(lang));
    }

    return AppDropdown<String>(
      label: t.homeSelectCar,
      value: state.modelGroupId ?? '',
      items: [
        AppDropdownItem(value: '', label: t.homeAll),
        for (final e in groups.entries)
          AppDropdownItem(value: e.key, label: e.value),
      ],
      onChanged: (v) => cubit.selectModelGroup(v.isEmpty ? null : v),
    );
  }
}

/// Car row: image, name, cash price and the live monthly estimate for the
/// active bank; "Finance" opens the request sheet (registered users only —
/// the gate lives inside showFinanceLeadSheet).
final class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.car,
    required this.bank,
    required this.period,
    required this.lang,
  });

  final FinanceVehicle car;
  final FinanceBank bank;
  final int period;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final price = car.minPrice ?? 0;
    final est = price > 0
        ? computeFinance(
            price, bank, period.clamp(1, bank.maxFinancePeriod))
        : null;
    final custGroups =
        context.read<FinanceCubit>().state.filters.custGroups;

    return HomeCard(
      child: Padding(
        padding: EdgeInsets.all(context.rs(12)),
        child: Row(
          children: [
            SizedBox(
              width: context.rs(110),
              height: context.rs(74),
              child: HomeImage(
                  url: car.image, fit: BoxFit.contain, logicalWidth: 110),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.group(lang)} ${car.year ?? ''}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(13.5),
                        fontWeight: FontWeight.w800),
                  ),
                  if (car.description(lang).isNotEmpty)
                    Text(
                      car.description(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(10.5),
                          color: scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  SizedBox(height: context.rs(6)),
                  PriceText(
                      price: price > 0 ? price : null,
                      currency: '',
                      contactForPrice: t.homeContactForPrice,
                      fontSize: context.rf(14)),
                  if (est != null)
                    Text(
                      t.finFromMonthly(formatPrice(est.monthly.roundToDouble())),
                      style: TextStyle(
                          fontSize: context.rf(10.5),
                          fontWeight: FontWeight.w700,
                          color: scheme.primary),
                    ),
                ],
              ),
            ),
            SizedBox(width: context.rs(8)),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: EdgeInsets.symmetric(
                    horizontal: context.rs(14), vertical: context.rs(9)),
                minimumSize: Size.zero,
                textStyle: TextStyle(
                    fontSize: context.rf(11), fontWeight: FontWeight.w800),
              ),
              onPressed: () => showFinanceLeadSheet(
                context,
                bank: bank,
                car: car,
                custGroups: custGroups,
                initialPeriod: period,
              ),
              child: Text(t.finApply),
            ),
          ],
        ),
      ),
    );
  }
}
