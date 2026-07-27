import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../guest_home/presentation/guest_home_view.dart' show showLoginPrompt;
import '../../home/presentation/widgets/home_bits.dart';
import '../../online_store/data/online_store_repository.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/finance_lead_cubit.dart';
import '../domain/finance_models.dart';

/// Opens the finance application (website FinanceRequestModal). Applying is a
/// registered-only action in the app: guests get the benefit prompt.
void showFinanceLeadSheet(
  BuildContext context, {
  required FinanceBank bank,
  required FinanceVehicle car,
  required List<FinanceCustGroup> custGroups,
  int? initialPeriod,
}) {
  final auth = sl<AuthBloc>().state;
  if (auth.status != AuthStatus.authenticated) {
    showLoginPrompt(context);
    return;
  }
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
      create: (_) => FinanceLeadCubit(
        bank: bank,
        car: car,
        onlineRepo: sl<OnlineStoreRepository>(),
        user: auth.user,
        lang: lang,
        custGroups: custGroups,
        initialPeriod: initialPeriod,
      ),
      child: const _LeadView(),
    ),
  );
}

final class _LeadView extends StatelessWidget {
  const _LeadView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<FinanceLeadCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    if (state.phase == FinanceLeadPhase.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 52, color: scheme.primary),
            const SizedBox(height: 14),
            Text(t.successFinance,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w600)),
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

    final est = cubit.estimate;
    final periods = [24, 36, 48, 60]
        .where((p) => p <= cubit.bank.maxFinancePeriod)
        .toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: 12),
            Row(
              children: [
                if ((cubit.bank.logo ?? '').isNotEmpty)
                  SizedBox(
                    width: context.rs(40),
                    height: context.rs(40),
                    child: HomeImage(
                        url: cubit.bank.logo,
                        fit: BoxFit.contain,
                        logicalWidth: 40),
                  ),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.finApply,
                          style: TextStyle(
                              fontSize: context.rf(17),
                              fontWeight: FontWeight.w800)),
                      Text(
                        '${cubit.car.group(lang)} ${cubit.car.year ?? ''} — ${cubit.bank.name(lang)}',
                        style: TextStyle(
                            fontSize: context.rf(11),
                            color: scheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Live estimate (computeFinance) ──
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.finEstMonthly,
                          style: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w700)),
                      PriceText(
                          price: est.monthly.roundToDouble(),
                          currency: '',
                          contactForPrice: '',
                          fontSize: context.rf(18)),
                    ],
                  ),
                  SizedBox(height: context.rs(10)),
                  for (final (label, value) in [
                    (t.finEstAdvance, est.firstPay),
                    (t.finEstBalloon, est.lastPay),
                    (t.finEstTotal, est.total),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: context.rs(4)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: context.rf(11),
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6))),
                          PriceText(
                              price: value.roundToDouble(),
                              currency: '',
                              contactForPrice: '',
                              fontSize: context.rf(12),
                              color: scheme.onSurface),
                        ],
                      ),
                    ),
                  SizedBox(height: context.rs(6)),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final p in periods)
                          ChoiceChip(
                            label: Text('$p ${t.finMo}'),
                            selected: state.period == p,
                            onSelected: (_) => cubit.selectPeriod(p),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (cubit.custGroups.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: state.custGroupId,
              isExpanded: true,
              items: [
                for (final g in cubit.custGroups)
                  DropdownMenuItem(value: g.id, child: Text(g.name(lang))),
              ],
              onChanged: cubit.selectCustGroup,
              decoration: InputDecoration(
                labelText: t.finBuyingAs,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
            ),
            const SizedBox(height: 12),
            _Field(controller: cubit.name, label: t.formFullName),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.phone,
                label: t.formPhone,
                keyboard: TextInputType.phone,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.identity,
                label: state.needIdentity ? t.formIdentity : t.finCommercialReg,
                keyboard: TextInputType.number,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.income,
                label: t.offersIncome,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.email,
                label: t.formEmailOptional,
                keyboard: TextInputType.emailAddress,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.advanceCtrl,
                label: t.finAdvanceOptional,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _Field(controller: cubit.note, label: t.formNoteOptional, maxLines: 2),
            const SizedBox(height: 18),
            if (state.phase == FinanceLeadPhase.failed || state.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  state.error ? t.formCheckFields : t.offersSubmitFailed,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.error, fontSize: context.rf(12)),
                ),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(
                      fontSize: context.rf(14), fontWeight: FontWeight.w800)),
              onPressed: state.phase == FinanceLeadPhase.busy
                  ? null
                  : () => context.read<FinanceLeadCubit>().submit(),
              child: state.phase == FinanceLeadPhase.busy
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
