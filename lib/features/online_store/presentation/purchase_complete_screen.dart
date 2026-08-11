import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile_models.dart';
import '../../protection/data/protection_repository.dart';
import '../../protection/domain/protection_models.dart';
import '../data/online_store_repository.dart';
import '../domain/online_store_models.dart';

/// POST-DEPOSIT car-purchase continuation — the website's
/// /car/complete/{orderGuid} (CarPurchaseCompleteView) with FULL step parity:
///   0. Protection & Shading  (protection-by-model packages)
///   1. Contract & signature  (Site_Car_Payment init + Absher OTP signature)
///   2. Delivery scheduling   (schedule row → date → slot → book)
///   3. Remaining payment     (Site_Car_Payment charge → gateway / SADAD)
/// Steps unlock progressively exactly like the website's in-memory ladder;
/// test-group cars ('test' product group) skip Absher + the gateway.
final class PurchaseCompleteScreen extends StatefulWidget {
  const PurchaseCompleteScreen({super.key, required this.orderGuid});

  final String orderGuid;

  /// Full-screen push over everything (root navigator), like the payment
  /// gateway pages.
  static Future<void> open(BuildContext context, String orderGuid) =>
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => PurchaseCompleteScreen(orderGuid: orderGuid),
      ));

  @override
  State<PurchaseCompleteScreen> createState() => _PurchaseCompleteScreenState();
}

/* ── Case-insensitive dynamic-row readers (the procs' column casing varies) ── */
String _rowStr(Map<String, dynamic>? row, List<String> keys) {
  if (row == null) return '';
  for (final k in keys) {
    for (final e in row.entries) {
      if (e.key.toLowerCase() == k.toLowerCase() && e.value != null) {
        final s = '${e.value}';
        if (s.isNotEmpty && s != 'null') return s;
      }
    }
  }
  return '';
}

bool _rowTruthy(Map<String, dynamic>? row, List<String> keys) {
  final v = _rowStr(row, keys).toLowerCase();
  return v == 'true' || v == '1';
}

/// "16:00:00" → "16:00".
String _hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

final class _PurchaseCompleteScreenState extends State<PurchaseCompleteScreen> {
  bool _loading = true;
  CarReservation? _reservation;

  int _active = 0; // 0 protection | 1 contract | 2 delivery | 3 payment
  bool _finished = false; // remaining payment confirmed

  bool _packagesLoading = false;
  List<ProtectionPackage> _packages = const [];
  final Set<String> _selected = {};

  // The REAL sales order created by the contract step (delivery + payment).
  ({String guid, String id})? _salesOrder;

  bool get _isTest =>
      (_reservation?.productGroupId ?? '').toLowerCase() == 'test';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await OnlineStoreRepository(sl<ApiClient>())
        .reservationByGuid(widget.orderGuid);
    if (!mounted) return;
    setState(() {
      _reservation = r;
      _loading = false;
    });
    if (r == null) return;
    // Keep the continuation reachable later (store banner).
    final lang = Localizations.localeOf(context).languageCode;
    await sl<LocalStore>().setPendingCarPurchase(
        guid: widget.orderGuid, carName: r.name(lang));
    // Protection & Shading catalog — same resolution the website's
    // fetchProtectionByModel uses (type + brand bucket).
    final type = (r.type ?? '').trim();
    if (type.isEmpty) return;
    if (!mounted) return;
    setState(() => _packagesLoading = true);
    final res = await ProtectionRepository(sl<ApiClient>())
        .protectionByModel(type, r.protectionBrandId);
    if (!mounted) return;
    setState(() {
      _packages = res?.services ?? const [];
      _packagesLoading = false;
    });
  }

  List<ProtectionPackage> get _chosen =>
      _packages.where((p) => _selected.contains(p.id ?? '')).toList();

  double get _chosenTotal => _chosen.fold(0, (sum, p) => sum + (p.price ?? 0));

  Future<void> _onPurchaseFinished() async {
    await sl<LocalStore>().clearPendingCarPurchase();
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final user = sl<AuthBloc>().state.user;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(8)),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      t.cpcTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: context.rf(16), fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : user == null
                      ? _SignInGate()
                      : _reservation == null
                          ? _NotFound()
                          : _body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final r = _reservation!;
    const green = Color(0xFF18A957);

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(6), context.rs(20), context.rs(28)),
      children: [
        // ── Green "deposit received" banner ──
        Container(
          padding: EdgeInsets.all(context.rs(12)),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: green.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, size: 20, color: green),
              SizedBox(width: context.rs(8)),
              Expanded(
                child: Text(
                  t.cpcDepositBanner,
                  style: TextStyle(
                    fontSize: context.rf(12),
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: green,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(12)),

        // ── Car card: image + name + VIN + status ──
        Container(
          padding: EdgeInsets.all(context.rs(13)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              if ((r.image ?? '').isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: context.rs(92),
                    height: context.rs(64),
                    child: HomeImage(
                        url: r.image, fit: BoxFit.contain, logicalWidth: 92),
                  ),
                ),
                SizedBox(width: context.rs(12)),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name(lang).isEmpty ? t.cpcYourCar : r.name(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(14),
                          fontWeight: FontWeight.w800),
                    ),
                    if ((r.sn ?? '').isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: context.rs(2)),
                        child: Text(
                          'VIN: ${r.sn}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: context.rf(10.5),
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    if (r.status(lang).isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: context.rs(5)),
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(8), vertical: context.rs(2)),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          r.status(lang),
                          style: TextStyle(
                            fontSize: context.rf(10),
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(16)),

        // ── 4-step rail ──
        _StepsRail(active: _active, allDone: _finished),
        SizedBox(height: context.rs(16)),

        // ── Active step body (website's in-memory ladder) ──
        if (_active == 0)
          _protectionCard(context)
        else if (_active == 1)
          _ContractStep(
            key: const ValueKey('contract'),
            reservation: r,
            chosen: _chosen,
            existingOrder: _salesOrder,
            isTest: _isTest,
            onBack: () => setState(() => _active = 0),
            onSigned: (order) => setState(() {
              _salesOrder = order;
              _active = 2;
            }),
          )
        else if (_active == 2)
          _DeliveryStep(
            key: const ValueKey('delivery'),
            reservation: r,
            salesOrderId: _salesOrder?.id ?? '',
            onBack: () => setState(() => _active = 1),
            onDone: () => setState(() => _active = 3),
          )
        else
          _PaymentStep(
            key: const ValueKey('payment'),
            reservation: r,
            salesOrder: _salesOrder,
            chosen: _chosen,
            isTest: _isTest,
            onBack: () => setState(() => _active = 2),
            onFinished: _onPurchaseFinished,
          ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  /* ── Step 0: Protection & Shading ── */
  Widget _protectionCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cpcStepProtection,
              style: TextStyle(
                  fontSize: context.rf(14), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(4)),
          Text(
            t.cpcProtectionHint,
            style: TextStyle(
              fontSize: context.rf(11.5),
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: context.rs(12)),
          if (_packagesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_packages.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(14)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.5)),
              ),
              child: Text(
                t.cpcNoPackages,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.rf(11.5),
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            for (final p in _packages) _packageTile(context, p),
          SizedBox(height: context.rs(10)),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.5)),
          SizedBox(height: context.rs(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  _chosen.isEmpty
                      ? t.cpcNoneSelected
                      : t.cpcSelectedCount(_chosen.length),
                  style: TextStyle(
                    fontSize: context.rf(12),
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              if (_chosenTotal > 0)
                Text.rich(
                  TextSpan(children: [
                    riyalSpan(fontSize: context.rf(15), color: scheme.primary),
                    TextSpan(text: formatPrice(_chosenTotal)),
                  ]),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: context.rf(15),
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: context.rs(12)),
          FilledButton(
            onPressed: () => setState(() => _active = 1),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(
                _chosen.isEmpty ? t.cpcContinueWithout : t.cpcConfirmSelection),
          ),
        ],
      ),
    );
  }

  Widget _packageTile(BuildContext context, ProtectionPackage p) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final id = p.id ?? '';
    final on = _selected.contains(id);

    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(9)),
      child: Material(
        color: on ? scheme.primary.withValues(alpha: 0.07) : scheme.surface,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: id.isEmpty
              ? null
              : () => setState(() {
                    on ? _selected.remove(id) : _selected.add(id);
                  }),
          child: Container(
            padding: EdgeInsets.all(context.rs(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: on
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.6),
                width: on ? 1.6 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.rs(20),
                  height: context.rs(20),
                  margin: EdgeInsets.only(top: context.rs(1)),
                  decoration: BoxDecoration(
                    color: on ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: on
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                  child: on
                      ? Icon(Icons.check_rounded,
                          size: 14, color: scheme.onPrimary)
                      : null,
                ),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name(lang),
                        style: TextStyle(
                            fontSize: context.rf(12.5),
                            fontWeight: FontWeight.w700),
                      ),
                      if (p.description(lang).isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.rs(2)),
                          child: Text(
                            p.description(lang),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.rf(10.5),
                              height: 1.4,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: context.rs(8)),
                (p.price ?? 0) > 0
                    ? Text.rich(
                        TextSpan(children: [
                          riyalSpan(
                              fontSize: context.rf(12.5),
                              color: scheme.primary),
                          TextSpan(text: formatPrice(p.price!)),
                        ]),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: context.rf(12.5),
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: scheme.primary,
                        ),
                      )
                    : Text(t.cpcByChoice,
                        style: TextStyle(
                            fontSize: context.rf(10.5),
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ═══════════════ Step 1: Contract & signature (website Step C) ═══════════════ */

final class _ContractStep extends StatefulWidget {
  const _ContractStep({
    super.key,
    required this.reservation,
    required this.chosen,
    required this.existingOrder,
    required this.isTest,
    required this.onBack,
    required this.onSigned,
  });

  final CarReservation reservation;
  final List<ProtectionPackage> chosen;
  final ({String guid, String id})? existingOrder;
  final bool isTest;
  final VoidCallback onBack;
  final ValueChanged<({String guid, String id})> onSigned;

  @override
  State<_ContractStep> createState() => _ContractStepState();
}

final class _ContractStepState extends State<_ContractStep> {
  final _repo = OnlineStoreRepository(sl<ApiClient>());
  final _otp = TextEditingController();

  bool _preparing = true;
  bool _contractReady = false;
  String _orderGuid = '';
  String _orderId = '';
  String? _error;

  bool _agreed = false;
  bool _signSent = false;
  bool _signing = false;

  /// A sales order carried back from a later step means the contract was
  /// already created AND signed this session — never re-init or re-sign.
  bool get _alreadySigned => widget.existingOrder != null;

  ProfileUser? _profile;

  double get _netSale =>
      widget.reservation.total ?? widget.reservation.salePrice ?? 0;
  double get _deposit => widget.reservation.reqDownPayment ?? 0;
  double get _accTotal =>
      widget.chosen.fold(0, (s, p) => s + (p.price ?? 0));

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // The signed-in user's FULL record — identity (Absher signature), city and
    // address feed the order payload like the website's useAuth().user.
    final auth = sl<AuthBloc>().state.user;
    if (auth != null) {
      _profile = await ProfileRepository(sl(), sl()).fetchUser(auth.guid);
    }
    if (!mounted) return;
    final t = AppLocalizations.of(context);

    // Sales order already created earlier in this session → don't re-init
    // (Site_Car_Payment would create a duplicate order); just re-confirm the
    // contract PDF is reachable.
    if (widget.existingOrder != null) {
      _orderGuid = widget.existingOrder!.guid;
      _orderId = widget.existingOrder!.id;
      final b64 = await _repo
          .carsoAgreementPdf(OnlineStoreRepository.contractPdfUrl(_orderGuid));
      if (!mounted) return;
      setState(() {
        _contractReady = b64 != null;
        _preparing = false;
      });
      return;
    }

    // ---- create the REAL order from the reservation draft (website payload,
    // field-for-field: InitializeOrder=true + OrderDraftID) ----
    final r = widget.reservation;
    final lang = Localizations.localeOf(context).languageCode;
    final accessoryIds = widget.chosen
        .map((p) => p.id)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(',');
    final payload = <String, dynamic>{
      'URL': 'https://hjapp.payment/carso',
      'Lang': lang,
      'Product': [
        {
          'id': r.productId,
          'quantity': 1,
          'colorID': r.colorId,
          'Type': 1,
          'price': _netSale,
          'CartID': null,
          'CostShipping': 0,
          'VIN': r.sn,
          'MiniDownPayment': _deposit,
        }
      ],
      'Accessories': accessoryIds.isEmpty ? null : accessoryIds,
      'NoteAccessories': '',
      'UserID': _profile?.userId ?? auth?.userId,
      'City': _profile?.cityId,
      'DelivaryAddress': _profile?.address,
      'NotificationWhatsApp': 0,
      'customerDetails': {'IP': ''},
      'DataAmount': {
        'FinalTotal': _netSale + _accTotal,
        'AmountShipping': 0,
        'SubAmountTotal': _netSale,
        'TotalTaxAmount': 0,
        'TotalDiscount': 0,
        'MiniDownPayment': _deposit,
      },
      'PaymentAmount': _deposit,
      'TypePaymnet': {
        'IsReservation': false,
        'IsPayment': true,
        'PaymnetTypeID': 'Cash',
        'MethodPayment': 'Myfatoorah&SADAD',
      },
      'DeliveryType': {'ByBranch': false, 'ByLocation': true},
      'DeliveryData': {'InfoBranch': null, 'InfoLocation': _profile?.cityId},
      'CobonData': {'Code': null, 'ID': null, 'Amount': null},
      'RefrancePayment': null,
      'status': 1,
      'InitializeOrder': true,
      'InitializeOrderID': null,
      'OrderDraftID': r.orderGuid,
    };

    final rows = await _repo.carsoCarPayment(payload);
    if (!mounted) return;
    Map<String, dynamic>? row;
    for (final x in rows) {
      if (_rowStr(x, ['OrderGUID']).isNotEmpty) {
        row = x;
        break;
      }
    }
    row ??= rows.isEmpty ? null : rows.first;
    final og = _rowStr(row, ['OrderGUID']);
    final oid = _rowStr(row, ['OrderId', 'OrderID']);
    final msg = _rowStr(row, ['MessageError']);
    if (og.isEmpty) {
      setState(() {
        _error = msg.isNotEmpty ? msg : t.cpcContractFailed;
        _preparing = false;
      });
      return;
    }
    _orderGuid = og;
    _orderId = oid;
    final b64 = await _repo
        .carsoAgreementPdf(OnlineStoreRepository.contractPdfUrl(og));
    if (!mounted) return;
    setState(() {
      _contractReady = b64 != null;
      _preparing = false;
    });
  }

  Future<void> _sendSign() async {
    final t = AppLocalizations.of(context);
    if (!_agreed) {
      setState(() => _error = t.cpcAgreeFirst);
      return;
    }
    final identity = (_profile?.identity ?? '').trim();
    if (!RegExp(r'^\d{10}$').hasMatch(identity)) {
      setState(() => _error = t.cpcNoIdentity);
      return;
    }
    setState(() {
      _error = null;
      _signing = true;
    });
    final lang = Localizations.localeOf(context).languageCode;
    final res = await _repo.carsoSignSend(identity, lang);
    if (!mounted) return;
    final ok = _rowStr(res, ['status']) == '1' ||
        _rowStr(res, ['verificationCode']).isNotEmpty;
    setState(() {
      _signing = false;
      if (ok) {
        _signSent = true;
      } else {
        _error = t.cpcSignSendFailed;
      }
    });
  }

  Future<void> _verifySign() async {
    final t = AppLocalizations.of(context);
    final identity = (_profile?.identity ?? '').trim();
    if (_otp.text.trim().length < 4) return;
    setState(() {
      _signing = true;
      _error = null;
    });
    final res = await _repo.carsoSignVerify(identity, _otp.text.trim());
    if (!mounted) return;
    final status = _rowStr(res, ['status']);
    final ok = status == '1' ||
        _rowStr(res, ['isMatched']) == '1' ||
        _rowStr(res, ['Matched']) == '1' ||
        status.toLowerCase() == 'success';
    setState(() => _signing = false);
    if (ok) {
      widget.onSigned((guid: _orderGuid, id: _orderId));
    } else {
      setState(() => _error = t.cpcSignInvalidOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final canSign = _contractReady && _agreed && _orderGuid.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cpcContractTitle,
              style: TextStyle(
                  fontSize: context.rf(14), fontWeight: FontWeight.w800)),
          if (widget.chosen.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: context.rs(3)),
              child: Text(
                '${t.cpcAddons} ${widget.chosen.map((p) => p.name(lang)).join('، ')}',
                style: TextStyle(
                  fontSize: context.rf(10.5),
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: context.rs(10)),
              padding: EdgeInsets.all(context.rs(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFE5484D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFE5484D), fontSize: 12)),
            ),
          SizedBox(height: context.rs(12)),

          if (_preparing)
            Container(
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2)),
                SizedBox(width: context.rs(12)),
                Expanded(
                  child: Text(t.cpcContractPreparing,
                      style:
                          TextStyle(fontSize: context.rf(11.5), height: 1.5)),
                ),
              ]),
            )
          else if (_orderGuid.isNotEmpty) ...[
            // Contract card — the PDF opens externally (no inline PDF
            // renderer on mobile; the ERP report renders in the browser).
            Container(
              padding: EdgeInsets.all(context.rs(13)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                Icon(Icons.picture_as_pdf_outlined,
                    size: 22, color: scheme.primary),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.cpcContractReady,
                          style: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w700)),
                      Text(_orderId,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: context.rf(10),
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          )),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(
                        OnlineStoreRepository.contractPdfUrl(_orderGuid)),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(t.cpcViewContract,
                      style: TextStyle(
                          fontSize: context.rf(11),
                          fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
            SizedBox(height: context.rs(12)),

            // Agree checkbox.
            Row(children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                ),
              ),
              Expanded(
                child: Text(t.cpcAgreeContract,
                    style: TextStyle(fontSize: context.rf(11.5))),
              ),
            ]),
            SizedBox(height: context.rs(10)),

            if (_alreadySigned)
              FilledButton(
                onPressed: () =>
                    widget.onSigned((guid: _orderGuid, id: _orderId)),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: Text(t.cpcContinue),
              )
            else if (widget.isTest) ...[
              // TEST-MODE parity: sign without Absher.
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: context.rs(10)),
                padding: EdgeInsets.all(context.rs(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFFB47D12).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(t.cpcTestModeSign,
                    style: TextStyle(
                        fontSize: context.rf(11),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB47D12))),
              ),
              Row(children: [
                OutlinedButton(
                    onPressed: widget.onBack, child: Text(t.cpcBack)),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: FilledButton(
                    onPressed: canSign
                        ? () =>
                            widget.onSigned((guid: _orderGuid, id: _orderId))
                        : null,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: Text(t.cpcSignTest),
                  ),
                ),
              ]),
            ] else if (!_signSent)
              Row(children: [
                OutlinedButton(
                    onPressed: widget.onBack, child: Text(t.cpcBack)),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canSign && !_signing ? _sendSign : null,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    icon: _signing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.2))
                        : const Icon(Icons.verified_user_outlined, size: 18),
                    label: Text(t.cpcSignAbsher),
                  ),
                ),
              ])
            else ...[
              // Absher OTP entry.
              Container(
                padding: EdgeInsets.all(context.rs(12)),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.cpcSignOtpHint,
                        style: TextStyle(
                            fontSize: context.rf(11.5),
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: context.rs(10)),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                              fontSize: context.rf(16),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8),
                          decoration: const InputDecoration(
                              counterText: '', hintText: '••••'),
                        ),
                      ),
                      SizedBox(width: context.rs(10)),
                      FilledButton(
                        onPressed: _otp.text.trim().length >= 4 && !_signing
                            ? _verifySign
                            : null,
                        child: _signing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.2))
                            : Text(t.cpcSignConfirm),
                      ),
                    ]),
                    TextButton(
                      onPressed: _signing ? null : _sendSign,
                      child: Text(t.cpcSignResend,
                          style: TextStyle(fontSize: context.rf(11))),
                    ),
                  ],
                ),
              ),
            ],
          ] else
            OutlinedButton(onPressed: widget.onBack, child: Text(t.cpcBack)),
        ],
      ),
    );
  }
}

/* ═══════════════ Step 2: Delivery scheduling (website Step D) ═══════════════ */

final class _DeliveryStep extends StatefulWidget {
  const _DeliveryStep({
    super.key,
    required this.reservation,
    required this.salesOrderId,
    required this.onBack,
    required this.onDone,
  });

  final CarReservation reservation;
  final String salesOrderId;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  State<_DeliveryStep> createState() => _DeliveryStepState();
}

final class _DeliveryStepState extends State<_DeliveryStep> {
  final _repo = OnlineStoreRepository(sl<ApiClient>());

  bool _loadingRec = true;
  Map<String, dynamic>? _record;
  DateTime? _date;
  bool _loadingSlots = false;
  List<Map<String, dynamic>> _slots = const [];
  Map<String, dynamic>? _selected;
  bool _booking = false;
  bool _booked = false;
  String? _error;

  String get _scheduleGuid => _rowStr(_record, ['GUID']);
  String get _siteId => _rowStr(_record, ['SiteID', 'SiteId']);
  bool get _standardDuration =>
      _rowTruthy(_record, ['StandardDeliveryDuration']);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final custId = sl<AuthBloc>().state.user?.custId ?? '';
    final rows = await _repo.carsoDeliveryVehicle(
        widget.reservation.sn ?? '', widget.salesOrderId, custId);
    if (!mounted) return;
    setState(() {
      _record = rows.isEmpty ? null : rows.first;
      _loadingRec = false;
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final min = now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? min,
      firstDate: min,
      lastDate: min.add(const Duration(days: 90)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _selected = null;
      _slots = const [];
    });
    if (_siteId.isEmpty) return;
    setState(() => _loadingSlots = true);
    final rows = await _repo.carsoDeliveryAvailable(
        _fmtDate(picked), _siteId, _standardDuration);
    if (!mounted) return;
    setState(() {
      _slots = rows;
      _loadingSlots = false;
    });
  }

  Future<void> _book() async {
    final t = AppLocalizations.of(context);
    if (_scheduleGuid.isEmpty || _selected == null || _date == null) return;
    setState(() {
      _booking = true;
      _error = null;
    });
    final d = _fmtDate(_date!);
    final res = await _repo.carsoDeliveryBook(
      _scheduleGuid,
      '$d ${_rowStr(_selected, ['FromTime'])}',
      '$d ${_rowStr(_selected, ['ToTime'])}',
    );
    if (!mounted) return;
    setState(() {
      _booking = false;
      if (res != null && _rowTruthy(res, ['ok'])) {
        _booked = true;
      } else {
        final e = _rowStr(res, ['error']);
        _error = e.isNotEmpty ? e : t.cpcDeliveryBookFailed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF18A957);

    Widget shell(List<Widget> children) => Container(
          padding: EdgeInsets.all(context.rs(14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );

    if (_loadingRec) {
      return shell([
        Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2)),
          SizedBox(width: context.rs(12)),
          Text(t.cpcDeliveryLoading,
              style: TextStyle(fontSize: context.rf(12))),
        ]),
      ]);
    }

    // Schedule row not ready (order still being confirmed by the ERP) →
    // allow skipping to payment, exactly like the website.
    if (_record == null || _scheduleGuid.isEmpty) {
      return shell([
        Text(t.cpcStepDelivery,
            style: TextStyle(
                fontSize: context.rf(14), fontWeight: FontWeight.w800)),
        SizedBox(height: context.rs(10)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.rs(14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          ),
          child: Text(
            t.cpcDeliveryNotReady,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.rf(11.5),
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        SizedBox(height: context.rs(12)),
        Row(children: [
          OutlinedButton(onPressed: widget.onBack, child: Text(t.cpcBack)),
          const Spacer(),
          FilledButton(
              onPressed: widget.onDone, child: Text(t.cpcContinuePayment)),
        ]),
      ]);
    }

    if (_booked) {
      return shell([
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.rs(12)),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: green.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: green),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: Text(
                '${t.cpcDeliveryBooked} · ${_date == null ? '' : _fmtDate(_date!)} ${_hhmm(_rowStr(_selected, ['FromTime']))}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: context.rf(11.5),
                    fontWeight: FontWeight.w700,
                    color: green),
              ),
            ),
          ]),
        ),
        SizedBox(height: context.rs(12)),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
              onPressed: widget.onDone, child: Text(t.cpcContinuePayment)),
        ),
      ]);
    }

    return shell([
      Row(children: [
        Icon(Icons.local_shipping_outlined, size: 18, color: scheme.primary),
        SizedBox(width: context.rs(8)),
        Text(t.cpcStepDelivery,
            style: TextStyle(
                fontSize: context.rf(14), fontWeight: FontWeight.w800)),
      ]),
      SizedBox(height: context.rs(4)),
      Text(t.cpcDeliveryHint,
          style: TextStyle(
            fontSize: context.rf(11.5),
            color: scheme.onSurface.withValues(alpha: 0.6),
          )),
      if (_error != null)
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: context.rs(10)),
          padding: EdgeInsets.all(context.rs(10)),
          decoration: BoxDecoration(
            color: const Color(0xFFE5484D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_error!,
              style:
                  const TextStyle(color: Color(0xFFE5484D), fontSize: 12)),
        ),
      SizedBox(height: context.rs(12)),

      // Date field (native date picker; min = tomorrow, like the website).
      Text(t.cpcDeliveryDate.toUpperCase(),
          style: TextStyle(
            fontSize: context.rf(10),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: scheme.onSurface.withValues(alpha: 0.55),
          )),
      SizedBox(height: context.rs(6)),
      Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _pickDate,
          child: Container(
            height: context.rs(48),
            padding: EdgeInsets.symmetric(horizontal: context.rs(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border:
                  Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            child: Row(children: [
              Icon(Icons.calendar_month_rounded,
                  size: 18, color: scheme.primary),
              SizedBox(width: context.rs(8)),
              Text(
                _date == null ? t.cpcDeliveryDate : _fmtDate(_date!),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: context.rf(12.5), fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
      ),

      if (_date != null) ...[
        SizedBox(height: context.rs(14)),
        Text(t.cpcDeliveryTimes.toUpperCase(),
            style: TextStyle(
              fontSize: context.rf(10),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: scheme.onSurface.withValues(alpha: 0.55),
            )),
        SizedBox(height: context.rs(8)),
        if (_loadingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_slots.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.rs(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: scheme.outline.withValues(alpha: 0.5)),
            ),
            child: Text(
              t.cpcDeliveryNoSlots,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          Wrap(
            spacing: context.rs(8),
            runSpacing: context.rs(8),
            children: [
              for (final s in _slots)
                Builder(builder: (context) {
                  final on = identical(_selected, s);
                  return Material(
                    color: on ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(11),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => setState(() => _selected = s),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(14),
                            vertical: context.rs(9)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: on
                                ? scheme.primary
                                : scheme.outline.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          _hhmm(_rowStr(s, ['FromTime'])),
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: context.rf(12),
                            fontWeight: FontWeight.w800,
                            color: on ? scheme.onPrimary : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
      ],

      SizedBox(height: context.rs(14)),
      Row(children: [
        OutlinedButton(onPressed: widget.onBack, child: Text(t.cpcBack)),
        const Spacer(),
        TextButton(
            onPressed: widget.onDone,
            child: Text(t.cpcDeliveryLater,
                style: TextStyle(fontSize: context.rf(11.5)))),
        SizedBox(width: context.rs(6)),
        FilledButton(
          onPressed: _selected != null && !_booking ? _book : null,
          child: _booking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2))
              : Text(t.cpcDeliveryConfirm),
        ),
      ]),
    ]);
  }
}

/* ═══════════════ Step 3: Remaining payment (website Step E) ═══════════════ */

final class _PaymentStep extends StatefulWidget {
  const _PaymentStep({
    super.key,
    required this.reservation,
    required this.salesOrder,
    required this.chosen,
    required this.isTest,
    required this.onBack,
    required this.onFinished,
  });

  final CarReservation reservation;
  final ({String guid, String id})? salesOrder;
  final List<ProtectionPackage> chosen;
  final bool isTest;
  final VoidCallback onBack;
  final VoidCallback onFinished;

  @override
  State<_PaymentStep> createState() => _PaymentStepState();
}

final class _PaymentStepState extends State<_PaymentStep> {
  final _repo = OnlineStoreRepository(sl<ApiClient>());

  bool _paying = false;
  bool _confirming = false;
  bool _paid = false;
  bool _testPaid = false;
  String? _sadad;
  String? _error;

  double get _netSale =>
      widget.reservation.total ?? widget.reservation.salePrice ?? 0;
  double get _deposit => widget.reservation.reqDownPayment ?? 0;
  double get _accTotal =>
      widget.chosen.fold(0, (s, p) => s + (p.price ?? 0));
  double get _remaining {
    final v = _netSale + _accTotal - _deposit;
    return v < 0 ? 0 : v;
  }

  Future<void> _pay() async {
    final t = AppLocalizations.of(context);
    final order = widget.salesOrder;
    if (order == null || order.id.isEmpty) {
      setState(() => _error = t.cpcContractFailed);
      return;
    }
    setState(() {
      _error = null;
      _paying = true;
    });
    final r = widget.reservation;
    final lang = Localizations.localeOf(context).languageCode;
    final profile = sl<AuthBloc>().state.user;
    final accessoryIds = widget.chosen
        .map((p) => p.id)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(',');
    // Website Step E payload, field-for-field: charge the EXISTING order
    // (InitializeOrder=false + InitializeOrderID).
    final payload = <String, dynamic>{
      'URL': 'https://hjapp.payment/carso',
      'Lang': lang,
      'Product': [
        {
          'id': r.productId,
          'quantity': 1,
          'colorID': r.colorId,
          'Type': 1,
          'price': _netSale,
          'CartID': null,
          'CostShipping': 0,
          'VIN': r.sn,
          'MiniDownPayment': _deposit,
        }
      ],
      'Accessories': accessoryIds.isEmpty ? null : accessoryIds,
      'NoteAccessories': '',
      'UserID': profile?.userId,
      'City': null,
      'DelivaryAddress': null,
      'NotificationWhatsApp': 0,
      'customerDetails': {'IP': ''},
      'DataAmount': {
        'FinalTotal': _netSale + _accTotal,
        'AmountShipping': 0,
        'SubAmountTotal': _remaining,
        'TotalTaxAmount': 0,
        'TotalDiscount': 0,
        'MiniDownPayment': _deposit,
      },
      'PaymentAmount': _remaining,
      'TypePaymnet': {
        'IsReservation': false,
        'IsPayment': true,
        'PaymnetTypeID': 'Cash',
        'MethodPayment': 'Myfatoorah&SADAD',
      },
      'DeliveryType': {'ByBranch': false, 'ByLocation': true},
      'DeliveryData': {'InfoBranch': null, 'InfoLocation': null},
      'CobonData': {'Code': null, 'ID': null, 'Amount': null},
      'RefrancePayment': null,
      'status': 1,
      'InitializeOrder': false,
      'InitializeOrderID': order.id,
      'OrderDraftID': null,
    };
    final rows = await _repo.carsoCarPayment(payload);
    if (!mounted) return;
    Map<String, dynamic>? row;
    for (final x in rows) {
      if (_rowStr(x, ['URL_Payment']).isNotEmpty ||
          _rowStr(x, ['SadadNumber']).isNotEmpty ||
          _rowStr(x, ['MessageError']).isNotEmpty) {
        row = x;
        break;
      }
    }
    row ??= rows.isEmpty ? null : rows.first;
    final url = _rowStr(row, ['URL_Payment']);
    final code = _rowStr(row, ['SadadNumber']);
    setState(() => _paying = false);

    if (url.isNotEmpty) {
      // In-app gateway (hjapp.payment callback pattern) → confirm status.
      final params = await Navigator.of(context, rootNavigator: true)
          .push<Map<String, String>>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CarsoGatewayPage(url: url),
      ));
      if (!mounted) return;
      if (params != null) {
        await _confirmStatus(params['Id'] ?? params['id'] ?? order.guid);
      }
      return;
    }
    if (code.isNotEmpty) {
      setState(() => _sadad = code);
      return;
    }
    final msg = _rowStr(row, ['MessageError', 'Message', 'ResponsMessage']);
    setState(
        () => _error = msg.isNotEmpty ? msg : AppLocalizations.of(context).pcPayFailed);
  }

  /// Gateway-return poller — website CarPurchasePaymentReturn.
  Future<void> _confirmStatus(String guid) async {
    setState(() => _confirming = true);
    final rows = await _repo.carsoPaymentStatus(guid);
    if (!mounted) return;
    Map<String, dynamic>? win;
    for (final x in rows) {
      if (_rowStr(x, ['Status']).toLowerCase() == 'success') {
        win = x;
        break;
      }
    }
    win ??= rows.isEmpty ? null : rows.first;
    final ok = _rowStr(win, ['Status']).toLowerCase() == 'success';
    final code = _rowStr(win, ['SadadNumber']);
    setState(() {
      _confirming = false;
      _paid = ok;
      if (code.isNotEmpty) _sadad = code;
    });
    if (ok) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF18A957);

    Widget money(double v, {Color? color, bool negative = false}) => Text.rich(
          TextSpan(children: [
            if (negative) TextSpan(text: '− ', style: TextStyle(color: color)),
            riyalSpan(fontSize: context.rf(12), color: color),
            TextSpan(text: formatPrice(v)),
          ]),
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: context.rf(12),
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: color,
          ),
        );

    Widget row(String label, Widget value) => Padding(
          padding: EdgeInsets.only(bottom: context.rs(7)),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: context.rf(11.5),
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  )),
            ),
            value,
          ]),
        );

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.credit_card_rounded, size: 18, color: scheme.primary),
            SizedBox(width: context.rs(8)),
            Text(t.cpcPayTitle,
                style: TextStyle(
                    fontSize: context.rf(14), fontWeight: FontWeight.w800)),
          ]),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: context.rs(10)),
              padding: EdgeInsets.all(context.rs(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFE5484D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFE5484D), fontSize: 12)),
            ),
          SizedBox(height: context.rs(12)),

          // ── Amount breakdown (website parity) ──
          Container(
            padding: EdgeInsets.all(context.rs(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
            ),
            child: Column(children: [
              row(t.cpcPayCar, money(_netSale)),
              if (_accTotal > 0) row(t.cpcPayAddons, money(_accTotal)),
              row(t.cpcPayDeposit,
                  money(_deposit, color: green, negative: true)),
              Divider(
                  height: context.rs(14),
                  color: scheme.outline.withValues(alpha: 0.5)),
              Row(children: [
                Expanded(
                  child: Text(t.cpcPayRemaining,
                      style: TextStyle(
                          fontSize: context.rf(12.5),
                          fontWeight: FontWeight.w800)),
                ),
                Text.rich(
                  TextSpan(children: [
                    riyalSpan(fontSize: context.rf(17), color: scheme.primary),
                    TextSpan(text: formatPrice(_remaining)),
                  ]),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: context.rf(17),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: scheme.primary,
                  ),
                ),
              ]),
            ]),
          ),
          SizedBox(height: context.rs(14)),

          if (_confirming)
            Row(children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2)),
              SizedBox(width: context.rs(10)),
              Text(t.cpcPayConfirming,
                  style: TextStyle(fontSize: context.rf(12))),
            ])
          else if (_testPaid || _paid)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: green.withValues(alpha: 0.35)),
              ),
              child: Column(children: [
                const Icon(Icons.check_circle_rounded, size: 38, color: green),
                SizedBox(height: context.rs(8)),
                Text(
                  _testPaid ? t.cpcTestPaid : t.cpcPayDone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: context.rf(14),
                      fontWeight: FontWeight.w800,
                      color: green),
                ),
                if ((widget.salesOrder?.id ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: context.rs(3)),
                    child: Text(widget.salesOrder!.id,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: context.rf(10.5),
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        )),
                  ),
                SizedBox(height: context.rs(6)),
                Text(
                  _testPaid ? t.cpcTestPaidHint : t.cpcPayThanks,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.rf(11.5),
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ]),
            )
          else if (_sadad != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(14)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.5)),
              ),
              child: Column(children: [
                Text(t.pcSadadTitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: context.rf(10),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    )),
                SizedBox(height: context.rs(6)),
                SelectableText(
                  _sadad!,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: context.rf(20),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(height: context.rs(6)),
                Text(
                  t.cpcSadadOpenBank,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.rf(10.5),
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ]),
            )
          else ...[
            if (widget.isTest)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: context.rs(10)),
                padding: EdgeInsets.all(context.rs(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFFB47D12).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(t.cpcTestModePay,
                    style: TextStyle(
                        fontSize: context.rf(11),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB47D12))),
              ),
            Row(children: [
              OutlinedButton(onPressed: widget.onBack, child: Text(t.cpcBack)),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: FilledButton(
                  onPressed: widget.isTest
                      ? () {
                          setState(() => _testPaid = true);
                          widget.onFinished();
                        }
                      : (_paying || _remaining <= 0 ? null : _pay),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                  child: _paying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2))
                      : Text(widget.isTest ? t.cpcPayTest : t.cpcPayProceed),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

/// MyFatoorah gateway for the REMAINING amount — intercepts the app callback
/// (`https://hjapp.payment…?PaymentMethod=…&Id=<salesOrderGUID>`) and pops
/// the query parameters, same pattern as the parts/jobcard gateway pages.
final class _CarsoGatewayPage extends StatefulWidget {
  const _CarsoGatewayPage({required this.url});

  final String url;

  @override
  State<_CarsoGatewayPage> createState() => _CarsoGatewayPageState();
}

final class _CarsoGatewayPageState extends State<_CarsoGatewayPage> {
  static const _callback = 'https://hjapp.payment';
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.startsWith(_callback)) {
            final params =
                Uri.tryParse(request.url)?.queryParameters ?? const {};
            Navigator.of(context).pop(Map<String, String>.from(params));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      child: SafeArea(
        child: Column(children: [
          Row(children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
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
          Expanded(child: WebViewWidget(controller: _controller)),
        ]),
      ),
    );
  }
}

/* ───────────────────────── Small pieces ───────────────────────── */

final class _StepsRail extends StatelessWidget {
  const _StepsRail({required this.active, required this.allDone});

  final int active;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF18A957);

    final steps = [
      (Icons.shield_outlined, t.cpcStepProtection),
      (Icons.history_edu_rounded, t.cpcStepContract),
      (Icons.local_shipping_outlined, t.cpcStepDelivery),
      (Icons.credit_card_rounded, t.cpcStepPayment),
    ];

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Builder(builder: (context) {
              final done = allDone || i < active;
              final on = !allDone && i == active;
              return Column(
                children: [
                  Container(
                    width: context.rs(38),
                    height: context.rs(38),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? green
                          : on
                              ? scheme.primary
                              : Colors.transparent,
                      border: done || on
                          ? null
                          : Border.all(
                              color: scheme.outline.withValues(alpha: 0.6)),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : steps[i].$1,
                      size: 17,
                      color: done || on
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  SizedBox(height: context.rs(5)),
                  Text(
                    steps[i].$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: context.rf(9),
                      height: 1.25,
                      fontWeight:
                          on || done ? FontWeight.w800 : FontWeight.w600,
                      color: on || done
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}

final class _SignInGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs(36)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 42, color: scheme.onSurface.withValues(alpha: 0.35)),
            SizedBox(height: context.rs(12)),
            Text(
              t.cpcSignInFirst,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.rf(13), height: 1.5),
            ),
            SizedBox(height: context.rs(16)),
            FilledButton(
              onPressed: () {
                Navigator.of(context).maybePop();
                sl<GoRouter>().go(Routes.signIn);
              },
              style:
                  FilledButton.styleFrom(minimumSize: Size(context.rs(180), 48)),
              child: Text(t.methodSignIn),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs(36)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 42, color: scheme.onSurface.withValues(alpha: 0.3)),
            SizedBox(height: context.rs(12)),
            Text(
              t.cpcNotFound,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.rf(13), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
