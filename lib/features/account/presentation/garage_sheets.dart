import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../protection/data/protection_repository.dart';
import '../../protection/domain/protection_models.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';
import 'maintenance_booking_sheet.dart';

/* ═══════════════════════════ Add car ═══════════════════════════ */

/// Two paths, per the spec: "I own a car" → pickers + VIN + name → register;
/// "I don't" → the online store.
void showAddCarSheet(BuildContext context, {VoidCallback? onAdded}) {
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => BlocProvider(
      create: (_) => _AddCarCubit(
        AccountRepository(sl<ApiClient>()),
        ProtectionRepository(sl<ApiClient>()),
        userId: sl<AuthBloc>().state.user?.userId ?? 0,
      ),
      child: _AddCarView(onAdded: onAdded),
    ),
  );
}

enum _AddPhase { choose, form, busy, done, failed }

final class _AddCarState extends Equatable {
  const _AddCarState({
    this.phase = _AddPhase.choose,
    this.groups = const [],
    this.models = const [],
    this.brandDbId = '1',
    this.year,
    this.groupId,
    this.modelId,
    this.reason,
  });

  final _AddPhase phase;
  final List<MaintGroup> groups;
  final List<MaintModel> models;
  final String brandDbId; // 1 Toyota / 2 Lexus
  final String? year;
  final String? groupId;
  final String? modelId; // productTypeID

  final String? reason;

  List<String> years() {
    final ys = groups
        .where((g) => g.brandId == brandDbId)
        .map((g) => g.year ?? '')
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return ys;
  }

  List<MaintGroup> groupOptions() {
    final seen = <String>{};
    return groups
        .where((g) =>
            g.brandId == brandDbId &&
            (year == null || g.year == year) &&
            seen.add('${g.nameEn}'.toUpperCase()))
        .toList();
  }

  List<MaintModel> modelOptions() {
    if (groupId == null) return const [];
    final seen = <String>{};
    return models
        .where((m) =>
            m.groupId == groupId &&
            (year == null || m.year == year) &&
            (m.id ?? '').isNotEmpty &&
            seen.add(m.id!))
        .toList();
  }

  _AddCarState copyWith({
    _AddPhase? phase,
    List<MaintGroup>? groups,
    List<MaintModel>? models,
    String? brandDbId,
    String? Function()? year,
    String? Function()? groupId,
    String? Function()? modelId,
    String? Function()? reason,
  }) =>
      _AddCarState(
        phase: phase ?? this.phase,
        groups: groups ?? this.groups,
        models: models ?? this.models,
        brandDbId: brandDbId ?? this.brandDbId,
        year: year == null ? this.year : year(),
        groupId: groupId == null ? this.groupId : groupId(),
        modelId: modelId == null ? this.modelId : modelId(),
        reason: reason == null ? this.reason : reason(),
      );

  @override
  List<Object?> get props =>
      [phase, groups, models, brandDbId, year, groupId, modelId, reason];
}

final class _AddCarCubit extends Cubit<_AddCarState> {
  _AddCarCubit(this._account, this._protection, {required this.userId})
      : super(const _AddCarState()) {
    _load();
  }

  final AccountRepository _account;
  final ProtectionRepository _protection;
  final int userId;

  final vin = TextEditingController();
  final plate = TextEditingController();
  final alias = TextEditingController();

  Future<void> _load() async {
    final (groups, models) = await _protection.settings();
    if (isClosed) return;
    emit(state.copyWith(groups: groups, models: models));
  }

  void startForm() => emit(state.copyWith(phase: _AddPhase.form));
  void selectBrand(String id) => emit(state.copyWith(
      brandDbId: id, year: () => null, groupId: () => null, modelId: () => null));
  void selectYear(String? y) => emit(
      state.copyWith(year: () => y, groupId: () => null, modelId: () => null));
  void selectGroup(String? id) =>
      emit(state.copyWith(groupId: () => id, modelId: () => null));
  void selectModel(String? id) => emit(state.copyWith(modelId: () => id));

  Future<void> submit() async {
    final v = vin.text.trim().toUpperCase();
    if (v.length != 17 ||
        state.groupId == null ||
        state.year == null) {
      emit(state.copyWith(
          phase: _AddPhase.failed, reason: () => 'invalid'));
      return;
    }
    emit(state.copyWith(phase: _AddPhase.busy, reason: () => null));
    final p = plate.text.trim();
    final (ok, reason) = await _account.addCar({
      'userId': userId,
      'brand': state.brandDbId,
      'productGroupId': state.groupId,
      'modelId': state.year,
      'carId': state.modelId,
      'structureNo': v,
      'boardNoAr': p.isEmpty ? null : p,
      'boardNoEn': p.isEmpty ? null : p,
      'alias': alias.text.trim().isEmpty ? null : alias.text.trim(),
    });
    if (isClosed) return;
    emit(state.copyWith(
        phase: ok ? _AddPhase.done : _AddPhase.failed,
        reason: () => reason));
  }

  @override
  Future<void> close() {
    vin.dispose();
    plate.dispose();
    alias.dispose();
    return super.close();
  }
}

final class _AddCarView extends StatelessWidget {
  const _AddCarView({this.onAdded});

  final VoidCallback? onAdded;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_AddCarCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    if (state.phase == _AddPhase.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 52, color: scheme.primary),
            const SizedBox(height: 14),
            Text(t.acAddCarDone,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder()),
              onPressed: () {
                Navigator.of(context).pop();
                onAdded?.call();
              },
              child: Text(t.commonDone),
            ),
          ],
        ),
      );
    }

    // Path chooser: owns a car → form; doesn't → the store.
    if (state.phase == _AddPhase.choose) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: 14),
            Text(t.acAddCarTitle,
                style: TextStyle(
                    fontSize: context.rf(18), fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(t.acAddCarSub,
                style: TextStyle(
                    fontSize: context.rf(12.5),
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder()),
              onPressed: cubit.startForm,
              icon: const Icon(Icons.directions_car_filled_outlined),
              label: Text(t.acHaveCar),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                side: BorderSide(color: scheme.primary),
                foregroundColor: scheme.primary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.onlineStore);
              },
              icon: const Icon(Icons.storefront_outlined),
              label: Text(t.acNoCar),
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
            Text(t.acHaveCar,
                style: TextStyle(
                    fontSize: context.rf(18), fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              for (final (id, label) in [('1', 'Toyota'), ('2', 'Lexus')])
                Padding(
                  padding: EdgeInsetsDirectional.only(end: context.rs(8)),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: state.brandDbId == id,
                    onSelected: (_) => cubit.selectBrand(id),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('year-${state.brandDbId}'),
              initialValue: state.year,
              isExpanded: true,
              items: [
                for (final y in state.years())
                  DropdownMenuItem(value: y, child: Text(y)),
              ],
              onChanged: cubit.selectYear,
              decoration: InputDecoration(
                labelText: t.offersYear,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('group-${state.brandDbId}-${state.year}'),
              initialValue: state.groupId,
              isExpanded: true,
              items: [
                for (final g in state.groupOptions())
                  DropdownMenuItem(value: g.id, child: Text(g.name(lang))),
              ],
              onChanged: cubit.selectGroup,
              decoration: InputDecoration(
                labelText: t.homeSelectCar,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('model-${state.groupId}'),
              initialValue: state.modelId,
              isExpanded: true,
              items: [
                for (final m in state.modelOptions())
                  DropdownMenuItem(
                      value: m.id,
                      child: Text('${m.name(lang)} ${m.year ?? ''}'.trim(),
                          overflow: TextOverflow.ellipsis)),
              ],
              onChanged: cubit.selectModel,
              decoration: InputDecoration(
                labelText: t.homeSelectModel,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cubit.vin,
              maxLength: 17,
              textDirection: TextDirection.ltr,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: t.acVin,
                helperText: t.acVinHelp,
                counterText: '',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: cubit.plate,
                  decoration: InputDecoration(
                    labelText: t.acPlateOptional,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: cubit.alias,
                  decoration: InputDecoration(
                    labelText: t.acAliasOptional,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            if (state.phase == _AddPhase.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  switch (state.reason) {
                    'duplicate_vin' => t.acDuplicateVin,
                    'invalid_vin' || 'invalid' => t.acInvalidVin,
                    _ => t.offersSubmitFailed,
                  },
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
              onPressed: state.phase == _AddPhase.busy
                  ? null
                  : () => context.read<_AddCarCubit>().submit(),
              child: state.phase == _AddPhase.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(t.acAddCarCta),
            ),
          ],
        ),
      ),
    );
  }
}

/* ═══════════════════════ Meter reading ═══════════════════════ */

/// Customer odometer update — branch readings are never replaced; the newest
/// reading wins at read time with its source shown.
void showMeterSheet(BuildContext context,
    {required GarageCar car, VoidCallback? onSaved}) {
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => BlocProvider(
      create: (_) => _MeterCubit(
        AccountRepository(sl<ApiClient>()),
        car: car,
        userId: sl<AuthBloc>().state.user?.userId ?? 0,
      ),
      child: _MeterView(car: car, onSaved: onSaved),
    ),
  );
}

final class _MeterState extends Equatable {
  const _MeterState({this.busy = false, this.error, this.latestKnown, this.done = false});

  final bool busy;
  final String? error; // invalid | lower_than_last
  final int? latestKnown;
  final bool done;

  @override
  List<Object?> get props => [busy, error, latestKnown, done];
}

final class _MeterCubit extends Cubit<_MeterState> {
  _MeterCubit(this._repo, {required this.car, required this.userId})
      : super(const _MeterState());

  final AccountRepository _repo;
  final GarageCar car;
  final int userId;
  final controller = TextEditingController();

  Future<void> save() async {
    final v = int.tryParse(controller.text.trim());
    if (v == null || v <= 0) {
      emit(const _MeterState(error: 'invalid'));
      return;
    }
    emit(const _MeterState(busy: true));
    final (ok, reason, latest) = await _repo.addMeterReading(
        vin: car.vin ?? '', userId: userId, reading: v);
    if (isClosed) return;
    emit(ok
        ? const _MeterState(done: true)
        : _MeterState(error: reason ?? 'invalid', latestKnown: latest));
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}

final class _MeterView extends StatelessWidget {
  const _MeterView({required this.car, this.onSaved});

  final GarageCar car;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<_MeterCubit>();
    final state = cubit.state;

    if (state.done) {
      // Pop on the next frame and notify the caller once.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
          onSaved?.call();
        }
      });
    }

    final error = switch (state.error) {
      null => null,
      'lower_than_last' when state.latestKnown != null =>
        t.acLowerReading(formatPrice(state.latestKnown!.toDouble())),
      _ => t.acInvalidReading,
    };

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: 14),
            Text(t.acUpdateMeter,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            if (car.meterReading != null)
              Text(
                t.acLastBranchReading(
                    formatPrice(car.meterReading!.toDouble())),
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: cubit.controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: t.acCurrentKm,
                suffixText: 'KM',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder()),
              onPressed: state.busy ? null : cubit.save,
              child: state.busy
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

/* ═══════════════════════ Vehicle hub ═══════════════════════ */

/// Compact Vehicle Hub — overview + next-PM (backend-computed) + actions.
void showVehicleHubSheet(BuildContext context, {required GarageCar car}) {
  showHeroBottomSheet<void>(
    context,
    heightFactor: 0.8,
    builder: (_) => _VehicleHub(car: car),
  );
}

final class _VehicleHub extends StatelessWidget {
  const _VehicleHub({required this.car});

  final GarageCar car;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(10), context.rs(20), context.rs(24)),
          children: [
            const Center(child: SheetHandle()),
            SizedBox(height: context.rs(12)),
            SizedBox(
              height: context.rs(150),
              child: HomeImage(
                  url: car.image, fit: BoxFit.contain, logicalWidth: 360),
            ),
            SizedBox(height: context.rs(8)),
            Text(
              '${car.displayName(lang)} ${car.year ?? ''}'.trim(),
              style: TextStyle(
                  fontSize: context.rf(19), fontWeight: FontWeight.w800),
            ),
            SizedBox(height: context.rs(14)),

            // Next PM — computed by the backend proc (single truth).
            if ((car.vin ?? '').isNotEmpty && (car.modelCode ?? '').isNotEmpty)
              _NextPmBlock(car: car),

            SizedBox(height: context.rs(14)),
            for (final (label, value) in [
              (t.acVin, car.vin ?? '—'),
              (t.acPlate, car.plate(lang).isEmpty ? '—' : car.plate(lang)),
              (t.acModelCode, car.modelCode ?? '—'),
              (
                t.acLastMaintenance,
                car.maintenanceLastDate == null
                    ? '—'
                    : car.maintenanceLastDate!.toIso8601String().substring(0, 10)
              ),
              (
                t.acMeter,
                car.meterReading == null
                    ? '—'
                    : '${formatPrice(car.meterReading!.toDouble())} KM'
              ),
            ])
              Padding(
                padding: EdgeInsets.only(bottom: context.rs(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: context.rf(12),
                            color:
                                scheme.onSurface.withValues(alpha: 0.55))),
                    Flexible(
                      child: Text(value,
                          textDirection: TextDirection.ltr,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(12.5),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            SizedBox(height: context.rs(12)),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder()),
              onPressed: () => showMaintenanceBookingSheet(context, car: car),
              icon: const Icon(Icons.build_circle_outlined, size: 19),
              label: Text(t.ghBookMaintenance),
            ),
            SizedBox(height: context.rs(8)),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: scheme.primary),
                    foregroundColor: scheme.primary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(Routes.protection);
                  },
                  child: Text(t.ghSvcProtection,
                      style: TextStyle(fontSize: context.rf(11.5))),
                ),
              ),
              SizedBox(width: context.rs(8)),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: scheme.primary),
                    foregroundColor: scheme.primary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(Routes.parts);
                  },
                  child: Text(t.ghSvcParts,
                      style: TextStyle(fontSize: context.rf(11.5))),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

final class _NextPmBlock extends StatelessWidget {
  const _NextPmBlock({required this.car});

  final GarageCar car;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NextPm?>(
      future: AccountRepository(sl<ApiClient>()).nextPm(
        vin: car.vin!,
        modelCode: car.modelCode!,
        userId: sl<AuthBloc>().state.user?.userId,
      ),
      builder: (context, snap) {
        final pm = snap.data;
        if (pm == null) return const SizedBox.shrink();
        return NextPmLine(pm: pm, car: car);
      },
    );
  }
}

/// The next-maintenance line — shared by the dynamic card and the hub.
/// Renders the backend status verbatim; never guesses (per spec).
final class NextPmLine extends StatelessWidget {
  const NextPmLine({super.key, required this.pm, required this.car});

  final NextPm pm;
  final GarageCar car;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final (icon, text, tone) = switch (pm.status) {
      'ok' => (
          Icons.build_circle_outlined,
          t.acNextPm(formatPrice((pm.nextPmkm ?? 0).toDouble()),
              formatPrice((pm.remainingKM ?? 0).toDouble())),
          scheme.primary
        ),
      'overdue' => (
          Icons.warning_amber_rounded,
          t.acPmOverdue(formatPrice((pm.nextPmkm ?? 0).toDouble())),
          scheme.error
        ),
      'no_mapping' => (
          Icons.info_outline_rounded,
          t.acPmNoPlan,
          scheme.onSurface.withValues(alpha: 0.6)
        ),
      _ => (
          Icons.speed_rounded,
          t.acPmNeedsReading,
          scheme.onSurface.withValues(alpha: 0.7)
        ),
    };

    return Container(
      padding: EdgeInsets.all(context.rs(12)),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: tone),
            SizedBox(width: context.rs(7)),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: tone)),
            ),
          ]),
          if (pm.currentOdometer != null) ...[
            SizedBox(height: context.rs(6)),
            Text(
              t.acOdometerLine(
                formatPrice(pm.currentOdometer!.toDouble()),
                pm.odometerSource == 'branch'
                    ? t.acSourceBranch
                    : t.acSourceCustomer,
              ),
              style: TextStyle(
                fontSize: context.rf(10.5),
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ],
          SizedBox(height: context.rs(8)),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: context.rs(10)),
                  minimumSize: Size.zero),
              onPressed: () => showMeterSheet(context, car: car),
              icon: const Icon(Icons.speed_rounded, size: 15),
              label: Text(t.acUpdateMeter,
                  style: TextStyle(
                      fontSize: context.rf(11), fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
