import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/routes.dart';
import '../../../core/constants/api_paths.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../guest_home/presentation/guest_home_view.dart' show showLoginPrompt;
import '../../home/presentation/widgets/home_bits.dart';
import '../../online_store/data/online_store_repository.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/finance_lead_cubit.dart';
import '../domain/finance_models.dart';

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
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  minimumSize: const Size.fromHeight(48),
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
    final periods = [60, 48, 36, 24]
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
            _AbsherButton(onFilled: cubit.applyAbsher),
            const SizedBox(height: 14),

            if (cubit.custGroups.isNotEmpty) ...[
              AppDropdown<String>(
                label: t.finBuyingAs,
                value: state.custGroupId,
                items: [
                  for (final g in cubit.custGroups)
                    AppDropdownItem(
                        value: g.id ?? '',
                        label: g.name(lang),
                        icon: g.needIdentity
                            ? Icons.person_rounded
                            : Icons.business_rounded),
                ],
                onChanged: cubit.selectCustGroup,
              ),
              const SizedBox(height: 12),
            ],
            _Field(controller: cubit.name, label: t.finFullName),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.phone,
                label: t.formPhone,
                keyboard: TextInputType.phone,
                ltr: true),
            const SizedBox(height: 12),
            _Field(
                controller: cubit.identity,
                label: state.needIdentity ? t.formIdentity : t.finCommercialReg,
                keyboard: TextInputType.number,
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
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _Field(controller: cubit.note, label: t.finNotes, maxLines: 2),
            const SizedBox(height: 16),

            // ── المستندات المطلوبة ──
            const _DocsSection(),
            const SizedBox(height: 18),

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
                  minimumSize: const Size.fromHeight(50),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(
                      fontSize: context.rf(14), fontWeight: FontWeight.w800)),
              onPressed: state.phase == FinanceLeadPhase.busy
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

final class _AbsherButton extends StatelessWidget {
  const _AbsherButton({required this.onFilled});

  final void Function({String? fullName, String? mobile9, String? identityNo})
      onFilled;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        final data = await showModalBottomSheet<Map<String, String?>>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  minimumSize: const Size.fromHeight(48),
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

/* ─────────────────────── المستندات المطلوبة ─────────────────────── */

final class _DocsSection extends StatelessWidget {
  const _DocsSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<FinanceLeadCubit>();
    final state = cubit.state;
    final scheme = Theme.of(context).colorScheme;

    final docs = <(String, String)>[
      ('identityImage', state.needIdentity ? t.finIdDoc : t.finCommercialReg),
      ('license', t.finLicenseDoc),
      ('salaryDefinitionLetter', t.finSalaryDoc),
      if (state.workType == 'private') ('insurance', t.finInsuranceDoc),
      ('accountStatement', t.finStatementDoc),
    ];

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.finDocs,
              style: TextStyle(
                  fontSize: context.rf(13.5), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(3)),
          Text(t.finDocsHint,
              style: TextStyle(
                  fontSize: context.rf(10.5),
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.55))),
          SizedBox(height: context.rs(11)),
          // جهة العمل segmented toggle.
          Text(t.finWorkSector,
              style: TextStyle(
                  fontSize: context.rf(11),
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
          SizedBox(height: context.rs(6)),
          Row(
            children: [
              for (final (v, label) in [
                ('private', t.finPrivate),
                ('governmental', t.finGov),
              ]) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => cubit.setWorkType(v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: context.rs(9)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: state.workType == v
                            ? scheme.primary
                            : scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.workType == v
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: context.rf(11.5),
                          fontWeight: FontWeight.w800,
                          color: state.workType == v
                              ? scheme.onPrimary
                              : scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                if (v == 'private') SizedBox(width: context.rs(8)),
              ],
            ],
          ),
          SizedBox(height: context.rs(12)),
          for (final (kind, label) in docs)
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(8)),
              child: _DocRow(kind: kind, label: label),
            ),
        ],
      ),
    );
  }
}

final class _DocRow extends StatelessWidget {
  const _DocRow({required this.kind, required this.label});

  final String kind;
  final String label;

  Future<void> _pick(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final cubit = context.read<FinanceLeadCubit>();
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 4 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.finFileTooBig)));
      }
      return;
    }
    cubit.setDoc(kind, base64Encode(bytes), picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<FinanceLeadCubit>();
    final attached = (cubit.state.docs[kind] ?? '').isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(12), vertical: context.rs(9)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: attached
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outline.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            attached
                ? Icons.check_circle_rounded
                : Icons.description_outlined,
            size: 18,
            color: attached
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.4),
          ),
          SizedBox(width: context.rs(9)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        fontWeight: FontWeight.w700)),
                if (attached)
                  Text(
                    cubit.state.docNames[kind] ?? t.finUploaded,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(9.5),
                        color: scheme.primary),
                  ),
              ],
            ),
          ),
          if (attached)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => cubit.setDoc(kind, null, null),
              icon: Icon(Icons.close_rounded,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            )
          else
            TextButton.icon(
              onPressed: () => _pick(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: scheme.primary,
              ),
              icon: const Icon(Icons.upload_rounded, size: 15),
              label: Text(t.finUpload,
                  style: TextStyle(
                      fontSize: context.rf(11),
                      fontWeight: FontWeight.w800)),
            ),
        ],
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
