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
import '../../../shared/widgets/app_dropdown.dart';
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
  showAppModalSheet<void>(
    context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder:(_) => BlocProvider(
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
                  minimumSize: const Size.fromHeight(44),
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
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder()),
              onPressed: cubit.startForm,
              icon: const Icon(Icons.directions_car_filled_outlined),
              label: Text(t.acHaveCar),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
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
            AppDropdown<String>(
              label: t.offersYear,
              value: state.year,
              items: [
                for (final y in state.years())
                  AppDropdownItem(value: y, label: y),
              ],
              onChanged: cubit.selectYear,
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: t.homeSelectCar,
              value: state.groupId,
              items: [
                for (final g in state.groupOptions())
                  AppDropdownItem(value: g.id ?? '', label: g.name(lang)),
              ],
              onChanged: cubit.selectGroup,
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: t.homeSelectModel,
              value: state.modelId,
              items: [
                for (final m in state.modelOptions())
                  AppDropdownItem(
                      value: m.id ?? '',
                      label: '${m.name(lang)} ${m.year ?? ''}'.trim()),
              ],
              onChanged: cubit.selectModel,
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
                  minimumSize: const Size.fromHeight(44),
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
  showAppModalSheet<void>(
    context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder:(_) => BlocProvider(
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
                  minimumSize: const Size.fromHeight(44),
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
/// [onChanged] fires after edits that alter the garage (e.g. renaming).
void showVehicleHubSheet(BuildContext context,
    {required GarageCar car, VoidCallback? onChanged}) {
  showHeroBottomSheet<void>(
    context,
    heightFactor: 0.8,
    builder: (_) => _VehicleHub(car: car, onChanged: onChanged),
  );
}

final class _VehicleHub extends StatefulWidget {
  const _VehicleHub({required this.car, this.onChanged});

  final GarageCar car;
  final VoidCallback? onChanged;

  @override
  State<_VehicleHub> createState() => _VehicleHubState();
}

final class _VehicleHubState extends State<_VehicleHub> {
  /// Locally applied nickname so the open hub reflects a rename instantly
  /// (the garage refresh happens behind it via [_VehicleHub.onChanged]).
  String? _alias;

  String _displayName(GarageCar car, String lang) {
    final a = (_alias ?? '').trim();
    return a.isNotEmpty ? a : car.displayName(lang);
  }

  void _rename(AppLocalizations t) {
    showRenameCarSheet(context, car: widget.car, onRenamed: (alias) {
      if (!mounted) return;
      setState(() => _alias = alias);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.alSaved)));
      widget.onChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final car = widget.car;

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
            Row(children: [
              Flexible(
                child: Text(
                  '${_displayName(car, lang)} ${car.year ?? ''}'.trim(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(19), fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(width: context.rs(8)),
              // Pencil roundel — rename the car (nickname).
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _rename(t),
                child: Container(
                  width: context.rs(28),
                  height: context.rs(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.08),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.35)),
                  ),
                  child: Icon(Icons.edit_rounded,
                      size: 14, color: scheme.primary),
                ),
              ),
            ]),
            SizedBox(height: context.rs(14)),

            // Next PM — computed by the backend proc (single truth).
            if ((car.vin ?? '').isNotEmpty && (car.modelCode ?? '').isNotEmpty)

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
                  minimumSize: const Size.fromHeight(44),
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
                    minimumSize: const Size.fromHeight(44),
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
                    minimumSize: const Size.fromHeight(44),
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

/* ═══════════════════════ Rename car (nickname) ═══════════════════════ */

/// Small rename sheet — a text field prefilled with the current alias +
/// save (App_UserCar_SetAlias via the alias endpoint). Calls [onRenamed]
/// with the saved nickname on success.
void showRenameCarSheet(BuildContext context,
    {required GarageCar car, void Function(String alias)? onRenamed}) {
  showAppModalSheet<void>(
    context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder:(_) => _RenameCarView(car: car, onRenamed: onRenamed),
  );
}

final class _RenameCarView extends StatefulWidget {
  const _RenameCarView({required this.car, this.onRenamed});

  final GarageCar car;
  final void Function(String alias)? onRenamed;

  @override
  State<_RenameCarView> createState() => _RenameCarViewState();
}

final class _RenameCarViewState extends State<_RenameCarView> {
  late final TextEditingController _controller =
      TextEditingController(text: (widget.car.alias ?? '').trim());
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final alias = _controller.text.trim();
    if (alias.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final userId = sl<AuthBloc>().state.user?.userId ?? 0;
    final (ok, _) = await AccountRepository(sl<ApiClient>()).setCarAlias(
      vin: widget.car.vin ?? '',
      userId: userId,
      alias: alias,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onRenamed?.call(alias);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

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
            Text(t.alRename,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              widget.car.displayName(
                  context.watch<LocaleCubit>().state.languageCode),
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 40,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: t.alNickname,
                counterText: '',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(t.offersSubmitFailed,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder()),
              onPressed:
                  _busy || _controller.text.trim().isEmpty ? null : _save,
              child: _busy
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

