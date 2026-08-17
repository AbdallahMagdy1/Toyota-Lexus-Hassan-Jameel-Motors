import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/availability_calendar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../protection/data/protection_repository.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';

/// "تعديل الموعد" — reschedules an upcoming maintenance booking with the
/// website profile tab's exact cycle: pick a day (shared availability
/// calendar) + an hour slot, then PUT /api/app/maintenance/bookings →
/// App_ServiceRequestUpdate (ownership + status='Created' enforced in SQL,
/// operations notified). Resolves with true when the booking was moved.
Future<bool?> showRescheduleBookingSheet(
    BuildContext context, UpcomingBooking booking) {
  return showHeroBottomSheet<bool>(
    context,
    builder: (_) => _RescheduleSheet(booking: booking),
  );
}

final class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.booking});

  final UpcomingBooking booking;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

final class _RescheduleSheetState extends State<_RescheduleSheet> {
  late final ProtectionRepository _maint =
      ProtectionRepository(sl<ApiClient>());
  late final AccountRepository _account = AccountRepository(sl<ApiClient>());

  DateTime? _date;
  List<String> _hours = const [];
  bool _hoursLoading = false;
  String? _hour;
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Start from the current appointment; changing the date resets the hour
    // (website behavior).
    _date = widget.booking.orderdate;
    final t = (widget.booking.ordertime ?? '').trim();
    if (t.length >= 5) _hour = t.substring(0, 5);
    if (_date != null) _loadHours(_date!, keepHour: true);
  }

  Future<void> _loadHours(DateTime d, {bool keepHour = false}) async {
    setState(() {
      _hoursLoading = true;
      if (!keepHour) _hour = null;
    });
    final hours = await _maint.hours(d);
    if (!mounted) return;
    setState(() {
      _hours = hours;
      _hoursLoading = false;
      if (_hour != null && !hours.contains(_hour)) _hour = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showAvailabilityCalendarSheet(
      context,
      selected: _date,
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    _loadHours(picked);
  }

  Future<void> _submit(String Function(String, String) tr) async {
    final user = sl<AuthBloc>().state.user;
    final guid = widget.booking.guid ?? '';
    final custId = user?.custId ?? '';
    final d = _date;
    final h = _hour;
    if (d == null || h == null || guid.isEmpty || custId.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await _account.updateBooking(
      guid: guid,
      custId: custId,
      orderdate:
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      orderTime: h.length == 5 ? '$h:00' : h,
    );
    if (!mounted) return;
    if (err == null) {
      setState(() {
        _busy = false;
        _done = true;
      });
    } else {
      setState(() {
        _busy = false;
        _error = err.isEmpty
            ? tr('تعذّر تعديل الحجز. حاول مرة أخرى.',
                'Could not update the booking. Please try again.')
            : err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = sl<LocaleCubit>().state.languageCode;
    final isAr = lang == 'ar';
    String tr(String ar, String en) => isAr ? ar : en;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(10), context.rs(20), context.rs(16)),
          child: _done
              ? _successView(context, tr, scheme)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: SheetHandle()),
                    SizedBox(height: context.rs(14)),
                    Text(tr('تعديل الموعد', 'Reschedule appointment'),
                        style: TextStyle(
                            fontSize: context.rf(17),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rs(4)),
                    Text(
                      tr('اختر التاريخ والوقت الجديدين لحجزك.',
                          'Pick the new date and time for your booking.'),
                      style: TextStyle(
                          fontSize: context.rf(11.5),
                          height: 1.4,
                          color: scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                    SizedBox(height: context.rs(16)),
                    // Date — the shared availability calendar (website cycle).
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        alignment: AlignmentDirectional.centerStart,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.6)),
                        foregroundColor: scheme.onSurface,
                      ),
                      onPressed: _busy ? null : _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(
                        _date == null
                            ? tr('اختر التاريخ', 'Pick a date')
                            : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: context.rf(13),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(height: context.rs(12)),
                    if (_hoursLoading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.4)),
                      ))
                    else if (_date != null && _hours.isEmpty)
                      Text(
                        tr('لا توجد أوقات متاحة في هذا اليوم.',
                            'No available times on this day.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: context.rf(12),
                            color: scheme.onSurface.withValues(alpha: 0.55)),
                      )
                    else if (_hours.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final h in _hours)
                            ChoiceChip(
                              label: Text(h,
                                  textDirection: TextDirection.ltr,
                                  style:
                                      TextStyle(fontSize: context.rf(11.5))),
                              selected: _hour == h,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() => _hour = h),
                            ),
                        ],
                      ),
                    if (_error != null) ...[
                      SizedBox(height: context.rs(10)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.rs(12)),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFE5484D).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: TextStyle(
                                color: const Color(0xFFE5484D),
                                fontSize: context.rf(12))),
                      ),
                    ],
                    SizedBox(height: context.rs(16)),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: const StadiumBorder(),
                        textStyle: TextStyle(
                            fontSize: context.rf(14),
                            fontWeight: FontWeight.w800),
                      ),
                      onPressed: _busy || _date == null || _hour == null
                          ? null
                          : () => _submit(tr),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4))
                          : Text(tr('حفظ التعديل', 'Save changes')),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _successView(BuildContext context,
      String Function(String, String) tr, ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: SheetHandle()),
        SizedBox(height: context.rs(22)),
        Icon(Icons.check_circle_rounded, size: 56, color: scheme.primary),
        SizedBox(height: context.rs(12)),
        Text(
          tr('تم تعديل موعد حجزك بنجاح.',
              'Your appointment was rescheduled successfully.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, height: 1.5, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: context.rs(18)),
        FilledButton(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: const StadiumBorder()),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(tr('تم', 'Done')),
        ),
      ],
    );
  }
}
