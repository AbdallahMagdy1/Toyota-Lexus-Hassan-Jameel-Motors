import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/domain/app_user.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../protection/data/protection_repository.dart';
import '../../protection/domain/protection_models.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';

/// "حجز صيانة" — the website BookingCard's exact 3 steps, mobile-native:
///   1 الخدمة (main services → PM packages priced by ModelCode / sub-services)
///   2 بيانات السيارة (حجز لإحدى سياراتي ← الجراج | حجز لسيارة أخرى ← cascade)
///   3 الموعد وبيانات التواصل (available-days calendar + live hour grid)
/// Submit follows the website payload verbatim (leaf serviceId, note
/// composition, userId = CustID) → App_ServiceRequestAdd.
void showMaintenanceBookingSheet(BuildContext context, {GarageCar? car}) {
  final lang = sl<LocaleCubit>().state.languageCode;
  final brandKey = sl<ThemeCubit>().state.brandKey;
  showHeroBottomSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => _BookingCubit(
        repo: ProtectionRepository(sl<ApiClient>()),
        account: AccountRepository(sl<ApiClient>()),
        preselected: car,
        user: sl<AuthBloc>().state.user,
        lang: lang,
        lockedBrand: brandKey == 'lexus' ? '2' : '1',
      ),
      child: const _BookingView(),
    ),
  );
}

enum _Phase { editing, busy, done, failed }

final class _CalDay extends Equatable {
  const _CalDay({required this.date, required this.type, required this.hoursCount});

  final DateTime date;
  final int type; // 1 available, 0 holiday, -1 unavailable
  final int hoursCount;

  @override
  List<Object?> get props => [date, type];
}

final class _BookingState extends Equatable {
  const _BookingState({
    this.step = 1,
    this.phase = _Phase.editing,
    // step 1 — main service picked by INDEX (legacy data shares one GUID
    // across several services), then sub1 drill, then PM km packages.
    this.services = const [],
    this.serviceIndex,
    this.sub1 = const [],
    this.sub1Loading = false,
    this.sub1Id,
    this.packages = const [],
    this.packagesLoading = false,
    this.packageId,
    // step 2
    this.garage = const [],
    this.mine = true,
    this.myCarIndex = 0,
    this.groups = const [],
    this.models = const [],
    this.year,
    this.groupId,
    this.modelId,
    // step 3
    this.branches = const [],
    this.branchId,
    this.calMonth,
    this.days = const [],
    this.daysLoading = false,
    this.date,
    this.hours = const [],
    this.hoursLoading = false,
    this.hour,
    this.error = false,
    this.bookingId,
  });

  final int step;
  final _Phase phase;
  final List<Map<String, dynamic>> services;
  final int? serviceIndex;
  final List<Map<String, dynamic>> sub1;
  final bool sub1Loading;
  final String? sub1Id;
  final List<Map<String, dynamic>> packages;
  final bool packagesLoading;
  final String? packageId;

  Map<String, dynamic>? get mainService =>
      serviceIndex == null ? null : services.elementAtOrNull(serviceIndex!);

  final List<GarageCar> garage;
  final bool mine;
  final int myCarIndex;
  final List<MaintGroup> groups;
  final List<MaintModel> models;
  final String? year;
  final String? groupId;
  final String? modelId;

  final List<MaintBranch> branches;
  final String? branchId;
  final DateTime? calMonth;
  final List<_CalDay> days;
  final bool daysLoading;
  final DateTime? date;
  final List<String> hours;
  final bool hoursLoading;
  final String? hour;
  final bool error;
  final String? bookingId;

  GarageCar? get myCar => garage.elementAtOrNull(myCarIndex);

  _BookingState copyWith({
    int? step,
    _Phase? phase,
    List<Map<String, dynamic>>? services,
    int? Function()? serviceIndex,
    List<Map<String, dynamic>>? sub1,
    bool? sub1Loading,
    String? Function()? sub1Id,
    List<Map<String, dynamic>>? packages,
    bool? packagesLoading,
    String? Function()? packageId,
    List<GarageCar>? garage,
    bool? mine,
    int? myCarIndex,
    List<MaintGroup>? groups,
    List<MaintModel>? models,
    String? Function()? year,
    String? Function()? groupId,
    String? Function()? modelId,
    List<MaintBranch>? branches,
    String? Function()? branchId,
    DateTime? calMonth,
    List<_CalDay>? days,
    bool? daysLoading,
    DateTime? Function()? date,
    List<String>? hours,
    bool? hoursLoading,
    String? Function()? hour,
    bool? error,
    String? Function()? bookingId,
  }) =>
      _BookingState(
        step: step ?? this.step,
        phase: phase ?? this.phase,
        services: services ?? this.services,
        serviceIndex: serviceIndex == null ? this.serviceIndex : serviceIndex(),
        sub1: sub1 ?? this.sub1,
        sub1Loading: sub1Loading ?? this.sub1Loading,
        sub1Id: sub1Id == null ? this.sub1Id : sub1Id(),
        packages: packages ?? this.packages,
        packagesLoading: packagesLoading ?? this.packagesLoading,
        packageId: packageId == null ? this.packageId : packageId(),
        garage: garage ?? this.garage,
        mine: mine ?? this.mine,
        myCarIndex: myCarIndex ?? this.myCarIndex,
        groups: groups ?? this.groups,
        models: models ?? this.models,
        year: year == null ? this.year : year(),
        groupId: groupId == null ? this.groupId : groupId(),
        modelId: modelId == null ? this.modelId : modelId(),
        branches: branches ?? this.branches,
        branchId: branchId == null ? this.branchId : branchId(),
        calMonth: calMonth ?? this.calMonth,
        days: days ?? this.days,
        daysLoading: daysLoading ?? this.daysLoading,
        date: date == null ? this.date : date(),
        hours: hours ?? this.hours,
        hoursLoading: hoursLoading ?? this.hoursLoading,
        hour: hour == null ? this.hour : hour(),
        error: error ?? this.error,
        bookingId: bookingId == null ? this.bookingId : bookingId(),
      );

  @override
  List<Object?> get props => [
        step, phase, services, serviceIndex, sub1, sub1Loading, sub1Id,
        packages, packagesLoading, packageId,
        garage, mine, myCarIndex, groups, models, year, groupId, modelId,
        branches, branchId, calMonth, days, daysLoading, date, hours,
        hoursLoading, hour, error, bookingId,
      ];
}

final class _BookingCubit extends Cubit<_BookingState> {
  _BookingCubit({
    required ProtectionRepository repo,
    required AccountRepository account,
    required this.user,
    required String lang,
    required this.lockedBrand,
    GarageCar? preselected,
  })  : _repo = repo,
        _account = account,
        super(const _BookingState()) {
    phone.text = user?.phone ?? '';
    firstName.text = (lang == 'ar'
            ? user?.firstNameAr ?? user?.firstNameEn
            : user?.firstNameEn ?? user?.firstNameAr) ??
        '';
    lastName.text = (lang == 'ar'
            ? user?.lastNameAr ?? user?.lastNameEn
            : user?.lastNameEn ?? user?.lastNameAr) ??
        '';
    _load(preselected);
  }

  final ProtectionRepository _repo;
  final AccountRepository _account;
  final AppUser? user;
  final String lockedBrand;

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final meter = TextEditingController();
  final note = TextEditingController();

  Future<void> _load(GarageCar? preselected) async {
    // All four catalogs in PARALLEL — the old sequential chain left step 1
    // blank for 4 round-trips.
    final servicesF = _repo.mainServices();
    final branchesF = _repo.branches();
    final settingsF = _repo.settings();
    final garageF = user == null
        ? Future.value(const <GarageCar>[])
        : _account.garage(user!.userId);

    // Paint the service tiles the moment they arrive.
    final services = await servicesF;
    if (isClosed) return;
    emit(state.copyWith(services: services));

    final branches = await branchesF;
    final (groups, models) = await settingsF;
    // Like the website: "my vehicle" mode needs a car of this site brand.
    final garage = (await garageF)
        .where((c) => c.brandDbId == lockedBrand)
        .toList();
    if (isClosed) return;
    var myIndex = 0;
    if (preselected != null) {
      final i = garage.indexWhere((c) => c.vin == preselected.vin);
      if (i >= 0) myIndex = i;
    }
    emit(state.copyWith(
      branches: branches,
      groups: groups,
      models: models,
      garage: garage,
      mine: garage.isNotEmpty,
      myCarIndex: myIndex,
      branchId: () => branches.length == 1 ? branches.first.id : null,
    ));
    final car = garage.elementAtOrNull(myIndex);
    if (car?.meterReading != null) meter.text = '${car!.meterReading}';
  }

  /* step 1 — website drill: main → sub1 → (periodic → km packages). */
  static bool _isPeriodic(String? name) {
    final n = (name ?? '').toLowerCase();
    return n.contains('دورية') || n.contains('periodic');
  }

  static String? _name(Map<String, dynamic>? m, [String key = 'nameAr']) =>
      m?[key]?.toString() ?? m?['nameEn']?.toString();

  Future<void> selectService(int index) async {
    final main = state.services.elementAtOrNull(index);
    if (main == null) return;
    emit(state.copyWith(
      serviceIndex: () => index,
      sub1: const [],
      sub1Id: () => null,
      packages: const [],
      packageId: () => null,
      error: false,
    ));

    // Main service already IS periodic → straight to the km packages.
    if (_isPeriodic(_name(main))) {
      await _loadPackages(main['id']?.toString());
      return;
    }

    emit(state.copyWith(sub1Loading: true));
    final sub1 = await _repo.subServices1(main['id']?.toString() ?? '');
    if (isClosed) return;
    emit(state.copyWith(sub1: sub1, sub1Loading: false));

    // Auto-resolve: when a sub matches the main service by name (فحص/عامة —
    // the legacy data shares one GUID across mains) or there's only one,
    // select it AND hide the list entirely: those services have no real
    // sub-choice for the customer. سمكرة ودهان (no name match) keeps the
    // visible sub picker.
    Map<String, dynamic>? preselect;
    if (sub1.length == 1) {
      preselect = sub1.first;
    } else {
      preselect = sub1
          .where((s) => _name(s) != null && _name(main) == _name(s))
          .firstOrNull;
    }
    if (preselect != null) {
      emit(state.copyWith(sub1: const []));
      await selectSub1(preselect['id']?.toString(), sub: preselect);
    }
  }

  Map<String, dynamic>? _sub1ById(String id) => state.sub1
      .where((s) => s['id']?.toString() == id)
      .firstOrNull;

  Future<void> selectSub1(String? id, {Map<String, dynamic>? sub}) async {
    sub ??= id == null ? null : _sub1ById(id);
    emit(state.copyWith(
        sub1Id: () => id, packages: const [], packageId: () => null));
    if (id == null) return;
    if (_isPeriodic(_name(sub))) {
      // km catalog is keyed on the MAIN service id (website behavior).
      await _loadPackages(state.mainService?['id']?.toString());
    }
  }

  Future<void> _loadPackages(String? mainId) async {
    if (mainId == null) return;
    emit(state.copyWith(packagesLoading: true));
    // The website's BookingCard loads the km schedule WITHOUT a model code —
    // sending one can filter the list to nothing for unmapped models.
    var packages = await _repo.periodicServices(mainId, null);
    if (packages.isEmpty) {
      final modelCode =
          state.mine ? state.myCar?.modelCode : _anotherModel()?.modelCode;
      if ((modelCode ?? '').isNotEmpty) {
        packages = await _repo.periodicServices(mainId, modelCode);
      }
    }
    if (isClosed) return;
    emit(state.copyWith(packages: packages, packagesLoading: false));
  }

  void selectPackage(String? id) => emit(state.copyWith(packageId: () => id));

  /* step 2 */
  void setMine(bool mine) => emit(state.copyWith(mine: mine));

  void selectMyCar(int? i) {
    if (i == null) return;
    emit(state.copyWith(myCarIndex: i));
    final car = state.garage.elementAtOrNull(i);
    if (car?.meterReading != null) meter.text = '${car!.meterReading}';
  }

  List<String> years() => (state.groups
      .where((g) => g.brandId == lockedBrand)
      .map((g) => g.year ?? '')
      .where((y) => y.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a)));

  List<MaintGroup> groupOptions() {
    final seen = <String>{};
    return state.groups
        .where((g) =>
            g.brandId == lockedBrand &&
            (state.year == null || g.year == state.year) &&
            seen.add('${g.nameEn}'.toUpperCase()))
        .toList();
  }

  List<MaintModel> modelOptions() {
    if (state.groupId == null) return const [];
    final seen = <String>{};
    return state.models
        .where((m) =>
            m.groupId == state.groupId &&
            (state.year == null || m.year == state.year) &&
            (m.id ?? '').isNotEmpty &&
            seen.add(m.id!))
        .toList();
  }

  MaintModel? _anotherModel() =>
      modelOptions().where((m) => m.id == state.modelId).firstOrNull;

  void selectYear(String? y) => emit(
      state.copyWith(year: () => y, groupId: () => null, modelId: () => null));
  void selectGroup(String? id) =>
      emit(state.copyWith(groupId: () => id, modelId: () => null));
  void selectModel(String? id) => emit(state.copyWith(modelId: () => id));

  /* step 3 — availability calendar (website /available-days cycle) */
  Future<void> loadMonth(DateTime month) async {
    emit(state.copyWith(calMonth: month, daysLoading: true));
    try {
      final res = await sl<ApiClient>().get<List<dynamic>>(
        ApiPaths.maintDays,
        query: {'month': month.month},
      );
      if (isClosed) return;
      final days = (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map((j) {
            final d = DateTime.tryParse('${j['date']}');
            return d == null
                ? null
                : _CalDay(
                    date: d,
                    type: (j['type'] as num?)?.toInt() ?? -1,
                    hoursCount:
                        (j['availableHoursCount'] as num?)?.toInt() ?? 0,
                  );
          })
          .whereType<_CalDay>()
          .toList();
      emit(state.copyWith(days: days, daysLoading: false));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(daysLoading: false));
    }
  }

  Future<void> selectDate(DateTime d) async {
    emit(state.copyWith(date: () => d, hour: () => null, hoursLoading: true));
    final hours = await _repo.hours(d);
    if (isClosed) return;
    emit(state.copyWith(hours: hours, hoursLoading: false));
  }

  void selectBranch(String? id) => emit(state.copyWith(branchId: () => id));
  void selectHour(String? h) => emit(state.copyWith(hour: () => h));

  /* navigation — website gates: sub1 required when listed, periodic
     requires a km package. */
  bool get _needsPackage =>
      _isPeriodic(_name(state.mainService)) ||
      _isPeriodic(_name(state.sub1
          .where((s) => s['id']?.toString() == state.sub1Id)
          .firstOrNull));

  bool _step1Ok() {
    if (state.mainService == null) return false;
    if (!_isPeriodic(_name(state.mainService)) &&
        state.sub1.isNotEmpty &&
        state.sub1Id == null) {
      return false;
    }
    if (_needsPackage && state.packages.isNotEmpty && state.packageId == null) {
      return false;
    }
    return true;
  }
  bool _step2Ok() => state.mine
      ? state.myCar != null
      : (state.groupId != null && state.year != null);

  void next() {
    if (state.step == 1 && !_step1Ok()) {
      emit(state.copyWith(error: true));
      return;
    }
    if (state.step == 2 && !_step2Ok()) {
      emit(state.copyWith(error: true));
      return;
    }
    emit(state.copyWith(step: state.step + 1, error: false));
  }

  void back() =>
      emit(state.copyWith(step: (state.step - 1).clamp(1, 3), error: false));

  String _fullPhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('00')) return '+${p.substring(2)}';
    if (p.startsWith('0')) p = p.substring(1);
    return '+966$p';
  }

  Future<void> submit() async {
    final ok = state.date != null &&
        (state.hour ?? '').isNotEmpty &&
        firstName.text.trim().isNotEmpty &&
        RegExp(r'^\+?\d{10,15}$').hasMatch(_fullPhone(phone.text));
    if (!ok) {
      emit(state.copyWith(error: true));
      return;
    }
    emit(state.copyWith(phase: _Phase.busy, error: false));

    final svc = state.mainService;
    final sub = state.sub1
        .where((s) => s['id']?.toString() == state.sub1Id)
        .firstOrNull;
    final car = state.mine ? state.myCar : null;
    final another = state.mine ? null : _anotherModel();
    final d = state.date!;

    // Leaf service like the website: km package → sub1 GUID → main GUID
    // (the backend resolver walks GUIDs down to the real ServiceID).
    final leafServiceId =
        state.packageId ?? state.sub1Id ?? svc?['id']?.toString();
    final noteLines = <String>[
      if (svc != null)
        'الخدمة: ${_name(svc) ?? ''}${sub != null ? ' (${_name(sub)})' : ''}',
      if (state.packageId != null) 'Periodic: ${state.packageId}',
      if (note.text.trim().isNotEmpty) note.text.trim(),
    ];

    final booked = await _repo.book({
      'serviceId': leafServiceId,
      'serviceNameEn': svc?['nameEn'] ?? svc?['nameAr'],
      'brandId': lockedBrand,
      'groupId': car?.productGroupId ?? state.groupId,
      'productTypeId': car?.type ?? another?.id,
      'year': car?.year ?? state.year,
      'vin': car?.vin,
      'siteId': state.branchId ?? state.branches.firstOrNull?.id,
      'orderdate':
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'orderTime':
          (state.hour!.length == 5) ? '${state.hour}:00' : state.hour,
      'firstName': firstName.text.trim(),
      'lastName': lastName.text.trim(),
      'phone': _fullPhone(phone.text),
      'email': user?.email,
      'meterReading': int.tryParse(meter.text.trim()),
      'note': noteLines.join(' | '),
      // CustID (not Web_UserID) — the website comment: sending userId saved
      // the wrong CustID → empty name/phone in the ops email.
      'userId': user?.custId,
    });
    if (isClosed) return;
    emit(state.copyWith(
        phase: booked ? _Phase.done : _Phase.failed,
        step: booked ? 4 : state.step));
  }

  @override
  Future<void> close() {
    for (final c in [firstName, lastName, phone, meter, note]) {
      c.dispose();
    }
    return super.close();
  }
}

/* ═══════════════════════════ View ═══════════════════════════ */

final class _BookingView extends StatelessWidget {
  const _BookingView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_BookingCubit>();
    final state = cubit.state;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(10), context.rs(20), 0),
              child: Column(children: [
                const SheetHandle(),
                SizedBox(height: context.rs(14)),
                // 3-segment progress, like the website's ProgressBar.
                Row(children: [
                  for (var s = 1; s <= 3; s++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsetsDirectional.only(
                            end: s < 3 ? context.rs(6) : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: s <= state.step.clamp(1, 3)
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ]),
                SizedBox(height: context.rs(10)),
                if (state.step <= 3)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      t.mbStepOf(state.step),
                      style: TextStyle(
                          fontSize: context.rf(10.5),
                          fontWeight: FontWeight.w800,
                          color: scheme.primary),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: switch (state.step) {
                1 => const _Step1(),
                2 => const _Step2(),
                3 => const _Step3(),
                _ => const _Success(),
              },
            ),
            if (state.step <= 3) const _NavBar(),
            const _FooterBadges(),
          ],
        ),
      ),
    );
  }
}

final class _Step1 extends StatelessWidget {
  const _Step1();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_BookingCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    String svcName(Map<String, dynamic> m) =>
        (lang == 'ar' ? m['nameAr'] : m['nameEn'])?.toString() ??
        m['nameEn']?.toString() ??
        m['nameAr']?.toString() ??
        '';

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(6), context.rs(20), context.rs(10)),
      children: [
        Text(t.mbStep1Title,
            style: TextStyle(
                fontSize: context.rf(21), fontWeight: FontWeight.w800)),
        Text(t.mbStep1Sub,
            style: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.55))),
        SizedBox(height: context.rs(14)),

        // Main services — 2-col tiles, selected by INDEX (the legacy data
        // shares one GUID across several services).
        if (state.services.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: context.rs(12),
          crossAxisSpacing: context.rs(12),
          childAspectRatio: 1.28,
          children: [
            for (var i = 0; i < state.services.length; i++)
              Builder(builder: (context) {
                final selected = state.serviceIndex == i;
                final s = state.services[i];
                // The mock's tile: white soft card, soft-pink icon square
                // top-start, bold label bottom-start; selection = red
                // border + check.
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => cubit.selectService(i),
                    child: Ink(
                      padding: EdgeInsets.all(context.rs(14)),
                      decoration:
                          softCardDecoration(context, radius: 20).copyWith(
                        border: selected
                            ? Border.all(color: scheme.primary, width: 1.6)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: context.rs(38),
                              height: context.rs(38),
                              decoration: BoxDecoration(
                                color:
                                    scheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_iconFor(svcName(s)),
                                  size: 18, color: scheme.primary),
                            ),
                            const Spacer(),
                            if (selected)
                              Icon(Icons.check_circle_rounded,
                                  size: 18, color: scheme.primary),
                          ]),
                          const Spacer(),
                          Text(
                            svcName(s),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.rf(12.5),
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),

        // Sub-service drill (the website's second dropdown, as tappable rows).
        if (state.sub1Loading)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4))),
          )
        else if (state.sub1.isNotEmpty) ...[
          SizedBox(height: context.rs(16)),
          Text(t.mbSubService,
              style: TextStyle(
                  fontSize: context.rf(13), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(8)),
          for (final s in state.sub1)
            Builder(builder: (context) {
              final id = s['id']?.toString();
              final selected = state.sub1Id == id;
              return Padding(
                padding: EdgeInsets.only(bottom: context.rs(7)),
                child: Material(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.08)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => cubit.selectSub1(id),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rs(13),
                          vertical: context.rs(11)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: selected
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.55),
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 17,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.35),
                        ),
                        SizedBox(width: context.rs(9)),
                        Expanded(
                          child: Text(svcName(s),
                              style: TextStyle(
                                  fontSize: context.rf(12.5),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                ),
              );
            }),
        ],

        // Periodic km packages — selectable chips, not a dropdown.
        if (state.packagesLoading)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4))),
          )
        else if (state.packages.isNotEmpty) ...[
          SizedBox(height: context.rs(16)),
          Text(t.mbPackage,
              style: TextStyle(
                  fontSize: context.rf(13), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in state.packages)
                ChoiceChip(
                  label: Text(
                    p['km'] != null
                        ? '${p['km']} KM'
                        : svcName(p),
                    style: TextStyle(fontSize: context.rf(11.5)),
                  ),
                  selected:
                      state.packageId == p['serviceId']?.toString(),
                  onSelected: (_) =>
                      cubit.selectPackage(p['serviceId']?.toString()),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('دورية') || n.contains('periodic')) {
      return Icons.event_repeat_rounded;
    }
    if (n.contains('سمكرة') || n.contains('دهان') || n.contains('paint')) {
      return Icons.format_paint_outlined;
    }
    if (n.contains('فحص') || n.contains('inspect')) {
      return Icons.speed_rounded;
    }
    return Icons.build_outlined;
  }
}

final class _Step2 extends StatelessWidget {
  const _Step2();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_BookingCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(6), context.rs(20), context.rs(10)),
      children: [
        Text(t.mbStep2Title,
            style: TextStyle(
                fontSize: context.rf(21), fontWeight: FontWeight.w800)),
        Text(t.mbStep2Sub,
            style: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.55))),
        SizedBox(height: context.rs(14)),
        if (state.garage.isNotEmpty) ...[
          // The mock's segmented toggle: white track, red pill + check on
          // the selected side.
          Container(
            padding: EdgeInsets.all(context.rs(4)),
            decoration: softCardDecoration(context, radius: 16),
            child: Row(children: [
              for (final (label, isMine) in [
                (t.mbForMyCar, true),
                (t.mbForAnotherCar, false),
              ])
                Expanded(
                  child: GestureDetector(
                    onTap: () => cubit.setMine(isMine),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding:
                          EdgeInsets.symmetric(vertical: context.rs(10)),
                      decoration: BoxDecoration(
                        color: state.mine == isMine
                            ? scheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state.mine == isMine) ...[
                            Icon(Icons.check_rounded,
                                size: 14, color: scheme.onPrimary),
                            SizedBox(width: context.rs(5)),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.rf(11.5),
                                fontWeight: FontWeight.w800,
                                color: state.mine == isMine
                                    ? scheme.onPrimary
                                    : scheme.onSurface
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          SizedBox(height: context.rs(14)),
        ],
        if (state.mine && state.garage.isNotEmpty) ...[
          AppDropdown<int>(
            label: t.homeSelectCar,
            value: state.myCarIndex,
            items: [
              for (var i = 0; i < state.garage.length; i++)
                AppDropdownItem(
                  value: i,
                  label:
                      '${state.garage[i].displayName(lang)} ${state.garage[i].year ?? ''}'
                          .trim(),
                ),
            ],
            onChanged: cubit.selectMyCar,
          ),
          if ((state.myCar?.vin ?? '').isNotEmpty) ...[
            SizedBox(height: context.rs(12)),
            // The mock's pink VIN panel: QR icon + small label over the
            // bold LTR chassis number.
            Container(
              padding: EdgeInsets.all(context.rs(13)),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(Icons.qr_code_2_rounded,
                    size: 22, color: scheme.primary),
                SizedBox(width: context.rs(11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.acVin} (${t.mbVinAuto})',
                        style: TextStyle(
                            fontSize: context.rf(9.5),
                            color:
                                scheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      SizedBox(height: context.rs(2)),
                      Text(
                        state.myCar!.vin!,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            fontSize: context.rf(12.5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ] else ...[
          AppDropdown<String>(
            label: t.offersYear,
            value: state.year,
            items: [
              for (final y in cubit.years()) AppDropdownItem(value: y, label: y),
            ],
            onChanged: cubit.selectYear,
          ),
          SizedBox(height: context.rs(12)),
          AppDropdown<String>(
            label: t.homeSelectCar,
            value: state.groupId,
            items: [
              for (final g in cubit.groupOptions())
                AppDropdownItem(value: g.id ?? '', label: g.name(lang)),
            ],
            onChanged: cubit.selectGroup,
          ),
          SizedBox(height: context.rs(12)),
          AppDropdown<String>(
            label: t.homeSelectModel,
            value: state.modelId,
            items: [
              for (final m in cubit.modelOptions())
                AppDropdownItem(
                    value: m.id ?? '',
                    label: '${m.name(lang)} ${m.year ?? ''}'.trim()),
            ],
            onChanged: cubit.selectModel,
          ),
        ],
      ],
    );
  }
}

final class _Step3 extends StatelessWidget {
  const _Step3();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_BookingCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(6), context.rs(20), context.rs(10)),
      children: [
        Text(t.mbStep3Title,
            style: TextStyle(
                fontSize: context.rf(21), fontWeight: FontWeight.w800)),
        Text(t.mbStep3Sub,
            style: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.55))),
        SizedBox(height: context.rs(14)),
        if (state.branches.length > 1) ...[
          AppDropdown<String>(
            label: t.protBranch,
            value: state.branchId,
            items: [
              for (final b in state.branches)
                AppDropdownItem(value: b.id ?? '', label: b.name(lang)),
            ],
            onChanged: cubit.selectBranch,
          ),
          SizedBox(height: context.rs(12)),
        ],
        // Date — opens the availability calendar (website cycle).
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            alignment: AlignmentDirectional.centerStart,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
            foregroundColor: scheme.onSurface,
          ),
          onPressed: () => _openCalendar(context, cubit),
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text(
            state.date == null
                ? t.protPickDate
                : '${state.date!.year}-${state.date!.month.toString().padLeft(2, '0')}-${state.date!.day.toString().padLeft(2, '0')}',
            style: TextStyle(
                fontSize: context.rf(13), fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: context.rs(12)),
        if (state.hoursLoading)
          const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4)))
        else if (state.date != null && state.hours.isEmpty)
          Text(t.protNoHours,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.rf(12),
                  color: scheme.onSurface.withValues(alpha: 0.55)))
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
        SizedBox(height: context.rs(14)),
        Row(children: [
          Expanded(
              child: TextField(
            controller: cubit.firstName,
            decoration: InputDecoration(
              labelText: t.formFirstName,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
            controller: cubit.lastName,
            decoration: InputDecoration(
              labelText: t.formLastName,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )),
        ]),
        SizedBox(height: context.rs(12)),
        Row(children: [
          Expanded(
              child: TextField(
            controller: cubit.phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: t.formPhone,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
            controller: cubit.meter,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.offersMeter,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )),
        ]),
        SizedBox(height: context.rs(12)),
        // The mock's large soft-gray notes area.
        TextField(
          controller: cubit.note,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: t.formNoteOptional,
            hintStyle: TextStyle(
                fontSize: context.rf(12),
                color: scheme.onSurface.withValues(alpha: 0.45)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF2F4F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void _openCalendar(BuildContext context, _BookingCubit cubit) {
    cubit.loadMonth(cubit.state.calMonth ?? DateTime.now());
    showModalBottomSheet<void>(
      context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _CalendarSheet(),
      ),
    );
  }
}

/// The website's MaintenanceCalendarDialog: month grid, availability tint,
/// holiday/unavailable states, capacity badge, legend.
final class _CalendarSheet extends StatelessWidget {
  const _CalendarSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_BookingCubit>();
    final state = cubit.state;
    final scheme = Theme.of(context).colorScheme;
    final month = state.calMonth ?? DateTime.now();
    final today = DateTime.now();
    final byDay = {
      for (final d in state.days)
        '${d.date.year}-${d.date.month}-${d.date.day}': d
    };
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Week starts Sunday (الأحد), like the website grid.
    final leading = first.weekday % 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(
              onPressed: () => cubit
                  .loadMonth(DateTime(month.year, month.month - 1, 1)),
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
              onPressed: () => cubit
                  .loadMonth(DateTime(month.year, month.month + 1, 1)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          if (state.daysLoading)
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
                    final isPast = date.isBefore(
                        DateTime(today.year, today.month, today.day));
                    final clickable =
                        (info?.type ?? -1) == 1 && !isPast;
                    final selected = state.date != null &&
                        state.date!.year == date.year &&
                        state.date!.month == date.month &&
                        state.date!.day == date.day;
                    final holiday = info?.type == 0;

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: clickable
                          ? () {
                              cubit.selectDate(date);
                              Navigator.of(context).pop();
                            }
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

final class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_BookingCubit>();
    final state = cubit.state;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(6), context.rs(20), context.rs(4)),
      child: Column(children: [
        if (state.error || state.phase == _Phase.failed)
          Padding(
            padding: EdgeInsets.only(bottom: context.rs(8)),
            child: Text(
              state.error ? t.formCheckFields : t.offersSubmitFailed,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error, fontSize: context.rf(12)),
            ),
          ),
        // The mock's footer: big red stadium CTA taking the row, with the
        // "السابق" text link beside it from step 2 on.
        Row(children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 52),
                shape: const StadiumBorder(),
                textStyle: TextStyle(
                    fontSize: context.rf(14), fontWeight: FontWeight.w800),
              ),
              onPressed: state.phase == _Phase.busy
                  ? null
                  : state.step < 3
                      ? cubit.next
                      : cubit.submit,
              child: state.phase == _Phase.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(state.step < 3 ? t.mbNext : t.protConfirmBooking),
            ),
          ),
          if (state.step > 1) ...[
            SizedBox(width: context.rs(14)),
            TextButton(
              onPressed: cubit.back,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurface.withValues(alpha: 0.75),
                textStyle: TextStyle(
                    fontSize: context.rf(13.5), fontWeight: FontWeight.w800),
              ),
              child: Text(t.mbBack),
            ),
          ],
        ]),
      ]),
    );
  }
}

final class _Success extends StatelessWidget {
  const _Success();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_rounded, size: 56, color: scheme.primary),
          const SizedBox(height: 14),
          Text(t.protBooked,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, height: 1.5, fontWeight: FontWeight.w700)),
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
}

/// The website footer badges: حجز آمن · ضمان 12 شهر · إلغاء مجاني.
final class _FooterBadges extends StatelessWidget {
  const _FooterBadges();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(6), context.rs(20), context.rs(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Green check badges, like the mock's trust row.
          for (final label in [
            t.mbBadgeSecure,
            t.mbBadgeWarranty,
            t.mbBadgeFreeCancel,
          ]) ...[
            const Icon(Icons.check_circle_rounded,
                size: 13, color: Color(0xFF2E9E5B)),
            SizedBox(width: context.rs(4)),
            Text(label,
                style: TextStyle(
                    fontSize: context.rf(9.5),
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.6))),
            SizedBox(width: context.rs(14)),
          ],
        ],
      ),
    );
  }
}
