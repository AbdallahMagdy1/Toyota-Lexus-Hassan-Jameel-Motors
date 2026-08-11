import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../coupons/domain/coupon_models.dart';
import '../../guest_home/presentation/guest_home_view.dart' show showLoginPrompt;
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../data/protection_repository.dart';
import '../domain/protection_models.dart';

/// Package detail — the website's /maintenance/protection/[id]: tier badge,
/// price breakdown (total ÷ 1.15 → base + VAT), and the description parsed
/// into check-list sections, then "Reserve & pay" (website payment cycle in
/// a WebView).
void showProtectionDetailSheet(
  BuildContext context, {
  required ProtectionPackage package,
  String? vehicleLabel,
  String? vin,
}) {
  showHeroBottomSheet<void>(
    context,
    builder: (_) =>
        _DetailSheet(package: package, vehicleLabel: vehicleLabel, vin: vin),
  );
}

/// The website's parseProtectionDescription: split on numbered headers or
/// the known section keywords; bullets split on newlines/bullets/dashes.
List<({String title, List<String> items, String type})> parseSections(
    String text) {
  if (text.trim().isEmpty) return const [];
  const keywords = [
    'الخدمات المجانية', 'الخدمات المجانيه', 'المميزات',
    'Free Services', 'Features',
  ];
  final headerRe = RegExp(
    '(?=\\d+\\s*-\\s*)|(?=(${keywords.map(RegExp.escape).join('|')}))',
    caseSensitive: false,
  );
  final chunks = text
      .split(headerRe)
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();
  return chunks.map((chunk) {
    final lines = chunk
        .split(RegExp(r'[\n•·-]'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final title = lines.isEmpty ? '' : lines.first;
    final items = lines.length > 1 ? lines.sublist(1) : <String>[];
    final low = title.toLowerCase();
    final type = (low.contains('مجاني') || low.contains('free'))
        ? 'free'
        : (low.contains('المميزات') || low.contains('features'))
            ? 'features'
            : 'standard';
    return (title: title, items: items, type: type);
  }).toList();
}

final class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.package, this.vehicleLabel, this.vin});

  final ProtectionPackage package;
  final String? vehicleLabel;
  final String? vin;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final price = package.price ?? 0;
    final base = price / 1.15;
    final vat = price - base;
    final sections = parseSections(package.description(lang));

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(10),
                  context.rs(20), context.rs(16)),
              children: [
                const Center(child: SheetHandle()),
                SizedBox(height: context.rs(14)),
                Text(package.name(lang),
                    style: TextStyle(
                        fontSize: context.rf(21),
                        fontWeight: FontWeight.w800)),
                if (vehicleLabel != null)
                  Text(vehicleLabel!,
                      style: TextStyle(
                          fontSize: context.rf(11.5),
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                SizedBox(height: context.rs(14)),

                // Price card: total + base + VAT(15%), like the website.
                Container(
                  padding: EdgeInsets.all(context.rs(14)),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.protTotal,
                            style: TextStyle(
                                fontSize: context.rf(12.5),
                                fontWeight: FontWeight.w800)),
                        PriceText(
                            price: price,
                            currency: '',
                            contactForPrice: t.homeContactForPrice,
                            fontSize: context.rf(20)),
                      ],
                    ),
                    SizedBox(height: context.rs(8)),
                    for (final (label, v) in [
                      (t.protBasePrice, base),
                      (t.protVat, vat),
                    ])
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: context.rf(11),
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6))),
                          PriceText(
                              price: double.parse(v.toStringAsFixed(2)),
                              currency: '',
                              contactForPrice: '',
                              fontSize: context.rf(12),
                              color: scheme.onSurface),
                        ],
                      ),
                  ]),
                ),

                // Description sections as check-lists (website parser port).
                for (final s in sections) ...[
                  SizedBox(height: context.rs(14)),
                  Container(
                    padding: EdgeInsets.all(context.rs(14)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.55)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(
                            s.type == 'free'
                                ? Icons.card_giftcard_rounded
                                : s.type == 'features'
                                    ? Icons.auto_awesome_rounded
                                    : Icons.verified_user_outlined,
                            size: 17,
                            color: scheme.primary,
                          ),
                          SizedBox(width: context.rs(8)),
                          Expanded(
                            child: Text(s.title,
                                style: TextStyle(
                                    fontSize: context.rf(13),
                                    fontWeight: FontWeight.w800)),
                          ),
                        ]),
                        SizedBox(height: context.rs(8)),
                        for (final item in s.items)
                          Padding(
                            padding: EdgeInsets.only(bottom: context.rs(5)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_rounded,
                                    size: 14, color: scheme.primary),
                                SizedBox(width: context.rs(7)),
                                Expanded(
                                  child: Text(item,
                                      style: TextStyle(
                                          fontSize: context.rf(11.5),
                                          height: 1.5)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(18), context.rs(8), context.rs(18), context.rs(10)),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(
                      fontSize: context.rf(14), fontWeight: FontWeight.w800)),
              onPressed: () {
                if (sl<AuthBloc>().state.status != AuthStatus.authenticated) {
                  showLoginPrompt(context);
                  return;
                }
                _showPaySheet(context, package,
                    vehicleLabel: vehicleLabel, vin: vin);
              },
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: Text(t.protReservePay),
            ),
          ),
        ]),
      ),
    );
  }
}

/* ═════════════════ Reserve & pay (website payment cycle) ═════════════════ */

void _showPaySheet(BuildContext context, ProtectionPackage package,
    {String? vehicleLabel, String? vin}) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => BlocProvider(
      create: (_) => _PayCubit(
        ProtectionRepository(sl<ApiClient>()),
        package: package,
        vin: vin,
        vehicleLabel: vehicleLabel,
      ),
      child: const _PayView(),
    ),
  );
}

enum _PayPhase { form, busy, sadad, success, failed }

final class _PayState extends Equatable {
  const _PayState({
    this.phase = _PayPhase.form,
    this.branches = const [],
    this.branchId,
    this.date,
    this.hours = const [],
    this.hoursLoading = false,
    this.hour,
    this.provider = 'myfatoorah',
    this.fullCar = true,
    this.fullGrade = '0.2',
    this.sadadNumber,
    this.error = false,
    this.couponCode,
    this.couponResult,
    this.couponBusy = false,
  });

  final _PayPhase phase;
  final List<MaintBranch> branches;
  final String? branchId;
  final DateTime? date;
  final List<String> hours;
  final bool hoursLoading;
  final String? hour;
  final String provider; // myfatoorah | tabby | tamara
  final bool fullCar;
  final String fullGrade; // 0 | 0.1 | 0.2
  final String? sadadNumber;
  final bool error;

  /// Applied coupon (server-validated). The discount is server-computed;
  /// this state only carries the verdict for display + pay-time forwarding.
  final String? couponCode;
  final CouponResult? couponResult;
  final bool couponBusy;

  _PayState copyWith({
    _PayPhase? phase,
    List<MaintBranch>? branches,
    String? Function()? branchId,
    DateTime? Function()? date,
    List<String>? hours,
    bool? hoursLoading,
    String? Function()? hour,
    String? provider,
    bool? fullCar,
    String? fullGrade,
    String? Function()? sadadNumber,
    bool? error,
    String? Function()? couponCode,
    CouponResult? Function()? couponResult,
    bool? couponBusy,
  }) =>
      _PayState(
        phase: phase ?? this.phase,
        branches: branches ?? this.branches,
        branchId: branchId == null ? this.branchId : branchId(),
        date: date == null ? this.date : date(),
        hours: hours ?? this.hours,
        hoursLoading: hoursLoading ?? this.hoursLoading,
        hour: hour == null ? this.hour : hour(),
        provider: provider ?? this.provider,
        fullCar: fullCar ?? this.fullCar,
        fullGrade: fullGrade ?? this.fullGrade,
        sadadNumber: sadadNumber == null ? this.sadadNumber : sadadNumber(),
        error: error ?? this.error,
        couponCode: couponCode == null ? this.couponCode : couponCode(),
        couponResult:
            couponResult == null ? this.couponResult : couponResult(),
        couponBusy: couponBusy ?? this.couponBusy,
      );

  @override
  List<Object?> get props => [
        phase, branches, branchId, date, hours, hoursLoading, hour,
        provider, fullCar, fullGrade, sadadNumber, error,
        couponCode, couponResult, couponBusy,
      ];
}

final class _PayCubit extends Cubit<_PayState> {
  _PayCubit(this._repo,
      {required this.package, this.vin, this.vehicleLabel})
      : super(const _PayState()) {
    _load();
  }

  final ProtectionRepository _repo;
  final ProtectionPackage package;
  final String? vin;
  final String? vehicleLabel;

  bool get isTinting {
    final txt = '${package.nameEn} ${package.nameAr} '
            '${package.descriptionEn} ${package.descriptionAr}'
        .toLowerCase();
    return txt.contains('tint') || txt.contains('shad') || txt.contains('تظليل');
  }

  Future<void> _load() async {
    final branches = await _repo.branches();
    if (isClosed) return;
    emit(state.copyWith(
      branches: branches,
      branchId: () => branches.firstOrNull?.id,
    ));
  }

  void selectBranch(String? id) => emit(state.copyWith(branchId: () => id));
  void selectHour(String? h) => emit(state.copyWith(hour: () => h));
  void selectProvider(String p) => emit(state.copyWith(provider: p));
  void setFullCar(bool v) => emit(state.copyWith(fullCar: v));
  void setGrade(String g) => emit(state.copyWith(fullGrade: g));

  Future<void> selectDate(DateTime d) async {
    emit(state.copyWith(date: () => d, hour: () => null, hoursLoading: true));
    final hours = await _repo.hours(d);
    if (isClosed) return;
    emit(state.copyWith(hours: hours, hoursLoading: false));
  }

  /// Server-validated coupon for THIS package. Network failures /
  /// unavailable codes resolve to the quiet invalid result — never blocking.
  Future<void> applyCoupon(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty || state.couponBusy) return;
    emit(state.copyWith(couponBusy: true, couponResult: () => null));
    final lang = sl<LocaleCubit>().state.languageCode;
    final res = await _repo.validateCoupon(
      code: code,
      lang: lang,
      // The sheet knows the package + VIN/label only — no carCategory here.
      items: [
        (
          productId: package.id ?? '',
          price: package.price ?? 0,
          carCategory: null,
        ),
      ],
    );
    if (isClosed) return;
    emit(state.copyWith(
      couponBusy: false,
      couponResult: () => res,
      couponCode: () => code,
    ));
  }

  void clearCoupon() =>
      emit(state.copyWith(couponResult: () => null, couponCode: () => null));

  /// Display-only discount: min(server discountAmount, package price).
  double get couponDiscount {
    final res = state.couponResult;
    if (res == null || !res.valid) return 0;
    return res.discountAmount.clamp(0.0, package.price ?? 0).toDouble();
  }

  /// The website's buildNote(): tinting + VIN + slot + branch + vehicle,
  /// packed into the note the SP stores on the order.
  String _note(String lang) {
    final branch = state.branches
        .where((b) => b.id == state.branchId)
        .firstOrNull
        ?.name(lang);
    final lines = <String>[
      if (isTinting) 'Full car shading degree: ${state.fullGrade}',
      if ((vin ?? '').isNotEmpty) 'VIN: $vin',
      if (state.date != null)
        'Date: ${state.date!.toIso8601String().substring(0, 10)} ${state.hour ?? ''}',
      if (branch != null) 'Branch: $branch',
      if (vehicleLabel != null) 'Vehicle: $vehicleLabel',
      'Source: MobileApp',
    ];
    return lines.join('\n');
  }

  Future<void> submit(BuildContext context, String lang) async {
    final user = sl<AuthBloc>().state.user;
    final ok = state.branchId != null &&
        state.date != null &&
        (state.hour ?? '').isNotEmpty;
    if (!ok) {
      emit(state.copyWith(error: true));
      return;
    }
    emit(state.copyWith(phase: _PayPhase.busy, error: false));
    try {
      // Same contract as the website: backend creates the order + session.
      const callback = 'https://hjapp.payment/callback';
      final res = await sl<ApiClient>().post<Map<String, dynamic>>(
        '/api/app/payment/apply',
        body: {
          'payType': state.provider,
          'serviceList': package.id,
          'userId': user?.custId ?? '${user?.userId ?? ''}',
          'vin': vin,
          'note': _note(lang),
          'callbackUrl': callback,
          // Forward the code ONLY when the validate verdict was valid==true;
          // the backend recomputes the discount server-side.
          if ((state.couponResult?.valid ?? false) &&
              (state.couponCode ?? '').isNotEmpty)
            'couponCode': state.couponCode,
        },
      );
      if (isClosed) return;
      final j = res.data ?? const {};
      final url = (j['urlPaytabs'] ?? '').toString();
      final sadad = (j['sadadNumber'] ?? '').toString();
      // URL/Sadad win over messageError — legacy SPs put a success string in
      // MessageError even on success (website behavior).
      if (sadad.isNotEmpty && sadad != 'null') {
        emit(state.copyWith(
            phase: _PayPhase.sadad, sadadNumber: () => sadad));
      } else if (url.isNotEmpty && url != 'null') {
        if (!context.mounted) return;
        final paid = await Navigator.of(context, rootNavigator: true)
            .push<bool>(MaterialPageRoute(
          builder: (_) => _GatewayPage(
            url: url,
            callbackPrefix: callback,
            provider: state.provider,
            orderId: j['orderId']?.toString(),
          ),
        ));
        if (isClosed) return;
        emit(state.copyWith(
            phase: paid == true ? _PayPhase.success : _PayPhase.form));
      } else if ((j['status'] ?? '') == 'success') {
        emit(state.copyWith(phase: _PayPhase.success));
      } else {
        emit(state.copyWith(phase: _PayPhase.failed));
      }
    } on DioException {
      if (!isClosed) emit(state.copyWith(phase: _PayPhase.failed));
    }
  }
}

final class _PayView extends StatelessWidget {
  const _PayView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_PayCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    if (state.phase == _PayPhase.success) {
      return _Result(
          icon: Icons.check_circle_rounded,
          color: scheme.primary,
          text: t.paySuccess);
    }
    if (state.phase == _PayPhase.failed) {
      return _Result(
          icon: Icons.error_outline_rounded,
          color: scheme.error,
          text: t.payFailed);
    }
    if (state.phase == _PayPhase.sadad) {
      return _Result(
          icon: Icons.pin_outlined,
          color: scheme.primary,
          text: '${t.paySadad}\n${state.sadadNumber}');
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
            Text(t.protReservePay,
                style: TextStyle(
                    fontSize: context.rf(18), fontWeight: FontWeight.w800)),
            Text(
              '${cubit.package.name(lang)} — ',
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),
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
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.8)),
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
              label: Text(state.date == null
                  ? t.protPickDate
                  : state.date!.toIso8601String().substring(0, 10)),
            ),
            const SizedBox(height: 12),
            if (state.hoursLoading)
              const Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4)))
            else if (state.hours.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final h in state.hours)
                  ChoiceChip(
                    label: Text(h, textDirection: TextDirection.ltr),
                    selected: state.hour == h,
                    onSelected: (_) => cubit.selectHour(h),
                  ),
              ])
            else if (state.date != null)
              Text(t.protNoHours,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      color: scheme.onSurface.withValues(alpha: 0.55))),

            if (cubit.isTinting) ...[
              const SizedBox(height: 14),
              Text(t.payTinting,
                  style: TextStyle(
                      fontSize: context.rf(12.5),
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final g in ['0', '0.1', '0.2'])
                  ChoiceChip(
                    label: Text(g, textDirection: TextDirection.ltr),
                    selected: state.fullGrade == g,
                    onSelected: (_) => cubit.setGrade(g),
                  ),
              ]),
            ],

            const SizedBox(height: 14),
            Text(t.payMethodTitle,
                style: TextStyle(
                    fontSize: context.rf(12.5), fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final (id, name, tag) in [
              ('myfatoorah', 'MyFatoorah', t.payMyfatoorahTag),
              ('tabby', 'Tabby', t.payTabbyTag),
              ('tamara', 'Tamara', t.payTamaraTag),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: state.provider == id
                      ? scheme.primary.withValues(alpha: 0.07)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => cubit.selectProvider(id),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: state.provider == id
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.55),
                          width: state.provider == id ? 1.4 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          state.provider == id
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: state.provider == id
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                      fontSize: context.rf(13),
                                      fontWeight: FontWeight.w800)),
                              Text(tag,
                                  style: TextStyle(
                                      fontSize: context.rf(10.5),
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55))),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            // Coupon — server-validated; discount displayed only, forwarded
            // at pay time when valid.
            const _CouponBox(),
            const SizedBox(height: 12),
            if (state.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t.formCheckFields,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: scheme.error, fontSize: context.rf(12))),
              ),
            Builder(builder: (context) {
              const green = Color(0xFF1E9E5A);
              final price = cubit.package.price ?? 0;
              final discount = cubit.couponDiscount;
              final total =
                  (price - discount).clamp(0.0, double.infinity).toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (discount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.pcSubtotal,
                            style: TextStyle(
                                fontSize: context.rf(12),
                                fontWeight: FontWeight.w600)),
                        PriceText(
                            price: price,
                            currency: '',
                            contactForPrice: '',
                            fontSize: context.rf(12),
                            color: scheme.onSurface),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.cpnCouponDiscount,
                            style: TextStyle(
                                fontSize: context.rf(12),
                                fontWeight: FontWeight.w600,
                                color: green)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            Text('−',
                                style: TextStyle(
                                    fontSize: context.rf(12),
                                    fontWeight: FontWeight.w800,
                                    color: green)),
                            PriceText(
                                price: discount,
                                currency: '',
                                contactForPrice: '',
                                fontSize: context.rf(12),
                                color: green),
                          ],
                        ),
                      ],
                    ),
                    Divider(
                        height: context.rs(16),
                        color: scheme.outline.withValues(alpha: 0.35)),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.protTotal,
                          style: TextStyle(
                              fontSize: context.rf(13),
                              fontWeight: FontWeight.w800)),
                      PriceText(
                          price: total,
                          currency: '',
                          contactForPrice: '',
                          fontSize: context.rf(17)),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(
                      fontSize: context.rf(14), fontWeight: FontWeight.w800)),
              onPressed: state.phase == _PayPhase.busy
                  ? null
                  : () => context.read<_PayCubit>().submit(context, lang),
              child: state.phase == _PayPhase.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(t.payConfirm),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coupon input — the parts-cart pattern: pill TextField + Apply button with
/// an inline spinner; once valid, a green pill with the code + Remove.
final class _CouponBox extends StatefulWidget {
  const _CouponBox();

  @override
  State<_CouponBox> createState() => _CouponBoxState();
}

final class _CouponBoxState extends State<_CouponBox> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<_PayCubit>();
    final state = cubit.state;
    final res = state.couponResult;
    const green = Color(0xFF1E9E5A);

    if (res != null && res.valid) {
      return Container(
        padding: EdgeInsetsDirectional.fromSTEB(
            context.rs(14), context.rs(6), context.rs(6), context.rs(6)),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: green.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: green),
          SizedBox(width: context.rs(8)),
          Expanded(
            child: Text(
              state.couponCode ?? '',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              style: TextStyle(
                  fontSize: context.rf(12.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: green),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: green,
                minimumSize: const Size(44, 36),
                textStyle: TextStyle(
                    fontSize: context.rf(11.5), fontWeight: FontWeight.w800)),
            onPressed: cubit.clearCoupon,
            child: Text(t.cpnRemove),
          ),
        ]),
      );
    }

    // reason == 'unavailable' / network failure → quietly invalid: no red.
    final invalid = res != null && !res.valid && !res.unavailable;
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _code,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            TextInputFormatter.withFunction(
                (o, n) => n.copyWith(text: n.text.toUpperCase())),
          ],
          decoration: InputDecoration(
            hintText: t.pcCoupon,
            hintStyle: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.4)),
            prefixIcon: const Icon(Icons.sell_outlined, size: 17),
            isDense: true,
            errorText: invalid
                ? ((res.message ?? '').isNotEmpty
                    ? res.message
                    : t.pcCouponInvalid)
                : null,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
      SizedBox(width: context.rs(8)),
      FilledButton(
        style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(
                horizontal: context.rs(18), vertical: context.rs(11))),
        onPressed:
            state.couponBusy ? null : () => cubit.applyCoupon(_code.text),
        child: state.couponBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(t.pcApply),
      ),
    ]);
  }
}

final class _Result extends StatelessWidget {
  const _Result({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 52, color: color),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14.5, height: 1.6, fontWeight: FontWeight.w600)),
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

/// Full-screen gateway WebView. When the gateway redirects to the callback
/// URL, the app verifies with /status/{provider} and pops with the result —
/// exactly the website's /payment/callback page, app-side.
final class _GatewayPage extends StatelessWidget {
  const _GatewayPage({
    required this.url,
    required this.callbackPrefix,
    required this.provider,
    this.orderId,
  });

  final String url;
  final String callbackPrefix;
  final String provider;
  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.startsWith(callbackPrefix)) {
            _verify(context, request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(url));

    return Material(
      child: SafeArea(
        child: Column(children: [
          Row(children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Text(t.payGatewayTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 48),
          ]),
          Expanded(child: WebViewWidget(controller: controller)),
        ]),
      ),
    );
  }

  Future<void> _verify(BuildContext context, String callbackUrl) async {
    final params = Uri.tryParse(callbackUrl)?.queryParameters ?? const {};
    try {
      final res = await sl<ApiClient>().post<Map<String, dynamic>>(
        '/api/app/payment/status/$provider',
        body: {
          'salesOrderGuid':
              params['id'] ?? params['salesOrderGuid'] ?? params['GUID'],
          'orderId': params['orderId'] ?? params['order_id'] ?? orderId,
          'jobCardGuid': params['jobCardGUID'],
        },
      );
      final ok = (res.data?['status'] ?? '') == 'success';
      if (context.mounted) Navigator.of(context).pop(ok);
    } on DioException {
      if (context.mounted) Navigator.of(context).pop(false);
    }
  }
}
