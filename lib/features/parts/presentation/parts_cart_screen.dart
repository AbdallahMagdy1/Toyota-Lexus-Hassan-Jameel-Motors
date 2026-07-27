import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../protection/data/protection_repository.dart';
import '../../protection/domain/protection_models.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/parts_cart_cubit.dart';
import '../data/parts_repository.dart';
import '../domain/parts_cart_models.dart';

const _kVatRate = 0.15;

/// Applied coupon (order-level, server-computed) — shared between the cart
/// and checkout screens, cleared with the cart.
final class PartsCoupon {
  const PartsCoupon({required this.id, required this.amount, required this.code});
  final int id;
  final double amount;
  final String code;

  static final ValueNotifier<PartsCoupon?> current = ValueNotifier(null);
}

double _round2(double v) => (v * 100).roundToDouble() / 100;

/* ───────────────────────────── Cart ───────────────────────────── */

/// سلة قطع الغيار — the website's /parts/cart: line items with qty steppers,
/// the coupon box and the summary, checkout goes branch-pickup only.
final class PartsCartScreen extends StatelessWidget {
  const PartsCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final items = context.watch<PartsCartCubit>().state;
    final cubit = context.read<PartsCartCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Column(children: [
      const AppHeader(),
      Expanded(
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 44,
                        color: scheme.onSurface.withValues(alpha: 0.25)),
                    SizedBox(height: context.rs(10)),
                    Text(t.pcEmpty,
                        style: TextStyle(
                            fontSize: context.rf(13.5),
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: context.rs(14)),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(24),
                              vertical: context.rs(11))),
                      onPressed: () => context.go(Routes.parts),
                      child: Text(t.pcContinue),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(16),
                    context.rs(16), context.rs(140)),
                children: [
                  Text(t.pcTitle,
                      style: TextStyle(
                          fontSize: context.rf(22),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(14)),
                  for (final it in items)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.rs(10)),
                      child: _CartLine(item: it, lang: lang, cubit: cubit),
                    ),
                  SizedBox(height: context.rs(8)),
                  const _CartSummary(),
                ],
              ),
      ),
    ]);
  }
}

final class _CartLine extends StatelessWidget {
  const _CartLine({required this.item, required this.lang, required this.cubit});

  final PartsCartItem item;
  final String lang;
  final PartsCartCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.rs(12)),
      decoration: softCardDecoration(context, radius: 18),
      child: Row(children: [
        SizedBox(
          width: context.rs(64),
          height: context.rs(56),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: HomeImage(
                url: item.image, fit: BoxFit.contain, logicalWidth: 64),
          ),
        ),
        SizedBox(width: context.rs(11)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(12.5),
                      fontWeight: FontWeight.w800)),
              if ((item.productNo ?? '').isNotEmpty)
                Text(item.productNo!,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: context.rf(9),
                        letterSpacing: 0.4,
                        color: scheme.onSurface.withValues(alpha: 0.45))),
              SizedBox(height: context.rs(4)),
              PriceText(
                  price: item.price,
                  currency: '',
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(13)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _QtyStepper(
            qty: item.qty,
            onChanged: (q) => cubit.setQty(item.guid, q),
          ),
          SizedBox(height: context.rs(6)),
          InkWell(
            onTap: () {
              cubit.remove(item.guid);
              if (cubit.state.isEmpty) PartsCoupon.current.value = null;
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delete_outline_rounded,
                  size: 14, color: scheme.onSurface.withValues(alpha: 0.45)),
              SizedBox(width: context.rs(3)),
              Text(t.pcRemove,
                  style: TextStyle(
                      fontSize: context.rf(10),
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            ]),
          ),
        ]),
      ]),
    );
  }
}

final class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.onChanged});

  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget btn(IconData icon, VoidCallback? onTap) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(icon,
                size: 14,
                color: onTap == null
                    ? scheme.onSurface.withValues(alpha: 0.25)
                    : scheme.onSurface.withValues(alpha: 0.7)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.add_rounded, () => onChanged(qty + 1)),
        Text('$qty',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        btn(Icons.remove_rounded, qty <= 1 ? null : () => onChanged(qty - 1)),
      ]),
    );
  }
}

final class _CartSummary extends StatefulWidget {
  const _CartSummary();

  @override
  State<_CartSummary> createState() => _CartSummaryState();
}

final class _CartSummaryState extends State<_CartSummary> {
  final _code = TextEditingController();
  bool _busy = false;
  bool _invalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _code.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _invalid = false;
    });
    final cubit = context.read<PartsCartCubit>();
    final lang = sl<LocaleCubit>().state.languageCode;
    final (valid, id, amount, _) =
        await PartsRepository(sl<ApiClient>()).validateCoupon(
      code,
      [
        for (final i in cubit.state)
          {
            'productId': i.productId ?? i.guid,
            'price': i.price ?? 0,
            'qty': i.qty,
          }
      ],
      lang,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _invalid = !valid;
    });
    PartsCoupon.current.value = valid && id != null && amount > 0
        ? PartsCoupon(id: id, amount: amount, code: code)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<PartsCartCubit>();
    final sub = _round2(cubit.subtotal);

    return ValueListenableBuilder<PartsCoupon?>(
      valueListenable: PartsCoupon.current,
      builder: (context, coupon, _) {
        final discount =
            coupon == null ? 0.0 : coupon.amount.clamp(0.0, sub).toDouble();
        final total = _round2(sub - discount);
        return Container(
          padding: EdgeInsets.all(context.rs(16)),
          decoration: softCardDecoration(context, radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.pcSummary,
                  style: TextStyle(
                      fontSize: context.rf(15), fontWeight: FontWeight.w800)),
              SizedBox(height: context.rs(12)),
              // Coupon box — server-validated, order-level discount.
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    decoration: InputDecoration(
                      hintText: t.pcCoupon,
                      hintStyle: TextStyle(
                          fontSize: context.rf(11.5),
                          color: scheme.onSurface.withValues(alpha: 0.4)),
                      prefixIcon: const Icon(Icons.sell_outlined, size: 17),
                      isDense: true,
                      errorText: _invalid ? t.pcCouponInvalid : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: context.rs(8)),
                FilledButton(
                  style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rs(18),
                          vertical: context.rs(11))),
                  onPressed: _busy ? null : _apply,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.pcApply),
                ),
              ]),
              SizedBox(height: context.rs(14)),
              _amountRow(context, t.pcSubtotal, sub),
              if (discount > 0)
                _amountRow(context, t.pcDiscount, -discount,
                    color: const Color(0xFF1E9E5A)),
              Divider(
                  height: context.rs(20),
                  color: scheme.outline.withValues(alpha: 0.35)),
              _amountRow(context, t.pcTotal, total, big: true),
              SizedBox(height: context.rs(14)),
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                    textStyle: TextStyle(
                        fontSize: context.rf(14),
                        fontWeight: FontWeight.w800)),
                onPressed: () => context.push(Routes.partsCheckout),
                child: Text(t.pcCheckout),
              ),
              SizedBox(height: context.rs(8)),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.parts),
                  child: Text(t.pcContinue,
                      style: TextStyle(
                          fontSize: context.rf(12),
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _amountRow(BuildContext context, String label, double value,
      {bool big = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: context.rf(big ? 14 : 12),
                  fontWeight: big ? FontWeight.w800 : FontWeight.w600)),
          PriceText(
              price: value.abs(),
              currency: '',
              contactForPrice: '',
              fontSize: context.rf(big ? 16 : 12.5),
              color: color),
        ],
      ),
    );
  }
}

/* ─────────────────────────── Checkout ─────────────────────────── */

enum _PayId { myfatoorah, tabby, tamara, sadad }

extension on _PayId {
  String get method => switch (this) {
        _PayId.myfatoorah => 'myFatoorah',
        _PayId.tabby => 'tabby',
        _PayId.tamara => 'tamara',
        _PayId.sadad => 'sadad',
      };
}

/// إتمام الطلب والدفع — the website's /parts/checkout, mobile-native and
/// BRANCH PICKUP ONLY (no delivery): branch + contact + payment method +
/// VAT summary → Site_SpareParts_Payment → gateway WebView / Sadad number.
final class PartsCheckoutScreen extends StatefulWidget {
  const PartsCheckoutScreen({super.key});

  @override
  State<PartsCheckoutScreen> createState() => _PartsCheckoutScreenState();
}

final class _PartsCheckoutScreenState extends State<PartsCheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  List<MaintBranch> _branches = const [];
  String? _branchId;
  _PayId _pay = _PayId.myfatoorah;

  bool _busy = false;
  bool _fieldError = false;
  String? _error;
  String? _sadad;
  String? _orderId;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    final user = sl<AuthBloc>().state.user;
    final lang = sl<LocaleCubit>().state.languageCode;
    _name.text = user?.displayName(lang) ?? '';
    _phone.text = user?.phone ?? '';
    _email.text = user?.email ?? '';
    ProtectionRepository(sl<ApiClient>()).branches().then((b) {
      if (!mounted) return;
      setState(() {
        _branches = b;
        _branchId = b.firstOrNull?.id;
      });
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _payNow() async {
    final t = AppLocalizations.of(context);
    final cart = context.read<PartsCartCubit>();
    final user = sl<AuthBloc>().state.user;
    if (user == null) {
      context.push(Routes.signIn);
      return;
    }
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _branchId == null ||
        cart.state.isEmpty) {
      setState(() => _fieldError = true);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = false;
      _error = null;
    });

    final lang = sl<LocaleCubit>().state.languageCode;
    final sub = _round2(cart.subtotal);
    final coupon = PartsCoupon.current.value;
    final discount =
        coupon == null ? 0.0 : coupon.amount.clamp(0.0, sub).toDouble();
    final base = _round2(sub - discount);
    final tax = _round2(base * _kVatRate);
    final total = _round2(base + tax);

    // The website checkout payload, verbatim (branch pickup only).
    final res = await PartsRepository(sl<ApiClient>()).checkout({
      'lang': lang,
      'userId': '${user.userId}',
      'products': [
        for (final i in cart.state)
          {
            'id': i.productId ?? i.guid,
            'quantity': i.qty,
            'price': i.price ?? 0,
            'isStock': i.inStock,
          }
      ],
      'finalTotal': total,
      'totalTaxAmount': tax,
      'totalDiscount': discount,
      'amountShipping': 0,
      'subAmountTotal': sub,
      'miniDownPayment': 0,
      'paymentAmount': total,
      'methodPayment': _pay.method,
      'paymentTypeId': 'Cash',
      'byBranch': true,
      'byLocation': false,
      'infoBranch': _branchId,
      'callbackUrl': 'https://hjapp.payment/parts?paid=1',
      if (discount > 0 && coupon != null) 'couponId': coupon.id,
      if (discount > 0) 'couponAmount': discount,
    });

    if (!mounted) return;
    if (res == null) {
      setState(() {
        _busy = false;
        _error = t.offersSubmitFailed;
      });
      return;
    }

    final status = (res['status'] ?? '').toString().toLowerCase();
    final urlPayment = (res['urlPayment'] ?? '').toString();
    final sadad = (res['sadadNumber'] ?? '').toString();
    final orderGuid = (res['orderGuid'] ?? '').toString();
    final orderId = (res['orderId'] ?? '').toString();
    final message = (res['messageError'] ?? '').toString();

    // URL / Sadad WIN over messageError (legacy SP quirk, like the website).
    if (sadad.isNotEmpty && sadad != 'null') {
      cart.clear();
      PartsCoupon.current.value = null;
      setState(() {
        _busy = false;
        _sadad = sadad;
        _orderId = orderId;
      });
      return;
    }
    if (urlPayment.isNotEmpty && urlPayment != 'null') {
      final paid = await Navigator.of(context, rootNavigator: true)
          .push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PartsGatewayPage(
          url: urlPayment,
          orderGuid: orderGuid,
          payType: _pay.name,
        ),
      ));
      if (!mounted) return;
      if (paid == true) {
        cart.clear();
        PartsCoupon.current.value = null;
        setState(() {
          _busy = false;
          _success = true;
          _orderId = orderId;
        });
      } else {
        setState(() {
          _busy = false;
          _error = t.pcPayFailed;
        });
      }
      return;
    }
    if (status == 'success') {
      cart.clear();
      PartsCoupon.current.value = null;
      setState(() {
        _busy = false;
        _success = true;
        _orderId = orderId;
      });
      return;
    }
    setState(() {
      _busy = false;
      _error = message.isNotEmpty && message != 'null'
          ? message
          : t.offersSubmitFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final cart = context.watch<PartsCartCubit>();

    if (_success || _sadad != null) {
      return Column(children: [
        const AppHeader(),
        Expanded(child: _resultView(t, scheme)),
      ]);
    }

    final sub = _round2(cart.subtotal);
    final coupon = PartsCoupon.current.value;
    final discount =
        coupon == null ? 0.0 : coupon.amount.clamp(0.0, sub).toDouble();
    final base = _round2(sub - discount);
    final tax = _round2(base * _kVatRate);
    final total = _round2(base + tax);

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    return Column(children: [
      const AppHeader(),
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.rs(16), context.rs(16), context.rs(16), context.rs(140)),
          children: [
            Text(t.pcCheckoutTitle,
                style: TextStyle(
                    fontSize: context.rf(22), fontWeight: FontWeight.w800)),
            SizedBox(height: context.rs(14)),

            // ── طريقة الاستلام: استلام من الفرع فقط ──
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: softCardDecoration(context, radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.pcPickupMethod,
                      style: TextStyle(
                          fontSize: context.rf(13.5),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(10)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(14), vertical: context.rs(12)),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.primary, width: 1.3),
                    ),
                    child: Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 17, color: scheme.primary),
                      SizedBox(width: context.rs(8)),
                      Text(t.pcPickup,
                          style: TextStyle(
                              fontSize: context.rf(12.5),
                              fontWeight: FontWeight.w800,
                              color: scheme.primary)),
                      const Spacer(),
                      Icon(Icons.check_circle_rounded,
                          size: 17, color: scheme.primary),
                    ]),
                  ),
                  SizedBox(height: context.rs(12)),
                  DropdownButtonFormField<String>(
                    initialValue: _branchId,
                    isExpanded: true,
                    items: [
                      for (final b in _branches)
                        DropdownMenuItem(
                            value: b.id, child: Text(b.name(lang))),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                    decoration: deco('${t.pcChooseBranch} *'),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.rs(12)),

            // ── بيانات التواصل ──
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: softCardDecoration(context, radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.pcContact,
                      style: TextStyle(
                          fontSize: context.rf(13.5),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(12)),
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _name,
                            decoration: deco('${t.formFullName} *'))),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                        child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: deco('${t.formPhone} *'))),
                  ]),
                  SizedBox(height: context.rs(12)),
                  TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: deco(t.formEmailOptional)),
                ],
              ),
            ),
            SizedBox(height: context.rs(12)),

            // ── طريقة الدفع ──
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: softCardDecoration(context, radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.pcPayMethod,
                      style: TextStyle(
                          fontSize: context.rf(13.5),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(10)),
                  for (final (id, label) in [
                    (_PayId.myfatoorah, t.pcPayMyfatoorah),
                    (_PayId.tamara, t.pcPayTamara),
                    (_PayId.tabby, t.pcPayTabby),
                    (_PayId.sadad, t.pcPaySadad),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: context.rs(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _pay = id),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(13),
                              vertical: context.rs(12)),
                          decoration: BoxDecoration(
                            color: _pay == id
                                ? scheme.primary.withValues(alpha: 0.07)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _pay == id
                                  ? scheme.primary
                                  : scheme.outline.withValues(alpha: 0.5),
                              width: _pay == id ? 1.3 : 1,
                            ),
                          ),
                          child: Row(children: [
                            Icon(
                              _pay == id
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 17,
                              color: _pay == id
                                  ? scheme.primary
                                  : scheme.onSurface.withValues(alpha: 0.35),
                            ),
                            SizedBox(width: context.rs(9)),
                            Expanded(
                              child: Text(label,
                                  style: TextStyle(
                                      fontSize: context.rf(12.5),
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: context.rs(12)),

            // ── الملخص + ادفع الآن ──
            Container(
              padding: EdgeInsets.all(context.rs(16)),
              decoration: softCardDecoration(
                  context, radius: 20, tint: scheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.pcOrder} (${cart.count})',
                      style: TextStyle(
                          fontSize: context.rf(14.5),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(10)),
                  for (final i in cart.state)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.rs(6)),
                      child: Row(children: [
                        Expanded(
                          child: Text('${i.name(lang)} ×${i.qty}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: context.rf(11.5),
                                  fontWeight: FontWeight.w600)),
                        ),
                        PriceText(
                            price: i.lineTotal,
                            currency: '',
                            contactForPrice: '',
                            fontSize: context.rf(11.5)),
                      ]),
                    ),
                  Divider(
                      height: context.rs(18),
                      color: scheme.outline.withValues(alpha: 0.35)),
                  _sum(context, t.pcSubtotal, sub),
                  if (discount > 0)
                    _sum(context, t.pcDiscount, -discount,
                        color: const Color(0xFF1E9E5A)),
                  _sum(context, t.pcVat, tax),
                  SizedBox(height: context.rs(4)),
                  _sum(context, t.pcTotal, total, big: true),
                  SizedBox(height: context.rs(14)),
                  if (_fieldError || _error != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.rs(8)),
                      child: Text(
                        _error ?? t.formCheckFields,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: scheme.error, fontSize: context.rf(12)),
                      ),
                    ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        textStyle: TextStyle(
                            fontSize: context.rf(14),
                            fontWeight: FontWeight.w800)),
                    onPressed: _busy || cart.state.isEmpty ? null : _payNow,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2))
                        : const Icon(Icons.payments_outlined, size: 18),
                    label: Text(t.jdPayNow),
                  ),
                  SizedBox(height: context.rs(6)),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(t.pcTitle,
                          style: TextStyle(
                              fontSize: context.rf(11.5),
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _sum(BuildContext context, String label, double value,
      {bool big = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: context.rf(big ? 14 : 11.5),
                  fontWeight: big ? FontWeight.w800 : FontWeight.w600)),
          PriceText(
              price: value.abs(),
              currency: '',
              contactForPrice: '',
              fontSize: context.rf(big ? 16 : 11.5),
              color: color),
        ],
      ),
    );
  }

  Widget _resultView(AppLocalizations t, ColorScheme scheme) {
    final sadad = _sadad;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
              sadad != null
                  ? Icons.receipt_long_rounded
                  : Icons.check_circle_rounded,
              size: 54,
              color: scheme.primary),
          const SizedBox(height: 14),
          Text(sadad != null ? t.pcSadadTitle : t.pcSuccess,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          if ((_orderId ?? '').isNotEmpty && _orderId != 'null') ...[
            const SizedBox(height: 6),
            Text('${t.pcOrderNo}: $_orderId',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6))),
          ],
          if (sadad != null) ...[
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Clipboard.setData(ClipboardData(text: sadad));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(sadad,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(t.pcSadadHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.6))),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder()),
            onPressed: () => context.go(Routes.parts),
            child: Text(t.commonDone),
          ),
        ],
      ),
    );
  }
}

/// Provider gateway WebView — intercepts the app callback URL, verifies the
/// payment with the backend and pops with the result.
final class _PartsGatewayPage extends StatefulWidget {
  const _PartsGatewayPage({
    required this.url,
    required this.orderGuid,
    required this.payType,
  });

  final String url;
  final String orderGuid;
  final String payType;

  @override
  State<_PartsGatewayPage> createState() => _PartsGatewayPageState();
}

final class _PartsGatewayPageState extends State<_PartsGatewayPage> {
  static const _callback = 'https://hjapp.payment/parts';
  late final WebViewController _controller;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.startsWith(_callback)) {
            _verify();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _verify() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    final res = await PartsRepository(sl<ApiClient>())
        .paymentStatus(widget.orderGuid, widget.payType);
    if (!mounted) return;
    final ok = (res?['status'] ?? '').toString().toLowerCase() == 'success';
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
          Expanded(
            child: _verifying
                ? const Center(child: CircularProgressIndicator())
                : WebViewWidget(controller: _controller),
          ),
        ]),
      ),
    );
  }
}
