import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../home/domain/home_models.dart';
import '../../../home/presentation/widgets/home_bits.dart';
import '../../../vehicles/domain/vehicle_models.dart' show EquipmentRow;
import '../../domain/online_specs.dart';

/// "تفاصيل السيارة" — the website OnlineDetail VehicleDetailsCard: key stats
/// (hp / cylinders / fuel / seats) + grade, model year and the selected
/// colour split into exterior / interior.
final class OnlineVehicleDetailsCard extends StatelessWidget {
  const OnlineVehicleDetailsCard({
    super.key,
    required this.detail,
    required this.vehicle,
    required this.color,
    required this.grade,
    required this.lang,
    this.interiorImage,
  });

  final SliderVehicle? detail;
  final OnlineVehicle vehicle;
  final CarColor? color;
  /// Interior trim swatch from the model palette (null → approximated dot).
  final String? interiorImage;
  final String? grade;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final d = detail;

    final stats = <(IconData, String, String)>[
      if (d?.hp != null) (Icons.speed_rounded, '${d!.hp!.round()}', t.specHp),
      if (d?.cylinders != null)
        (Icons.settings_rounded, '${d!.cylinders}', t.specCylinders),
      if ((d?.petrol ?? '').trim().isNotEmpty)
        (Icons.local_gas_station_rounded, d!.petrol!.trim(), t.specFuel),
      if (d?.seatsNumber != null)
        (Icons.people_alt_outlined, '${d!.seatsNumber}', t.specSeats),
    ];

    final (exterior, interior) = splitColorName(color?.name(lang) ?? '');
    final year = (d?.year ?? vehicle.year ?? '').trim();
    final rows = <(String, Widget)>[
      if ((grade ?? '').trim().isNotEmpty) (t.osGrade, _value(context, grade!.trim())),
      if (year.isNotEmpty) (t.osModelYear, _value(context, year)),
      if (exterior != null)
        (t.osExteriorColor, _colorValue(context, exterior, color?.image)),
      if (interior != null)
        (
          t.osInnerColor,
          _colorValue(context, interior, interiorImage,
              // No palette image → the website's name-based colour dot.
              hex: (interiorImage ?? '').isEmpty
                  ? interiorSwatchArgb(color?.nameEn)
                  : null),
        ),
    ];

    if (stats.isEmpty && rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.rs(16)),
      decoration: softCardDecoration(context, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.acCarDetails,
            style: TextStyle(
              fontSize: context.rf(10),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (stats.isNotEmpty) ...[
            SizedBox(height: context.rs(12)),
            Row(children: [
              for (final (i, s) in stats.indexed) ...[
                if (i > 0) SizedBox(width: context.rs(8)),
                Expanded(child: _StatTile(icon: s.$1, value: s.$2, label: s.$3)),
              ],
            ]),
          ],
          if (rows.isNotEmpty) ...[
            SizedBox(height: context.rs(6)),
            for (final (i, r) in rows.indexed)
              Container(
                padding: EdgeInsets.symmetric(vertical: context.rs(11)),
                decoration: BoxDecoration(
                  border: i == rows.length - 1
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.35))),
                ),
                child: Row(children: [
                  Text(r.$1,
                      style: TextStyle(
                          fontSize: context.rf(12),
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                  SizedBox(width: context.rs(14)),
                  Expanded(
                    child: Align(
                        alignment: AlignmentDirectional.centerEnd, child: r.$2),
                  ),
                ]),
              ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _value(BuildContext context, String v) => Text(
        v,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: context.rf(12.5), fontWeight: FontWeight.w700),
      );

  Widget _colorValue(BuildContext context, String name, String? image,
      {int? hex}) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = (image ?? '').isNotEmpty;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (hasImage || hex != null) ...[
        Container(
          width: context.rs(20),
          height: context.rs(20),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hex == null ? null : Color(hex),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          ),
          child: hasImage ? HomeImage(url: image, fit: BoxFit.cover) : null,
        ),
        SizedBox(width: context.rs(8)),
      ],
      Flexible(child: _value(context, name)),
    ]);
  }
}

final class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(6), vertical: context.rs(10)),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Container(
          width: context.rs(32),
          height: context.rs(32),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        SizedBox(height: context.rs(6)),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: context.rf(13.5), fontWeight: FontWeight.w800)),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: context.rf(9),
                color: scheme.onSurface.withValues(alpha: 0.5))),
      ]),
    );
  }
}

/// "مواصفات السيارة" — the website OnlineDetail SpecsSection: this trim's
/// equipment grouped into tabs (عام / الاضافات الخارجية / مزايا الراحة
/// والسلامة / …) with a count badge; "label: value" rows and ✓ feature rows.
final class OnlineSpecsSection extends StatefulWidget {
  const OnlineSpecsSection({
    super.key,
    required this.rows,
    required this.loading,
    required this.subtitle,
    required this.lang,
  });

  final List<EquipmentRow> rows;
  final bool loading;
  final String subtitle; // "LX · 2026 · Elite BB"
  final String lang;

  @override
  State<OnlineSpecsSection> createState() => _OnlineSpecsSectionState();
}

final class _OnlineSpecsSectionState extends State<OnlineSpecsSection> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (widget.loading) {
      return Padding(
        padding: EdgeInsets.only(top: context.rs(8)),
        child: SkeletonList(itemCount: 4, itemHeight: context.rs(44)),
      );
    }

    final sections = buildOnlineSpecSections(widget.rows, widget.lang);
    if (sections.isEmpty) return const SizedBox.shrink();
    final idx = _active.clamp(0, sections.length - 1);
    final sec = sections[idx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.tabSpecs,
          style: TextStyle(
            fontSize: context.rf(10.5),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: context.rs(4)),
        Text(
          t.osVehicleSpecs,
          style: TextStyle(
              fontSize: context.rf(21),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4),
        ),
        if (widget.subtitle.isNotEmpty) ...[
          SizedBox(height: context.rs(3)),
          Text(
            widget.subtitle,
            textDirection: TextDirection.ltr,
            style: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.55)),
          ),
        ],
        SizedBox(height: context.rs(14)),

        // Section tabs — one sliding row with count badges.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final (i, s) in sections.indexed)
              Padding(
                padding: EdgeInsetsDirectional.only(end: context.rs(8)),
                child: _SpecTab(
                  title: s.title,
                  count: s.lines.length,
                  selected: i == idx,
                  onTap: () => setState(() => _active = i),
                ),
              ),
          ]),
        ),
        SizedBox(height: context.rs(8)),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Column(
            key: ValueKey(idx),
            children: [
              for (final l in sec.lines) _SpecLineRow(line: l),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SpecTab extends StatelessWidget {
  const _SpecTab({
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.7);
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
            color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.rs(14), vertical: context.rs(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                style: TextStyle(
                    fontSize: context.rf(12),
                    fontWeight: FontWeight.w700,
                    color: fg)),
            SizedBox(width: context.rs(6)),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(6), vertical: context.rs(1)),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: context.rf(9.5),
                      fontWeight: FontWeight.w800,
                      color: selected ? scheme.onPrimary : scheme.primary)),
            ),
          ]),
        ),
      ),
    );
  }
}

final class _SpecLineRow extends StatelessWidget {
  const _SpecLineRow({required this.line});

  final OnlineSpecLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = Border(
        bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.35)));
    final value = line.value;

    if (value != null) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: context.rs(11)),
        decoration: BoxDecoration(border: border),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(line.label,
                style: TextStyle(
                    fontSize: context.rf(12),
                    color: scheme.onSurface.withValues(alpha: 0.6))),
          ),
          SizedBox(width: context.rs(14)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: context.rf(12), fontWeight: FontWeight.w700)),
          ),
        ]),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: context.rs(11)),
      decoration: BoxDecoration(border: border),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: context.rs(20),
          height: context.rs(20),
          margin: EdgeInsets.only(top: context.rs(1)),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 13, color: scheme.primary),
        ),
        SizedBox(width: context.rs(10)),
        Expanded(
          child: Text(line.label,
              style: TextStyle(fontSize: context.rf(12.5), height: 1.4)),
        ),
      ]),
    );
  }
}
