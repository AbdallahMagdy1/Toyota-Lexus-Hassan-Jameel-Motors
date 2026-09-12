import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/constants/api_paths.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../guest_home/presentation/guest_home_view.dart' show showLoginPrompt;
import '../../home/presentation/widgets/home_bits.dart';
import '../../online_store/data/online_store_repository.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/finance_lead_cubit.dart';
import '../domain/finance_models.dart';
import 'finance_docs_section.dart';

/// Opens the finance application — the website FinanceRequestModal as a
/// mobile sheet: live installment panel, Absher autofill, documents upload.
/// Applying is a registered-only action in the app: guests get the prompt.
void showFinanceLeadSheet(
  BuildContext context, {
  required FinanceBank bank,
  required FinanceVehicle car,
  required List<FinanceCustGroup> custGroups,
  int? initialPeriod,
}) {
  final auth = sl<AuthBloc>().state;
  if (auth.status != AuthStatus.authenticated) {
    showLoginPrompt(context);
    return;
  }
  final lang = sl<LocaleCubit>().state.languageCode;
  showAppModalSheet<void>(
    context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => BlocProvider(
      create: (_) => FinanceLeadCubit(
        bank: bank,
        car: car,
        onlineRepo: sl<OnlineStoreRepository>(),
        user: auth.user,
        lang: lang,
        custGroups: custGroups,
        initialPeriod: initialPeriod,
      ),
      child: const _LeadView(),
    ),
  );
}

final class _LeadView extends StatelessWidget {
  const _LeadView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<FinanceLeadCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    if (state.phase == FinanceLeadPhase.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 52, color: scheme.primary),
            const SizedBox(height: 14),
            Text(t.finReqSent,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15.5, height: 1.5, fontWeight: FontWeight.w800)),
            if ((state.reference ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${t.finReqRef} · ${state.reference}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurface.withValues(alpha: 0.6))),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder()),
              onPressed: () {
                Navigator.of(context).pop();
                context.go(Routes.financeRequests);
              },
              icon: const Icon(Icons.track_changes_rounded, size: 18),
              label: Text(t.finTrackCta),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.commonDone),
            ),
          ],
        ),
      );
    }

    final est = cubit.estimate;
    // Website order: 24 / 36 / 48 / 60, capped by the bank's max period.
    final periods = [24, 36, 48, 60]
        .where((p) => p <= cubit.bank.maxFinancePeriod)
        .toList();

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
            Row(
              children: [
                Container(
                  width: context.rs(42),
                  height: context.rs(42),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.directions_car_filled_rounded,
                      color: scheme.primary, size: 22),
                ),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.finReqTitle,
                          style: TextStyle(
                              fontSize: context.rf(17),
                              fontWeight: FontWeight.w800)),
                      Text(
                        '${cubit.car.group(lang)} ${cubit.car.year ?? ''} · ${cubit.bank.name(lang)}',
                        style: TextStyle(
                            fontSize: context.rf(11),
                            color: scheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                if ((cubit.bank.logo ?? '').isNotEmpty)
                  SizedBox(
                    width: context.rs(38),
                    height: context.rs(38),
                    child: HomeImage(
                        url: cubit.bank.logo,
                        fit: BoxFit.contain,
                        logicalWidth: 40),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Installment panel: monthly hero + 4 stat tiles + period chips
            Container(
              padding: EdgeInsets.all(context.rs(15)),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.finMonthly,
                      style: TextStyle(
                          fontSize: context.rf(11),
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PriceText(
                          price: est.monthly.roundToDouble(),
                          currency: '',
                          contactForPrice: '',
                          fontSize: context.rf(26)),
                      SizedBox(width: context.rs(4)),
                      Padding(
                        padding: EdgeInsets.only(bottom: context.rs(4)),
                        child: Text(t.finPerMonth,
                            style: TextStyle(
                                fontSize: context.rf(11),
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55))),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rs(12)),
                  Row(children: [
                    _Stat(label: t.finEstAdvance, value: est.firstPay),
                    SizedBox(width: context.rs(8)),
                    _Stat(label: t.finLastPay, value: est.lastPay),
                  ]),
                  SizedBox(height: context.rs(8)),
                  Row(children: [
                    _Stat(label: t.finFinalPrice, value: est.total),
                    SizedBox(width: context.rs(8)),
                    _Stat(label: t.finCashPrice, value: cubit.price),
                  ]),
                  SizedBox(height: context.rs(12)),
                  Text(t.finPeriodTitle,
                      style: TextStyle(
                          fontSize: context.rf(11),
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                  SizedBox(height: context.rs(7)),
                  Row(
                    children: [
                      for (final p in periods) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => cubit.selectPeriod(p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.symmetric(
                                  vertical: context.rs(9)),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: state.period == p
                                    ? scheme.primary
                                    : scheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: state.period == p
                                      ? scheme.primary
                                      : scheme.outline
                                          .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                '$p',
                                style: TextStyle(
                                  fontSize: context.rf(13),
                                  fontWeight: FontWeight.w800,
                                  color: state.period == p
                                      ? scheme.onPrimary
                                      : scheme.onSurface
                                          .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (p != periods.last) SizedBox(width: context.rs(7)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── تعبئة البيانات من أبشر ──
            AbsherAutofillButton(onFilled: cubit.applyAbsher),
            const SizedBox(height: 14),

            // Website FinanceRequestModal: NO "Buying as" selector — applicants
            // are individuals (identity number).
            _Field(
                controller: cubit.identity,
                label: t.formIdentity,
                keyboard: TextInputType.number,
                ltr: true),
            const SizedBox(height: 12),
            _Field(controller: cubit.name, label: t.finFullName),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.phone,
                label: t.formPhone,
                keyboard: TextInputType.phone,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.income,
                label: t.finIncome,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.email,
                label: t.formEmailOptional,
                keyboard: TextInputType.emailAddress,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.advanceCtrl,
                label: t.finFirstPayOptional,
                keyboard: TextInputType.number,
                // Website placeholder: the bank's minimum advance payment.
                hint: formatPrice(est.minFirstPay)),
            const SizedBox(height: 12),
            _Field(controller: cubit.note, label: t.finNotes, maxLines: 2),
            const SizedBox(height: 16),

            // ── المستندات المطلوبة (website FinanceDocUploads) ──
            FinanceDocsSection(
              needIdentity: true,
              sector: state.workType,
              onSector: cubit.setWorkType,
              docs: state.docs,
              docNames: state.docNames,
              onDoc: cubit.setDoc,
            ),
            const SizedBox(height: 12),

            // Privacy consent — gates submit like the website PrivacyConsent.
            Row(children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: state.accepted,
                  onChanged: (v) => cubit.setAccepted(v ?? false),
                ),
              ),
              Expanded(
                child: Text(t.cmpConsent,
                    style: TextStyle(
                        fontSize: context.rf(10.5),
                        height: 1.45,
                        color: scheme.onSurface.withValues(alpha: 0.65))),
              ),
            ]),
            const SizedBox(height: 10),

            if (state.phase == FinanceLeadPhase.failed || state.error)
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
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(
                      fontSize: context.rf(14), fontWeight: FontWeight.w800)),
              onPressed: state.phase == FinanceLeadPhase.busy || !state.accepted
                  ? null
                  : () => context.read<FinanceLeadCubit>().submit(),
              child: state.phase == FinanceLeadPhase.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(t.finSendReq),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.rs(11), vertical: context.rs(9)),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: context.rf(10),
                    color: scheme.onSurface.withValues(alpha: 0.55))),
            SizedBox(height: context.rs(2)),
            PriceText(
                price: value.roundToDouble(),
                currency: '',
                contactForPrice: '',
                fontSize: context.rf(13.5),
                color: scheme.onSurface),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────── Absher autofill (two-step OTP) ───────────────────── */

/// Absher/Yakeen autofill entry — public so the online-store checkout forms
/// reuse it (website AbsherAutofill parity). Returns the verified
/// {fullName, mobile9, identityNo} via [onFilled].
final class AbsherAutofillButton extends StatelessWidget {
  const AbsherAutofillButton({super.key, required this.onFilled});

  final void Function({String? fullName, String? mobile9, String? identityNo})
      onFilled;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        final data = await showAppModalSheet<Map<String, String?>>(
          context,
          backgroundColor: scheme.surface,
          builder: (_) => const _AbsherSheet(),
        );
        if (data != null) {
          onFilled(
            fullName: data['fullName'],
            mobile9: data['mobile'],
            identityNo: data['identity'],
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.finAbsherFilled)));
          }
        }
      },
      child: Ink(
        padding: EdgeInsets.symmetric(vertical: context.rs(11)),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_rounded, size: 17, color: scheme.primary),
            SizedBox(width: context.rs(7)),
            Text(
              t.finAbsher,
              style: TextStyle(
                  fontSize: context.rf(12.5),
                  fontWeight: FontWeight.w800,
                  color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AbsherSheet extends StatefulWidget {
  const _AbsherSheet();

  @override
  State<_AbsherSheet> createState() => _AbsherSheetState();
}

final class _AbsherSheetState extends State<_AbsherSheet> {
  final _id = TextEditingController();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  DateTime _birth = DateTime(1995);
  String? _guid;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _mobile.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final id = int.tryParse(_id.text.trim());
    var mob = _mobile.text.trim().replaceAll(RegExp(r'\D'), '');
    if (mob.startsWith('966')) mob = mob.substring(3);
    if (mob.startsWith('0')) mob = mob.substring(1);
    if (id == null || mob.length != 9) {
      setState(() => _error = AppLocalizations.of(context).formCheckFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final lang = sl<LocaleCubit>().state.languageCode;
      final res = await sl<ApiClient>().post<Map<String, dynamic>>(
        ApiPaths.absher,
        body: {
          'actionType': 3,
          'insertIdentity': id,
          'insertMobile': mob,
          'insertDateOfBirth':
              '${_birth.year}-${_birth.month.toString().padLeft(2, '0')}',
          'insertLanguage': lang,
          'insertCreatedUser': 'MobileAppAutofill',
        },
      );
      final ok = res.data?['ok'] == true;
      final guid = res.data?['guid']?.toString();
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (ok && (guid ?? '').isNotEmpty) {
          _guid = guid;
        } else {
          _error = res.data?['error']?.toString() ??
              AppLocalizations.of(context).offersSubmitFailed;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context).offersSubmitFailed;
      });
    }
  }

  Future<void> _confirm() async {
    final otp = int.tryParse(_otp.text.trim());
    if (otp == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await sl<ApiClient>().post<Map<String, dynamic>>(
        '/api/user/absher/fetch',
        body: {'guid': _guid, 'otp': otp},
      );
      final ok = res.data?['ok'] == true;
      final d = res.data?['data'] as Map<String, dynamic>?;
      if (!mounted) return;
      if (ok && d != null) {
        final name = (d['fullNameAr'] ?? '').toString().trim().isNotEmpty
            ? d['fullNameAr'].toString()
            : [
                d['firstNameAr'],
                d['fatherNameAr'],
                d['grandFatherNameAr'],
                d['familyNameAr'],
              ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
        Navigator.of(context).pop({
          'fullName': name,
          'mobile': d['mobile']?.toString(),
          'identity': d['identity']?.toString(),
        });
      } else {
        setState(() {
          _busy = false;
          _error = res.data?['error']?.toString() ??
              AppLocalizations.of(context).offersSubmitFailed;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context).offersSubmitFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final otpStage = _guid != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: 12),
            Text(t.finAbsher,
                style: TextStyle(
                    fontSize: context.rf(16), fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            if (!otpStage) ...[
              _Field(
                  controller: _id,
                  label: t.finAbsherId,
                  keyboard: TextInputType.number,
                  ltr: true),
              const SizedBox(height: 12),
              _Field(
                  controller: _mobile,
                  label: t.finAbsherMobile,
                  keyboard: TextInputType.phone,
                  ltr: true),
              const SizedBox(height: 12),
              // Birth month picker (Absher needs YYYY-MM).
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birth,
                    firstDate: DateTime(1930),
                    lastDate: DateTime.now(),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) setState(() => _birth = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.finAbsherBirth,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  child: Text(
                    '${_birth.year}-${_birth.month.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: context.rf(13.5)),
                  ),
                ),
              ),
            ] else
              _Field(
                  controller: _otp,
                  label: t.finAbsherOtp,
                  keyboard: TextInputType.number,
                  ltr: true),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.error, fontSize: context.rf(11.5))),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder()),
              onPressed: _busy ? null : (otpStage ? _confirm : _send),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2))
                  : Text(otpStage ? t.finAbsherConfirm : t.finAbsherSend),
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
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final int maxLines;
  final bool ltr;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      textDirection: ltr ? TextDirection.ltr : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
