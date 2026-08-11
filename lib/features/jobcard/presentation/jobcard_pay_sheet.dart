import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../coupons/domain/coupon_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../data/jobcard_repository.dart';

/// Return URL the gateways redirect back to inside the WebView — never a
/// real page; navigation to it is intercepted and the capture endpoint runs.
const String _kCallback = 'https://hjapp.payment/jobcard';

/// Opens the job-card payment sheet (بطاقة العمل) for the given job-card
/// GUID — the app-native version of the website's /jobCard/[number] page:
/// grouped line items, additional requests, cost summary, gateway picker
/// (MyFatoorah full / Tabby / Tamara / Sadad) and the in-app gateway WebView.
Future<void> showJobCardPaySheet(BuildContext context,
    {required String guid}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _JobCardPaySheet(guid: guid),
  );
}

/* ────────────────────────────── gateways ────────────────────────────── */

/// Same four methods as the website, in the same order: pay-in-full settles
/// through MyFatoorah (it is the channel, not a separate method), then the
/// BNPL pair (disabled when TamarClose), then Sadad.
final class _Gateway {
  const _Gateway({
    required this.method,
    required this.icon,
    required this.ar,
    required this.en,
    required this.subAr,
    required this.subEn,
    this.bnpl = false,
  });

  final String method;
  final IconData icon;
  final String ar;
  final String en;
  final String subAr;
  final String subEn;
  final bool bnpl;
}

const List<_Gateway> _kGateways = [
  _Gateway(
    method: 'full',
    icon: Icons.credit_card_rounded,
    ar: 'كامل المبلغ',
    en: 'Pay in full',
    subAr: 'مدى • فيزا • ماستركارد • أبل باي • STC Pay',
    subEn: 'Mada • Visa • Mastercard • Apple Pay • STC Pay',
  ),
  _Gateway(
    method: 'tabby',
    icon: Icons.splitscreen_rounded,
    ar: 'تابي',
    en: 'Tabby',
    subAr: 'قسّمها على ٤ دفعات — بدون فوائد',
    subEn: 'Split in 4 — no interest',
    bnpl: true,
  ),
  _Gateway(
    method: 'tamara',
    icon: Icons.calendar_month_rounded,
    ar: 'تمارا',
    en: 'Tamara',
    subAr: 'قسّمها على دفعات — بدون فوائد',
    subEn: 'Split in instalments — no interest',
    bnpl: true,
  ),
  _Gateway(
    method: 'sadad',
    icon: Icons.receipt_long_rounded,
    ar: 'سداد',
    en: 'Sadad',
    subAr: 'ادفع برقم فاتورة سداد عبر تطبيق بنكك',
    subEn: 'Pay with a Sadad invoice via your bank app',
  ),
];

/* ─────────────────────────────── sheet ─────────────────────────────── */

enum _Phase { loading, failed, ready, success }

final class _JobCardPaySheet extends StatefulWidget {
  const _JobCardPaySheet({required this.guid});

  final String guid;

  @override
  State<_JobCardPaySheet> createState() => _JobCardPaySheetState();
}

final class _JobCardPaySheetState extends State<_JobCardPaySheet> {
  late final JobCardRepository _repo = JobCardRepository(sl<ApiClient>());

  _Phase _phase = _Phase.loading;
  Map<String, dynamic>? _pay; // CheckJobCartStatus row
  Map<String, dynamic>? _netTotal; // summary.netTotal aggregates
  List<Map<String, dynamic>> _rows = const [];
  List<Map<String, dynamic>> _addLines = const [];
  Map<String, dynamic>? _addHeader;
  bool _checkCustomer = false;
  bool _tamaraClose = false;

  bool _includeAdd = false;
  String? _method;
  bool _busy = false;
  String? _error;
  String? _sadadIssued; // Sadad number issued during this session

  // Coupon — server-validated; the client only displays the verdict.
  final _couponCtrl = TextEditingController();
  CouponResult? _coupon;
  String _couponCode = '';
  bool _couponBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  /* ── derived state (mirrors the website page exactly) ── */

  // CheckJobCartStatus: status = 0 → PAID / settled / payment already issued
  // (e.g. a pending Sadad); status = 1 → still OPEN and payable. Do NOT invert.
  int get _status => jcNum(_pay, const ['status']).round();
  bool get _isPaid => _pay != null && _status == 0;

  String get _sadadNumber {
    if (_sadadIssued != null) return _sadadIssued!;
    if (_isPaid &&
        jcStr(_pay, const ['PaymentMethodID']).toLowerCase() == 'sadad') {
      return jcStr(_pay, const ['SadadNumber']);
    }
    return '';
  }

  double get _remaining => jcNum(_addHeader, const ['Remaining']);
  double get _paidAmount => jcNum(_addHeader, const ['PaidAmount']);

  double get _total =>
      (_checkCustomer ? 0 : jcNum(_netTotal, const ['numberNet'])) +
      (_includeAdd ? _remaining : 0);

  bool get _canPay =>
      !_checkCustomer &&
      _pay != null &&
      _status == 1 &&
      _sadadNumber.isEmpty &&
      _total > 0;

  /// Display-only coupon discount, capped at the payable total.
  double get _couponDiscount {
    final c = _coupon;
    if (c == null || !c.valid) return 0;
    return c.discountAmount.clamp(0.0, _total).toDouble();
  }

  /// Amount actually due after the coupon — drives the summary total and
  /// the BNPL split hints. (_netTotal is the raw summary aggregate map.)
  double get _dueTotal =>
      (_total - _couponDiscount).clamp(0.0, double.infinity).toDouble();

  /* ── data ── */

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _phase = _Phase.loading);
    final results = await Future.wait<dynamic>([
      _repo.paymentStatus(widget.guid),
      _repo.summary(widget.guid),
      _repo.tamaraStatus(widget.guid),
      _repo.additionalsLines(widget.guid),
      _repo.checkCustomer(widget.guid),
    ]);
    if (!mounted) return;
    final sum = results[1] as Map<String, dynamic>?;
    final lines = results[3] as List<Map<String, dynamic>>;
    final header = lines.isEmpty
        ? null
        : (await _repo.additionalsHeader(widget.guid)).firstOrNull;
    if (!mounted) return;
    setState(() {
      _pay = results[0] as Map<String, dynamic>?;
      _netTotal = jcMap(jcField(sum, const ['netTotal']));
      _rows = jcRows(jcField(sum, const ['jobCardRespons']));
      _tamaraClose = jcTruthy(
          (results[2] as List<Map<String, dynamic>>).firstOrNull,
          const ['TamarClose']);
      _addLines = lines;
      _addHeader = header;
      _checkCustomer = jcTruthy(
          (results[4] as List<Map<String, dynamic>>).firstOrNull,
          const ['CheckCustomer']);
      _phase = (sum == null && results[0] == null && !silent)
          ? _Phase.failed
          : (_phase == _Phase.success ? _phase : _Phase.ready);
    });
  }

  /* ── coupon ── */

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty || _couponBusy) return;
    setState(() {
      _couponBusy = true;
      _coupon = null;
    });
    final lang = sl<LocaleCubit>().state.languageCode;
    final res = await _repo.validateCoupon(widget.guid, code, lang);
    if (!mounted) return;
    setState(() {
      _couponBusy = false;
      _coupon = res;
      _couponCode = code;
    });
  }

  void _clearCoupon() => setState(() {
        _coupon = null;
        _couponCode = '';
        _couponCtrl.clear();
      });

  /* ── payment flow ── */

  Future<void> _payNow(String Function(String, String) tr) async {
    final method = _method;
    if (method == null) {
      setState(() => _error = tr('اختر طريقة الدفع.', 'Choose a payment method.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    // CSV of the approved line GUIDs — same selection the website sends.
    final prudocts = [
      for (final r in _rows)
        if (jcTruthy(r, const ['Approved'])) jcStr(r, const ['GUID']),
    ].where((s) => s.isNotEmpty).join(',');

    final res = await _repo.approvePayment(
      widget.guid,
      prudocts: prudocts,
      paymentType: method,
      callback: _kCallback,
      // Only a code the server declared valid is forwarded — the backend
      // recomputes the discount itself.
      couponCode: (_coupon?.valid ?? false) ? _couponCode : null,
    );
    if (!mounted) return;

    // Sadad has NO gateway redirect: approve prepares the bill, sadad-code
    // uploads it and returns the invoice number to pay via the bank app.
    if (method == 'sadad') {
      final sadad = await _repo.sadadCode(widget.guid);
      if (!mounted) return;
      final snum = jcStr(sadad, const ['sadadNumber', 'SadadNumber']);
      if (snum.isNotEmpty && snum != 'null') {
        setState(() {
          _busy = false;
          _sadadIssued = snum;
        });
        _load(silent: true); // pull the pending-Sadad payment status
      } else {
        final msg = jcStr(sadad,
            const ['sadadMessage', 'MessageError', 'Error_messages', 'ErrorMessage']);
        setState(() {
          _busy = false;
          _error = msg.isNotEmpty && msg != 'null'
              ? msg
              : tr('تعذّر إصدار فاتورة سداد. حاول مرة أخرى.',
                  'Could not issue the Sadad invoice. Please try again.');
        });
      }
      return;
    }

    final url = jcStr(res, const ['url_payment', 'URL_Paytabs', 'Url']);
    if (url.isEmpty || url == 'null') {
      final err = jcStr(res, const ['MessageError', 'Error_messages']);
      setState(() {
        _busy = false;
        _error = err.isNotEmpty && err != 'null'
            ? err
            : tr('تعذّر بدء عملية الدفع. حاول مرة أخرى.',
                'Could not start the payment. Please try again.');
      });
      return;
    }

    final ret = await Navigator.of(context, rootNavigator: true)
        .push<(String, String, String)>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _JobCardGatewayPage(url: url),
    ));
    if (!mounted) return;
    if (ret == null) {
      // User closed the gateway — a cancel, not a failure.
      setState(() => _busy = false);
      return;
    }
    await _confirmReturn(ret.$1, ret.$2, ret.$3, method, tr);
  }

  /// Post-return confirm/capture — the website's callback effect, plus the
  /// refetch it was missing so the paid state shows immediately.
  Future<void> _confirmReturn(String pm, String pt, String orderId,
      String chosenMethod, String Function(String, String) tr) async {
    var gateway = pm;
    if (gateway.isEmpty) {
      gateway = chosenMethod == 'full' ? 'myfatoorah' : chosenMethod;
    }
    final res = switch (gateway) {
      'paytabs' when pt == 'partial' =>
        await _repo.paytabsStatusPartially(widget.guid),
      'paytabs' => await _repo.paytabsStatusFully(widget.guid),
      'tamara' => await _repo.tamaraCapture(widget.guid, orderId),
      'tabby' => await _repo.tabbyCapture(widget.guid),
      _ => await _repo.myFatoorahStatusFully(widget.guid),
    };
    if (!mounted) return;

    final hasError = jcField(res, const ['MessageError', 'Error_messages']);
    final ok = res != null &&
        (jcField(res, const ['SuccessMessage']) != null ||
            jcStr(res, const ['Status']).toLowerCase() == 'success' ||
            hasError == null);
    if (ok) {
      setState(() {
        _busy = false;
        _phase = _Phase.success;
      });
      _load(silent: true); // refetch → the paid banner shows behind Done
    } else {
      setState(() {
        _busy = false;
        _error = '$hasError'.isNotEmpty && '$hasError' != 'null'
            ? '$hasError'
            : tr('تعذّر تأكيد عملية الدفع. حاول مرة أخرى.',
                'Could not confirm the payment. Please try again.');
      });
    }
  }

  /* ── build ── */

  @override
  Widget build(BuildContext context) {
    final lang = sl<LocaleCubit>().state.languageCode;
    final isAr = lang == 'ar';
    String tr(String ar, String en) => isAr ? ar : en;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: SafeArea(
        top: false,
        child: Column(children: [
          const SheetHandle(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(8)),
            child: Row(children: [
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  tr('دفع بطاقة العمل', 'Job card payment'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: context.rf(16), fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
          ),
          Expanded(
            child: switch (_phase) {
              _Phase.loading => _Skeleton(),
              _Phase.failed => _FailedView(tr: tr, onRetry: _load),
              _Phase.success => _SuccessView(
                  tr: tr,
                  onDone: () => setState(() => _phase = _Phase.ready),
                ),
              _Phase.ready => _content(context, tr, isAr, scheme),
            },
          ),
        ]),
      ),
    );
  }

  Widget _content(BuildContext context, String Function(String, String) tr,
      bool isAr, ColorScheme scheme) {
    // Group the summary rows like the website (dedupe on "Group").
    final groups = <String, (String, List<Map<String, dynamic>>)>{};
    for (final r in _rows) {
      final key = jcStr(r, const ['Group']);
      final k = key.isEmpty ? '—' : key;
      final name = isAr
          ? jcStr(r, const ['Group Ar', 'Group'])
          : jcStr(r, const ['Group']);
      (groups[k] ??= (name.isEmpty ? '—' : name, [])).$2.add(r);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(16), context.rs(6), context.rs(16), context.rs(28)),
      children: [
        if (_isPaid && _sadadNumber.isEmpty) _paidBanner(context, tr),
        if (_sadadNumber.isNotEmpty) _sadadPanel(context, tr, _sadadNumber),

        // ── بنود بطاقة العمل ──
        if (groups.isNotEmpty) ...[
          _SectionLabel(tr('بنود بطاقة العمل', 'Job card items')),
          Container(
            padding: EdgeInsets.all(context.rs(14)),
            decoration: softCardDecoration(context, radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (gi, g) in groups.values.indexed) ...[
                  if (gi > 0)
                    Divider(
                        height: context.rs(18),
                        color: scheme.outline.withValues(alpha: 0.35)),
                  Text(g.$1,
                      style: TextStyle(
                          fontSize: context.rf(12.5),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(6)),
                  for (final it in g.$2)
                    _lineRow(
                      context,
                      name: isAr
                          ? jcStr(it, const ['Product Ar', 'Product'])
                          : jcStr(it, const ['Product']),
                      qty: jcNum(it, const ['Qty']),
                      price: jcNum(
                          it, const ['Net Total', 'Net Total Excluding Tax']),
                    ),
                ],
              ],
            ),
          ),
        ],

        // ── طلبات إضافية ──
        if (_addLines.isNotEmpty) ...[
          _SectionLabel(tr('طلبات إضافية', 'Additional requests')),
          Container(
            padding: EdgeInsets.all(context.rs(14)),
            decoration: softCardDecoration(context, radius: 18),
            child: Column(children: [
              for (final it in _addLines)
                _lineRow(
                  context,
                  name: isAr
                      ? jcStr(it, const ['OrderName', 'OrderNameEn'])
                      : jcStr(it, const ['OrderNameEn', 'OrderName']),
                  qty: jcNum(it, const ['Qty']),
                  price: jcNum(it, const ['NetTotal', 'SalesPrice']),
                ),
              if (!_checkCustomer && _remaining > 0) ...[
                SizedBox(height: context.rs(6)),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _includeAdd = !_includeAdd),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(10), vertical: context.rs(11)),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(
                        _includeAdd
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 20,
                        color: _includeAdd
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.4),
                      ),
                      SizedBox(width: context.rs(8)),
                      Expanded(
                        child: Text(
                          tr('تضمين المبلغ المتبقّي لبطاقة العمل الرئيسية',
                              'Include the remaining main job-card amount'),
                          style: TextStyle(
                              fontSize: context.rf(11.5),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      PriceText(
                          price: _remaining,
                          currency: '',
                          contactForPrice: '',
                          fontSize: context.rf(12)),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ],

        // ── كود الكوبون ── (website parity: input + Apply → emerald pill
        // when valid, red text when invalid; 'unavailable' stays quiet)
        if (_canPay) ...[
          _SectionLabel(tr('كود الكوبون', 'Coupon code')),
          _couponBox(context, tr, scheme),
        ],

        // ── ملخص التكاليف ──
        _SectionLabel(tr('ملخص التكاليف', 'Cost summary')),
        Container(
          padding: EdgeInsets.all(context.rs(16)),
          decoration:
              softCardDecoration(context, radius: 20, tint: scheme.primary),
          child: Column(children: [
            _priceRow(
                context,
                tr('الإجمالي قبل الخصم', 'Total before discount'),
                jcNum(_netTotal, const ['numberTotalBefore'])),
            _priceRow(context, tr('الخصم', 'Discount'),
                jcNum(_netTotal, const ['numberDiscount'])),
            _priceRow(context, tr('ضريبة القيمة المضافة', 'VAT'),
                jcNum(_netTotal, const ['numberTax'])),
            if (_paidAmount > 0)
              _priceRow(context, tr('مدفوع مسبقًا', 'Prepaid'), _paidAmount,
                  hideNever: true),
            if (_couponDiscount > 0)
              Padding(
                padding: EdgeInsets.only(bottom: context.rs(6)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context).cpnCouponDiscount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.rf(12),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E9E5A)),
                          ),
                        ),
                        Text(
                          ' ($_couponCode)',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              fontSize: context.rf(10.5),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E9E5A)),
                        ),
                      ]),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      children: [
                        Text('−',
                            style: TextStyle(
                                fontSize: context.rf(12.5),
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E9E5A))),
                        _amount(context, _couponDiscount,
                            fontSize: context.rf(12.5),
                            color: const Color(0xFF1E9E5A)),
                      ],
                    ),
                  ],
                ),
              ),
            Divider(
                height: context.rs(20),
                color: scheme.outline.withValues(alpha: 0.35)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr('الإجمالي المستحق', 'Amount due'),
                    style: TextStyle(
                        fontSize: context.rf(14),
                        fontWeight: FontWeight.w800)),
                if (_checkCustomer)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(12), vertical: context.rs(4)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18A957).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(tr('مجانًا', 'FREE'),
                        style: TextStyle(
                            fontSize: context.rf(12.5),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF18A957))),
                  )
                else
                  _amount(context, _dueTotal, fontSize: context.rf(17)),
              ],
            ),
            if (!_checkCustomer)
              Padding(
                padding: EdgeInsets.only(top: context.rs(4)),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    tr('شامل ضريبة القيمة المضافة', 'VAT included'),
                    style: TextStyle(
                        fontSize: context.rf(10),
                        color: scheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ),
          ]),
        ),

        // ── الدفع ──
        if (_canPay) ...[
          _SectionLabel(tr('اختر طريقة الدفع', 'Choose a payment method')),
          for (final g in _kGateways)
            _gatewayRow(context, g, tr,
                disabled: g.bnpl && _tamaraClose),
          if (_error != null)
            Container(
              margin: EdgeInsets.only(top: context.rs(8)),
              padding: EdgeInsets.all(context.rs(12)),
              decoration: BoxDecoration(
                color: const Color(0xFFE5484D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!,
                  style: TextStyle(
                      color: const Color(0xFFE5484D),
                      fontSize: context.rf(12))),
            ),
          SizedBox(height: context.rs(14)),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                textStyle: TextStyle(
                    fontSize: context.rf(14), fontWeight: FontWeight.w800)),
            onPressed: _busy ? null : () => _payNow(tr),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2))
                : const Icon(Icons.verified_user_outlined, size: 18),
            label: Text(AppLocalizations.of(context).jdPayNow),
          ),
          SizedBox(height: context.rs(10)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_outline_rounded,
                size: 13, color: scheme.onSurface.withValues(alpha: 0.45)),
            SizedBox(width: context.rs(4)),
            Text(tr('دفع آمن وموثّق بالكامل', 'Secure, fully documented payment'),
                style: TextStyle(
                    fontSize: context.rf(10.5),
                    color: scheme.onSurface.withValues(alpha: 0.5))),
          ]),
        ] else if (!_checkCustomer &&
            !_isPaid &&
            _sadadNumber.isEmpty &&
            _total > 0) ...[
          SizedBox(height: context.rs(4)),
          Container(
            padding: EdgeInsets.all(context.rs(14)),
            decoration: softCardDecoration(context, radius: 16),
            child: Text(
              tr('هذه البطاقة غير متاحة للدفع حاليًا.',
                  'This job card is not available for payment right now.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.rf(12),
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ],
    );
  }

  /* ── pieces ── */

  /// Riyal amount that, unlike [PriceText], still renders "⃀ 0" for zero
  /// values (the website prints zero discounts/taxes, not a placeholder).
  Widget _amount(BuildContext context, double value,
      {required double fontSize, Color? color}) {
    if (value > 0) {
      return PriceText(
          price: value,
          currency: '',
          contactForPrice: '—',
          fontSize: fontSize,
          color: color);
    }
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(children: [
        riyalSpan(fontSize: fontSize, color: color ?? scheme.primary),
        TextSpan(
          text: '0',
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              color: color),
        ),
      ]),
      textDirection: TextDirection.ltr,
    );
  }

  /// Coupon input / applied pill — website parity: ticket-icon input +
  /// Apply; valid → emerald pill (code + server message + X to clear);
  /// invalid → red text; 'unavailable' or a network failure stays quiet.
  Widget _couponBox(BuildContext context, String Function(String, String) tr,
      ColorScheme scheme) {
    final t = AppLocalizations.of(context);
    const green = Color(0xFF1E9E5A);
    final c = _coupon;

    if (c != null && c.valid) {
      return Container(
        padding: EdgeInsetsDirectional.fromSTEB(
            context.rs(12), context.rs(8), context.rs(4), context.rs(8)),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: green.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: green),
          SizedBox(width: context.rs(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_couponCode,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: green)),
                if ((c.message ?? '').isNotEmpty)
                  Text(c.message!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(10.5), color: green)),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearCoupon,
            tooltip: t.cpnRemove,
            icon: const Icon(Icons.close_rounded, size: 18, color: green),
          ),
        ]),
      );
    }

    final invalid = c != null && !c.valid && !c.unavailable;
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _couponCtrl,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            TextInputFormatter.withFunction(
                (o, n) => n.copyWith(text: n.text.toUpperCase())),
          ],
          decoration: InputDecoration(
            hintText: tr('كود الكوبون', 'Coupon code'),
            hintStyle: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.4)),
            prefixIcon: const Icon(Icons.confirmation_number_outlined,
                size: 17),
            isDense: true,
            errorText: invalid
                ? ((c.message ?? '').isNotEmpty
                    ? c.message
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
        onPressed: _couponBusy ? null : _applyCoupon,
        child: _couponBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(t.pcApply),
      ),
    ]);
  }

  Widget _paidBanner(BuildContext context, String Function(String, String) tr) {
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(12)),
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: const Color(0xFF18A957).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF18A957).withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded,
            size: 20, color: Color(0xFF18A957)),
        SizedBox(width: context.rs(8)),
        Text(tr('تم سداد هذه البطاقة', 'This job card has been paid'),
            style: TextStyle(
                fontSize: context.rf(13),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18A957))),
      ]),
    );
  }

  Widget _sadadPanel(BuildContext context, String Function(String, String) tr,
      String number) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(12)),
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(tr('رقم فاتورة سداد', 'Sadad invoice number'),
            style: TextStyle(
                fontSize: context.rf(10.5),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: scheme.primary)),
        SizedBox(height: context.rs(8)),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Clipboard.setData(ClipboardData(text: number));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
              content: Text(tr('تم النسخ', 'Copied')),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ));
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.rs(14), vertical: context.rs(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(number,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: context.rf(18),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              SizedBox(width: context.rs(8)),
              Icon(Icons.copy_rounded, size: 16, color: scheme.primary),
            ]),
          ),
        ),
        SizedBox(height: context.rs(4)),
        Text(t.pcSadadHint,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.rf(11),
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _lineRow(BuildContext context,
      {required String name, required double qty, required double price}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(6)),
      child: Row(children: [
        Expanded(
          child: Text(name.isEmpty ? '—' : name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: context.rf(11.5), fontWeight: FontWeight.w600)),
        ),
        SizedBox(width: context.rs(8)),
        Text('×${qty <= 0 ? 1 : (qty % 1 == 0 ? qty.toInt() : qty)}',
            textDirection: TextDirection.ltr,
            style: TextStyle(
                fontSize: context.rf(11),
                color: scheme.onSurface.withValues(alpha: 0.5))),
        SizedBox(width: context.rs(10)),
        if (_checkCustomer)
          Text('—',
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  color: scheme.onSurface.withValues(alpha: 0.5)))
        else
          _amount(context, price, fontSize: context.rf(11.5)),
      ]),
    );
  }

  Widget _priceRow(BuildContext context, String label, double value,
      {bool hideNever = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: context.rf(12),
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
          if (_checkCustomer && !hideNever)
            Text('—',
                style: TextStyle(
                    fontSize: context.rf(12),
                    color: scheme.onSurface.withValues(alpha: 0.5)))
          else
            _amount(context, value, fontSize: context.rf(12.5)),
        ],
      ),
    );
  }

  Widget _gatewayRow(BuildContext context, _Gateway g,
      String Function(String, String) tr,
      {required bool disabled}) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _method == g.method;
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(8)),
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled
                ? null
                : () => setState(() {
                      _method = g.method;
                      _error = null;
                    }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(13), vertical: context.rs(12)),
              decoration: softCardDecoration(context, radius: 16).copyWith(
                border: Border.all(
                  color: selected
                      ? scheme.primary
                      : scheme.outline.withValues(alpha: 0.5),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 19,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.35),
                ),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(g.ar, g.en),
                          style: TextStyle(
                              fontSize: context.rf(13),
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: context.rs(2)),
                      Text(tr(g.subAr, g.subEn),
                          style: TextStyle(
                              fontSize: context.rf(10.5),
                              color:
                                  scheme.onSurface.withValues(alpha: 0.55))),
                      if (g.bnpl && _dueTotal > 0)
                        Padding(
                          padding: EdgeInsets.only(top: context.rs(2)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('${tr('من', 'From')} ',
                                style: TextStyle(
                                    fontSize: context.rf(10.5),
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700)),
                            PriceText(
                                price: _dueTotal / 4,
                                currency: '',
                                contactForPrice: '',
                                fontSize: context.rf(10.5)),
                            Text(' ${tr('× ٤ دفعات', '× 4 payments')}',
                                style: TextStyle(
                                    fontSize: context.rf(10.5),
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: context.rs(8)),
                Icon(g.icon,
                    size: 20,
                    color: selected
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.35)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────── sub-views ─────────────────────────── */

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.rs(16), bottom: context.rs(8)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.rf(11),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

final class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(16), context.rs(10), context.rs(16), context.rs(28)),
      children: [
        for (final h in const [110.0, 150.0, 130.0, 90.0])
          Container(
            height: h,
            margin: EdgeInsets.only(bottom: context.rs(12)),
            decoration: softCardDecoration(context, radius: 18),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.45, end: 1, duration: 700.ms),
      ],
    );
  }
}

final class _FailedView extends StatelessWidget {
  const _FailedView({required this.tr, required this.onRetry});

  final String Function(String, String) tr;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded,
            size: 40, color: scheme.onSurface.withValues(alpha: 0.3)),
        SizedBox(height: context.rs(12)),
        Text(
          tr('تعذّر تحميل بيانات بطاقة العمل.',
              'Could not load the job card details.'),
          style: TextStyle(
              fontSize: context.rf(13), fontWeight: FontWeight.w700),
        ),
        SizedBox(height: context.rs(14)),
        FilledButton(
          style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: Size(context.rs(160), 46)),
          onPressed: onRetry,
          child: Text(tr('إعادة المحاولة', 'Try again')),
        ),
      ]),
    );
  }
}

final class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.tr, required this.onDone});

  final String Function(String, String) tr;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: context.rs(76),
            height: context.rs(76),
            decoration: BoxDecoration(
              color: const Color(0xFF18A957).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 40, color: Color(0xFF18A957)),
          )
              .animate()
              .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutBack)
              .fadeIn(duration: 250.ms),
          SizedBox(height: context.rs(18)),
          Text(
            tr('تم استلام عملية الدفع بنجاح.',
                'Your payment was received successfully.'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.rf(15), fontWeight: FontWeight.w800),
          ),
          SizedBox(height: context.rs(8)),
          Text(
            tr('سيصلك تأكيد بذلك، ويمكنك متابعة حالة بطاقة العمل من التطبيق.',
                'A confirmation is on its way — you can follow the job card from the app.'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.rf(12),
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          SizedBox(height: context.rs(24)),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: Size(context.rs(180), 50),
                shape: const StadiumBorder()),
            onPressed: onDone,
            child: Text(t.commonDone),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────── gateway page ─────────────────────────── */

/// Provider gateway WebView — same pattern as the parts/online gateways:
/// intercepts the app callback, parses PaymentMethod / PaymentType / orderId
/// (tolerating a second '?' in the return URL) and pops with them; the sheet
/// then runs the matching capture endpoint.
final class _JobCardGatewayPage extends StatefulWidget {
  const _JobCardGatewayPage({required this.url});

  final String url;

  @override
  State<_JobCardGatewayPage> createState() => _JobCardGatewayPageState();
}

final class _JobCardGatewayPageState extends State<_JobCardGatewayPage> {
  late final WebViewController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.startsWith(_kCallback)) {
            if (!_handled) {
              _handled = true;
              final p = _params(request.url);
              Navigator.of(context).pop((
                (p['paymentmethod'] ?? '').toLowerCase(),
                (p['paymenttype'] ?? '').toLowerCase(),
                p['orderid'] ?? p['order_id'] ?? '',
              ));
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Gateways sometimes append their params with a second '?' — normalize
  /// everything after the first into one query string, keys lowercased.
  static Map<String, String> _params(String url) {
    final qi = url.indexOf('?');
    if (qi < 0) return const {};
    final tail = url.substring(qi + 1).replaceAll('?', '&');
    Map<String, String> raw;
    try {
      raw = Uri.splitQueryString(tail);
    } catch (_) {
      raw = const {};
    }
    return {for (final e in raw.entries) e.key.toLowerCase(): e.value};
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
