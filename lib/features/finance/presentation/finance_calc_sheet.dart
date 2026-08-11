import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../online_store/data/online_store_repository.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/finance_calc_cubit.dart';
import '../data/finance_repository.dart';
import '../domain/finance_models.dart';
import 'finance_lead_sheet.dart';

/// "احسب التمويل" — the website home-hero Finance tab as a bottom sheet:
/// two dropdowns (car → model), the price, then the per-bank benefit report.
void showFinanceCalcSheet(BuildContext context) {
  showHeroBottomSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => FinanceCalcCubit(
        sl<OnlineStoreRepository>(),
        FinanceRepository(sl<ApiClient>()),
      ),
      child: const _CalcView(),
    ),
  );
}

final class _CalcView extends StatelessWidget {
  const _CalcView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<FinanceCalcCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: switch (state.status) {
          FinanceCalcStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          FinanceCalcStatus.error => Center(child: Text(t.homeErrorRetry)),
          FinanceCalcStatus.ready => const _CalcBody(),
        },
      ),
    );
  }
}

final class _CalcBody extends StatelessWidget {
  const _CalcBody();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<FinanceCalcCubit>();
    final state = context.watch<FinanceCalcCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    final wantedDbId = brandKey == 'lexus' ? '2' : '1';
    final scheme = Theme.of(context).colorScheme;

    final groups = state.groupsFor(wantedDbId);
    final trims = state.trimsFor(wantedDbId);
    final selected = state.selected(wantedDbId);
    final report = state.showReport ? state.report(wantedDbId) : const <BankEstimate>[];
    final best = report.firstOrNull;

    String groupLabel(OnlineVehicle v) =>
        '${(lang == 'ar' ? v.brandAr : v.brandEn) ?? v.brandEn ?? ''} '
        '${(lang == 'ar' ? v.groupAr : v.groupEn) ?? v.groupEn ?? ''} '
        '${v.year ?? ''}';
    String trimLabel(OnlineVehicle v) =>
        ((lang == 'ar' ? v.shortDescriptionAr : v.shortDescriptionEn) ??
                v.shortDescriptionEn ??
                v.shortDescriptionAr ??
                '')
            .trim();

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(10), context.rs(20), context.rs(28)),
      children: [
        const Center(child: SheetHandle()),
        SizedBox(height: context.rs(14)),
        Text(t.ghCalcFinance,
            style: TextStyle(
                fontSize: context.rf(20), fontWeight: FontWeight.w800)),
        SizedBox(height: context.rs(4)),
        Text(t.finCalcSub,
            style: TextStyle(
                fontSize: context.rf(12),
                color: scheme.onSurface.withValues(alpha: 0.55))),
        SizedBox(height: context.rs(18)),

        // ── Car / Model dropdowns (hero FinanceBar) ──
        AppDropdown<String>(
          label: t.homeSelectCar,
          value: state.groupKey,
          items: [
            for (final g in groups)
              AppDropdownItem(
                value: FinanceCalcState.keyOf(g),
                label: groupLabel(g),
              ),
          ],
          onChanged: cubit.selectGroup,
        ),
        SizedBox(height: context.rs(12)),
        AppDropdown<int>(
          label: t.homeSelectModel,
          value: trims.isEmpty ? null : (state.trimIndex ?? 0),
          items: [
            for (var i = 0; i < trims.length; i++)
              AppDropdownItem(
                value: i,
                label: trimLabel(trims[i]).isEmpty
                    ? trims[i].year ?? ''
                    : trimLabel(trims[i]),
              ),
          ],
          onChanged: cubit.selectTrim,
        ),
        SizedBox(height: context.rs(14)),

        if (selected != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.finCashPrice,
                  style: TextStyle(
                      fontSize: context.rf(12.5),
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.65))),
              PriceText(
                  price: selected.minPrice,
                  currency: '',
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(17)),
            ],
          ),
        SizedBox(height: context.rs(14)),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
                fontSize: context.rf(14), fontWeight: FontWeight.w800),
          ),
          onPressed: selected == null || (selected.minPrice ?? 0) <= 0
              ? null
              : cubit.calculate,
          icon: const Icon(Icons.calculate_outlined),
          label: Text(t.finCalculate),
        ),

        // ── Benefit report ──
        if (state.showReport && report.isNotEmpty) ...[
          SizedBox(height: context.rs(22)),
          Text(t.finBestOffer,
              style: TextStyle(
                  fontSize: context.rf(15), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(10)),

          // Tenure chips + down-payment % slider (0–50 step 5).
          Wrap(
            spacing: 8,
            children: [
              for (final p in [12, 24, 36, 48, 60])
                ChoiceChip(
                  label: Text('$p ${t.finMo}'),
                  selected: state.period == p,
                  onSelected: (_) => cubit.selectPeriod(p),
                ),
            ],
          ),
          SizedBox(height: context.rs(6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.finDownPct,
                  style: TextStyle(
                      fontSize: context.rf(11.5),
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.6))),
              Text(
                state.downPct == null
                    ? t.finBankDefault
                    : '${state.downPct!.round()}%',
                style: TextStyle(
                    fontSize: context.rf(12.5),
                    fontWeight: FontWeight.w800,
                    color: scheme.primary),
              ),
            ],
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Slider(
              value: state.downPct ?? 0,
              min: 0,
              max: 50,
              divisions: 10,
              onChanged: (v) => cubit.setDownPct(v == 0 ? null : v),
            ),
          ),
          SizedBox(height: context.rs(6)),

          // Best deal highlight.
          if (best != null)
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: context.rs(46),
                    height: context.rs(46),
                    child: HomeImage(
                        url: best.bank.logo,
                        fit: BoxFit.contain,
                        logicalWidth: 46),
                  ),
                  SizedBox(width: context.rs(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(best.bank.name(lang),
                            style: TextStyle(
                                fontSize: context.rf(13),
                                fontWeight: FontWeight.w800)),
                        Text(
                          '${best.bank.financeRate.toStringAsFixed(2)}%',
                          style: TextStyle(
                              fontSize: context.rf(11),
                              color:
                                  scheme.onSurface.withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PriceText(
                          price: best.estimate.monthly.roundToDouble(),
                          currency: '',
                          contactForPrice: '',
                          fontSize: context.rf(18)),
                      Text(t.finPerMonth,
                          style: TextStyle(
                              fontSize: context.rf(10),
                              color:
                                  scheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
            ),
          SizedBox(height: context.rs(12)),

          // Per-bank rows.
          for (final row in report.skip(1))
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(8)),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.rs(12), vertical: context.rs(10)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: context.rs(34),
                      height: context.rs(34),
                      child: HomeImage(
                          url: row.bank.logo,
                          fit: BoxFit.contain,
                          logicalWidth: 34),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                      child: Text(row.bank.name(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(11.5),
                              fontWeight: FontWeight.w700)),
                    ),
                    PriceText(
                        price: row.estimate.monthly.roundToDouble(),
                        currency: '',
                        contactForPrice: '',
                        fontSize: context.rf(13)),
                  ],
                ),
              ),
            ),

          // Best-deal breakdown (cash / down / balloon / fees / total).
          if (best != null && selected != null) ...[
            SizedBox(height: context.rs(10)),
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  for (final (label, value) in [
                    (t.finCashPrice, selected.minPrice ?? 0),
                    (t.finEstAdvance, best.estimate.firstPay),
                    (t.finEstFees, best.estimate.managementFees),
                    (t.finEstBalloon, best.estimate.lastPay),
                    (t.finEstTotal, best.estimate.total),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: context.rs(5)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: context.rf(11.5),
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.65))),
                          PriceText(
                              price: value.roundToDouble(),
                              currency: '',
                              contactForPrice: '',
                              fontSize: context.rf(12.5),
                              color: scheme.onSurface),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: context.rs(16)),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: const StadiumBorder(),
                textStyle: TextStyle(
                    fontSize: context.rf(14), fontWeight: FontWeight.w800),
              ),
              onPressed: () => showFinanceLeadSheet(
                context,
                bank: best.bank,
                car: FinanceVehicle(
                  productId: selected.productId,
                  year: selected.year,
                  brandId: selected.brandId,
                  groupAr: selected.groupAr,
                  groupEn: selected.groupEn,
                  carGroupId: selected.carGroupId,
                  type: selected.type,
                  minPrice: selected.minPrice,
                  image: selected.image,
                ),
                custGroups: state.custGroups,
                initialPeriod: state.period,
              ),
              child: Text(t.finApply),
            ),
          ],
        ],
      ],
    );
  }
}
