import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/protection_booking_cubit.dart';
import '../data/protection_repository.dart';
import '../domain/protection_models.dart';

/// Booking sheet for a protection package — branch, date, live hour grid and
/// contact details, POSTing the website's ERP booking flow. Caller must have
/// verified the user is signed in.
void showProtectionBookingSheet(
  BuildContext context, {
  required ProtectionPackage package,
  required MaintModel model,
  required String? groupId,
}) {
  final lang = sl<LocaleCubit>().state.languageCode;
  final brandKey = sl<ThemeCubit>().state.brandKey;
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => BlocProvider(
      create: (_) => ProtectionBookingCubit(
        repo: ProtectionRepository(sl<ApiClient>()),
        package: package,
        model: model,
        groupId: groupId,
        brandDbId: brandKey == 'lexus' ? '2' : '1',
        user: sl<AuthBloc>().state.user,
        lang: lang,
      ),
      child: const _BookingView(),
    ),
  );
}

final class _BookingView extends StatelessWidget {
  const _BookingView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<ProtectionBookingCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    if (state.phase == ProtectionBookingPhase.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 52, color: scheme.primary),
            const SizedBox(height: 14),
            Text(t.protBooked,
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
            Text(t.protBookTitle,
                style: TextStyle(
                    fontSize: context.rf(18), fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${cubit.package.name(lang)} — ${cubit.model.name(lang)} ${cubit.model.year ?? ''}',
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                PriceText(
                    price: cubit.package.price,
                    currency: '',
                    contactForPrice: '',
                    fontSize: context.rf(14)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Branch ──
            AppDropdown<String>(
              label: t.protBranch,
              value: state.branchId,
              items: [
                for (final b in state.branches)
                  AppDropdownItem(value: b.id ?? '', label: b.name(lang)),
              ],
              onChanged: cubit.selectBranch,
            ),
            const SizedBox(height: 12),

            // ── Date ──
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side:
                    BorderSide(color: scheme.outline.withValues(alpha: 0.8)),
                foregroundColor: scheme.onSurface,
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.date ?? now,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 60)),
                );
                if (picked != null) cubit.selectDate(picked);
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(
                state.date == null
                    ? t.protPickDate
                    : '${state.date!.year}-${state.date!.month.toString().padLeft(2, '0')}-${state.date!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: context.rf(13), fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),

            // ── Hours (live availability) ──
            if (state.hoursLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4))),
              )
            else if (state.date != null && state.hours.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t.protNoHours,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: context.rf(12),
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              )
            else if (state.hours.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in state.hours)
                    ChoiceChip(
                      label: Text(h,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: context.rf(11.5))),
                      selected: state.hour == h,
                      onSelected: (_) => cubit.selectHour(h),
                    ),
                ],
              ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                  child:
                      _Field(controller: cubit.firstName, label: t.formFirstName)),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _Field(controller: cubit.lastName, label: t.formLastName)),
            ]),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.phone,
                label: t.formPhone,
                keyboard: TextInputType.phone,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.email,
                label: t.formEmailOptional,
                keyboard: TextInputType.emailAddress,
                ltr: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _Field(
                      controller: cubit.meter,
                      label: t.offersMeter,
                      keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Field(
                      controller: cubit.vin,
                      label: t.offersVinOptional,
                      ltr: true)),
            ]),
            const SizedBox(height: 12),
            _Field(controller: cubit.note, label: t.formNoteOptional, maxLines: 2),
            const SizedBox(height: 18),
            if (state.phase == ProtectionBookingPhase.failed || state.error)
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
              onPressed: state.phase == ProtectionBookingPhase.busy
                  ? null
                  : () => context.read<ProtectionBookingCubit>().submit(),
              child: state.phase == ProtectionBookingPhase.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(t.protConfirmBooking),
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
