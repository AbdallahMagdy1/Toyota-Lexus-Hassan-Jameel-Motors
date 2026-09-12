import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/api_paths.dart';
import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/sheet_routes.dart';

/// One day of the maintenance availability month grid
/// (GET /api/app/maintenance/available-days — the website's
/// GetAvailableDaysInMonth cycle): type 1 = bookable, 0 = holiday,
/// otherwise unavailable; hoursCount = bookable slots that day.
final class AvailabilityDay {
  const AvailabilityDay({
    required this.date,
    required this.type,
    required this.hoursCount,
  });

  final DateTime date;
  final int type;
  final int hoursCount;
}

/// Opens the SHARED maintenance availability calendar — the same
/// month-grid sheet the maintenance booking uses (month navigation,
/// weekday headers, per-day capacity badges, holiday/unavailable states,
/// legend) — and resolves with the picked date (null on dismiss).
///
/// [minDate]: earliest selectable day (inclusive). Defaults to today;
/// the maintenance-OFFER reservation passes tomorrow to block same-day
/// booking regardless of availability.
Future<DateTime?> showAvailabilityCalendarSheet(
  BuildContext context, {
  DateTime? initialMonth,
  DateTime? selected,
  DateTime? minDate,
}) {
  return showAppModalSheet<DateTime>(
    context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _AvailabilityCalendarSheet(
      initialMonth: initialMonth,
      selected: selected,
      minDate: minDate,
    ),
  );
}

final class _AvailabilityCalendarSheet extends StatefulWidget {
  const _AvailabilityCalendarSheet({
    this.initialMonth,
    this.selected,
    this.minDate,
  });

  final DateTime? initialMonth;
  final DateTime? selected;
  final DateTime? minDate;

  @override
  State<_AvailabilityCalendarSheet> createState() =>
      _AvailabilityCalendarSheetState();
}

final class _AvailabilityCalendarSheetState
    extends State<_AvailabilityCalendarSheet> {
  late DateTime _month =
      widget.initialMonth ?? widget.selected ?? DateTime.now();
  List<AvailabilityDay> _days = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(_month);
  }

  Future<void> _load(DateTime month) async {
    setState(() {
      _month = DateTime(month.year, month.month, 1);
      _loading = true;
    });
    try {
      final res = await sl<ApiClient>().get<List<dynamic>>(
        ApiPaths.maintDays,
        query: {'month': month.month},
      );
      if (!mounted) return;
      setState(() {
        _days = (res.data ?? [])
            .whereType<Map<String, dynamic>>()
            .map((j) {
              final d = DateTime.tryParse('${j['date']}');
              return d == null
                  ? null
                  : AvailabilityDay(
                      date: d,
                      type: (j['type'] as num?)?.toInt() ?? -1,
                      hoursCount:
                          (j['availableHoursCount'] as num?)?.toInt() ?? 0,
                    );
            })
            .whereType<AvailabilityDay>()
            .toList();
        _loading = false;
      });
    } on DioException {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final month = _month;
    final now = DateTime.now();
    // Earliest selectable day (inclusive) — defaults to today.
    final min = widget.minDate ?? DateTime(now.year, now.month, now.day);
    final minDay = DateTime(min.year, min.month, min.day);
    final byDay = {
      for (final d in _days) '${d.date.year}-${d.date.month}-${d.date.day}': d
    };
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Week starts Sunday (الأحد), like the website grid.
    final leading = first.weekday % 7;

    // Scrollable body — a 6-row month on a small screen must never
    // RenderFlex-overflow the sheet.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(
              onPressed: () =>
                  _load(DateTime(month.year, month.month - 1, 1)),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '${month.year}/${month.month.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: context.rf(15),
                    fontWeight: FontWeight.w800,
                    color: scheme.primary),
              ),
            ),
            IconButton(
              onPressed: () =>
                  _load(DateTime(month.year, month.month + 1, 1)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            )
          else ...[
            Row(children: [
              for (final d in [
                t.calSun, t.calMon, t.calTue, t.calWed,
                t.calThu, t.calFri, t.calSat
              ])
                Expanded(
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: context.rf(9.5),
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.5))),
                ),
            ]),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              children: [
                for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                for (var day = 1; day <= daysInMonth; day++)
                  Builder(builder: (context) {
                    final date = DateTime(month.year, month.month, day);
                    final info = byDay['${month.year}-${month.month}-$day'];
                    final tooEarly = date.isBefore(minDay);
                    final clickable = (info?.type ?? -1) == 1 && !tooEarly;
                    final selected = widget.selected != null &&
                        widget.selected!.year == date.year &&
                        widget.selected!.month == date.month &&
                        widget.selected!.day == date.day;
                    final holiday = info?.type == 0;

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: clickable
                          ? () => Navigator.of(context).pop(date)
                          : null,
                      child: Stack(children: [
                        Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: selected
                                ? scheme.primary
                                : clickable
                                    ? scheme.primary.withValues(alpha: 0.1)
                                    : scheme.onSurface
                                        .withValues(alpha: 0.04),
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? scheme.onPrimary
                                  : clickable
                                      ? scheme.primary
                                      : scheme.onSurface
                                          .withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        if (holiday)
                          const PositionedDirectional(
                            top: 2,
                            end: 3,
                            child: Icon(Icons.wb_sunny_outlined, size: 9),
                          )
                        else if (clickable && (info?.hoursCount ?? 0) > 0)
                          PositionedDirectional(
                            top: 2,
                            start: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${info!.hoursCount}',
                                style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimary),
                              ),
                            ),
                          ),
                      ]),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (color, label) in [
                  (scheme.primary, t.calAvailable),
                  (scheme.onSurface.withValues(alpha: 0.3), t.calHoliday),
                  (scheme.onSurface.withValues(alpha: 0.15), t.calUnavailable),
                ]) ...[
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(fontSize: context.rf(9.5))),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
