import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/home_models.dart';
import '../../../home/presentation/widgets/home_bits.dart';

/// The website's "Order details" panel (OrderSummary.tsx) as a compact
/// COLLAPSIBLE card for the mobile form pages: car name + cash price
/// ("Including VAT"), exterior + inner colour lines at 0, total, down
/// payment, amount required — plus the "How you pay" platforms strip for
/// the quick-reservation flow. Flat, hairline border, no shadows.
final class OrderSummaryCard extends StatefulWidget {
  const OrderSummaryCard({
    super.key,
    required this.vehicle,
    required this.downPayment,
    this.color,
    this.showPlatforms = false,
    this.initiallyExpanded = false,
  });

  final OnlineVehicle vehicle;
  final double downPayment;
  final CarColor? color;
  final bool showPlatforms;
  final bool initiallyExpanded;

  @override
  State<OrderSummaryCard> createState() => _OrderSummaryCardState();
}

final class _OrderSummaryCardState extends State<OrderSummaryCard> {
  late bool _open = widget.initiallyExpanded;

  /// Website splitColorName: "Purplish Silver / Black" → exterior + interior.
  (String?, String?) _splitColor(String name) {
    final parts = name
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (null, null);
    if (parts.length == 1) return (parts.first, null);
    return (parts[0], parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final v = widget.vehicle;

    final cash = v.minPrice ?? 0;
    final (exterior, interior) = _splitColor(widget.color?.name(lang) ?? '');
    final title = '${v.name(lang)} ${v.year ?? ''}'.trim();

    Widget priceOf(double value, {Color? color, double? size, bool bold = false}) =>
        Text.rich(
          TextSpan(children: [
            riyalSpan(fontSize: size ?? context.rf(12.5), color: color),
            TextSpan(text: formatPrice(value)),
          ]),
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: size ?? context.rf(12.5),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: color,
          ),
        );

    Widget row(String label, double value,
        {String? hint, bool bold = false, bool subtle = false, bool accent = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: context.rs(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.rf(subtle ? 11 : 12),
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: subtle
                          ? scheme.onSurface.withValues(alpha: 0.55)
                          : scheme.onSurface,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: context.rf(9.5),
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            priceOf(value,
                color: accent
                    ? scheme.primary
                    : subtle
                        ? scheme.onSurface.withValues(alpha: 0.6)
                        : scheme.onSurface,
                size: context.rf(bold || accent ? 13.5 : 12),
                bold: bold || accent),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(top: context.rs(4), bottom: context.rs(6)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          // Collapsed header: title + amount required + chevron.
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(14), vertical: context.rs(12)),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 18, color: scheme.primary),
                  SizedBox(width: context.rs(8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.osOrderDetails,
                            style: TextStyle(
                                fontSize: context.rf(12.5),
                                fontWeight: FontWeight.w800)),
                        Text(
                          '${t.osAmountRequired}: ${formatPrice(widget.downPayment)}',
                          style: TextStyle(
                            fontSize: context.rf(10),
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.fromLTRB(context.rs(14), 0,
                        context.rs(14), context.rs(12)),
                    child: Column(
                      children: [
                        Divider(
                            height: 1,
                            color: scheme.outline.withValues(alpha: 0.5)),
                        SizedBox(height: context.rs(10)),
                        row(title, cash, hint: t.osInclVat, accent: true),
                        if (exterior != null)
                          row('${t.osExteriorColor} : $exterior', 0,
                              subtle: true),
                        if (interior != null)
                          row('${t.osInnerColor} : $interior', 0, subtle: true),
                        Divider(
                            height: 1,
                            color: scheme.outline.withValues(alpha: 0.5)),
                        SizedBox(height: context.rs(8)),
                        row(t.osTotal, cash, bold: true),
                        row(t.sheetDownPayment, widget.downPayment,
                            subtle: true),
                        row(t.osAmountRequired, widget.downPayment, bold: true),
                        if (widget.showPlatforms) _HowYouPay(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "How you pay" strip — VISA / MADA / SADAD chips + the website's hint that
/// the down payment goes by card and the remaining amount via SADAD.
final class _HowYouPay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: context.rs(4)),
      padding: EdgeInsets.all(context.rs(11)),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.osHowYouPay,
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  fontWeight: FontWeight.w800,
                  color: scheme.primary)),
          SizedBox(height: context.rs(6)),
          Wrap(
            spacing: context.rs(6),
            runSpacing: context.rs(6),
            children: [
              for (final p in const ['VISA', 'MADA', 'SADAD'])
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.rs(9), vertical: context.rs(4)),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: scheme.outline.withValues(alpha: 0.6)),
                  ),
                  child: Text(p,
                      style: TextStyle(
                          fontSize: context.rf(9.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ),
            ],
          ),
          SizedBox(height: context.rs(6)),
          Text(
            t.osPayHint,
            style: TextStyle(
              fontSize: context.rf(10),
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
