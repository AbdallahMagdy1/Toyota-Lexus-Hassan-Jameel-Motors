import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/home_bits.dart';
import '../../../settings/bloc/locale_cubit.dart';
import '../../domain/online_store_models.dart';

/// The website's "Pick a bank" cards: logo + name + months, MONTHLY
/// (highlighted) / DOWN / ADMIN FEES / TOTAL — all figures API-precomputed.
final class BankCardList extends StatelessWidget {
  const BankCardList({
    super.key,
    required this.banks,
    required this.selectedBankId,
    required this.onSelect,
    this.compact = false,
  });

  final List<BankOffer> banks;
  final String? selectedBankId;
  final ValueChanged<String?> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final b in banks)
          Padding(
            padding: EdgeInsets.only(bottom: context.rs(10)),
            child: _BankCard(
              bank: b,
              selected: b.bankId == selectedBankId,
              onTap: () => onSelect(b.bankId),
              compact: compact,
            ),
          ),
      ],
    );
  }
}

final class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.bank,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final BankOffer bank;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: selected ? 1.0 : 0.985,
      duration: const Duration(milliseconds: 160),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(context.rs(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.6),
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: context.rs(34),
                        height: context.rs(34),
                        child: HomeImage(
                            url: bank.logo, fit: BoxFit.contain, logicalWidth: 40),
                      ),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bank.name(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.rf(13.5),
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            t.bankMonths(bank.financePeriodMonths),
                            style: TextStyle(
                              fontSize: context.rf(10),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: context.rs(22),
                      height: context.rs(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? scheme.primary : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.8),
                        ),
                      ),
                      child: selected
                          ? Icon(Icons.check_rounded,
                              size: 15, color: scheme.onPrimary)
                          : null,
                    ),
                  ],
                ),
                if (!compact) ...[
                  SizedBox(height: context.rs(10)),
                  Row(
                    children: [
                      _Cell(
                        label: t.bankMonthly,
                        value: bank.monthlyInstallment,
                        currency: t.currency,
                        highlight: true,
                      ),
                      _Cell(
                        label: t.bankDown,
                        value: bank.downPayment,
                        currency: t.currency,
                      ),
                      _Cell(
                        label: t.bankAdminFees,
                        value: bank.adminFees,
                        currency: t.currency,
                      ),
                      _Cell(
                        label: t.bankTotal,
                        value: bank.totalCost,
                        currency: t.currency,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    required this.currency,
    this.highlight = false,
  });

  final String label;
  final double? value;
  final String currency;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = value == null || value == 0
        ? '—'
        : value!.toStringAsFixed(value! % 1 == 0 ? 0 : 2).replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return Expanded(
      child: Container(
        margin: EdgeInsetsDirectional.only(end: context.rs(6)),
        padding: EdgeInsets.symmetric(
            vertical: context.rs(7), horizontal: context.rs(6)),
        decoration: BoxDecoration(
          color: highlight
              ? scheme.primary.withValues(alpha: 0.1)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rf(8),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: context.rs(2)),
            text == '—'
                ? Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: context.rf(11.5),
                      fontWeight: FontWeight.w800,
                      color: highlight ? scheme.primary : scheme.onSurface,
                    ),
                  )
                : Text.rich(
                    TextSpan(children: [
                      riyalSpan(
                        fontSize: context.rf(11.5),
                        color: highlight ? scheme.primary : scheme.onSurface,
                      ),
                      TextSpan(text: text),
                    ]),
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: context.rf(11.5),
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: highlight ? scheme.primary : scheme.onSurface,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
