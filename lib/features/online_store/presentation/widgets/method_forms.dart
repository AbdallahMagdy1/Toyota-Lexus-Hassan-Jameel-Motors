import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/storage/local_store.dart';
import '../../../../shared/navigation/sheet_routes.dart' show SheetHandle;
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../finance/presentation/finance_lead_sheet.dart'
    show AbsherAutofillButton;
import '../../../home/domain/home_models.dart';
import '../../../home/presentation/widgets/home_bits.dart';
import '../../../settings/bloc/locale_cubit.dart';
import '../../bloc/car_sheet_cubit.dart';
import '../../bloc/method_form_cubits.dart';
import '../../domain/online_store_models.dart';
import '../purchase_complete_screen.dart';
import 'bank_cards.dart';
import 'order_summary_card.dart';

/* ───────────────────────── Method picker card ───────────────────────── */

final class MethodCard extends StatelessWidget {
  const MethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.title,
    required this.price,
    required this.bullets,
    required this.onTap,
    this.badge,
    this.authBadge,
  });

  final PurchaseMethod method;
  final bool selected;
  final String title;
  final Widget price;
  final List<String> bullets;
  final VoidCallback onTap;
  final String? badge;
  final String? authBadge;

  IconData get _icon => switch (method) {
        PurchaseMethod.reserve => Icons.bolt_rounded,
        PurchaseMethod.finance => Icons.description_outlined,
        PurchaseMethod.contact => Icons.phone_callback_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(10)),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(context.rs(14)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.6),
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: context.rs(36),
                      height: context.rs(36),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon, size: 19, color: scheme.primary),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: context.rf(15),
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (badge != null) ...[
                                SizedBox(width: context.rs(6)),
                                _Chip(text: badge!, color: scheme.primary),
                              ],
                            ],
                          ),
                          if (authBadge != null)
                            _Chip(
                                text: authBadge!,
                                color: scheme.onSurface.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: context.rf(11.5),
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                      child: price,
                    ),
                  ],
                ),
                SizedBox(height: context.rs(8)),
                for (final b in bullets)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.rs(3)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_rounded, size: 14, color: scheme.primary),
                        SizedBox(width: context.rs(6)),
                        Expanded(
                          child: Text(
                            b,
                            style: TextStyle(
                              fontSize: context.rf(11.5),
                              height: 1.35,
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: context.rf(8.5), fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

/* ───────────────────────── Form page dispatcher ───────────────────────── */

final class MethodFormPage extends StatelessWidget {
  const MethodFormPage({super.key, required this.vehicle});

  final OnlineVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sheet = context.watch<CarSheetCubit>();
    final state = sheet.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final auth = context.watch<AuthBloc>().state;

    final title = switch (state.method) {
      PurchaseMethod.reserve => t.methodReserveTitle,
      PurchaseMethod.finance => t.methodFinanceTitle,
      PurchaseMethod.contact => t.methodContactTitle,
    };

    // Quick reservation requires sign-in — the website's SignInPrompt gate.
    if (state.method == PurchaseMethod.reserve && auth.user == null) {
      return _SignInGate(title: title);
    }

    final body = switch (state.method) {
      PurchaseMethod.contact => BlocProvider(
          create: (_) => ContactFormCubit(sl(), vehicle, state.formSettings,
              lang: lang, user: auth.user, color: state.color),
          child: const ContactForm(),
        ),
      PurchaseMethod.reserve => BlocProvider(
          create: (_) => ReserveFormCubit(sl(), vehicle, state.formSettings,
              lang: lang,
              downPayment: sheet.downPayment,
              sn: state.detail?.sn,
              user: auth.user,
              color: state.color),
          child: const ReserveForm(),
        ),
      PurchaseMethod.finance => BlocProvider(
          create: (_) => FinanceFormCubit(sl(), vehicle, state.formSettings,
              lang: lang,
              user: auth.user,
              color: state.color,
              initialBankId: state.selectedBankId),
          child: FinanceForm(banks: state.banks),
        ),
    };

    return Column(
      children: [
        _FormHeader(title: title, onBack: sheet.backToMethods),
        Expanded(child: body),
      ],
    );
  }
}

final class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Opaque bar + hairline so scrolling form content reads as passing
    // UNDER the pinned header instead of merging with it.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom:
              BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.rs(8), 0, context.rs(8), context.rs(4)),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: context.rf(16), fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

final class _SignInGate extends StatelessWidget {
  const _SignInGate({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sheet = context.read<CarSheetCubit>();
    return Column(
      children: [
        _FormHeader(title: title, onBack: sheet.backToMethods),
        const Spacer(),
        Icon(Icons.lock_outline_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
        SizedBox(height: context.rs(12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rs(40)),
          child: Text(t.reserveSignInFirst, textAlign: TextAlign.center),
        ),
        SizedBox(height: context.rs(16)),
        FilledButton(
          onPressed: () {
            Navigator.of(context).maybePop();
            context.go(Routes.signIn);
          },
          style: FilledButton.styleFrom(minimumSize: Size(context.rs(180), 48)),
          child: Text(t.methodSignIn),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

/* ───────────────────────── Shared form widgets ───────────────────────── */

final class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.rs(14), bottom: context.rs(6)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: context.rf(10.5),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

final class FormInput extends StatelessWidget {
  const FormInput({
    super.key,
    required this.controller,
    this.hint,
    this.error,
    this.keyboardType,
    this.digitsOnly = false,
    this.maxLength,
    this.ltr = false,
    this.prefix,
  });

  final TextEditingController controller;
  final String? hint;
  final String? error;
  final TextInputType? keyboardType;
  final bool digitsOnly;
  final int? maxLength;
  final bool ltr;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: ltr ? TextDirection.ltr : null,
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(hintText: hint, errorText: error, prefix: prefix),
    );
  }
}

/// +966-prefixed 9-digit phone field — the website's PhoneField.
final class PhoneInput extends StatelessWidget {
  const PhoneInput({super.key, required this.controller, this.error});

  final TextEditingController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: context.rs(50),
            padding: EdgeInsets.symmetric(horizontal: context.rs(12)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            child: Text('+966',
                style: TextStyle(
                    fontSize: context.rf(13.5), fontWeight: FontWeight.w700)),
          ),
          SizedBox(width: context.rs(8)),
          Expanded(
            child: FormInput(
              controller: controller,
              hint: '5xxxxxxxx',
              error: error,
              keyboardType: TextInputType.phone,
              digitsOnly: true,
              maxLength: 9,
              ltr: true,
            ),
          ),
        ],
      ),
    );
  }
}

final class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.error,
    this.hint,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.rs(14)),
      child: AppDropdown<T>(
        label: label,
        value: value,
        hint: hint,
        errorText: error,
        items: [
          for (final i in items) AppDropdownItem(value: i, label: labelOf(i)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

final class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(vertical: context.rs(9)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: context.rf(12.5),
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String? _errText(BuildContext context, String? code) {
  final t = AppLocalizations.of(context);
  return switch (code) {
    null => null,
    'phone' => t.authInvalidPhone,
    'email' => t.authInvalidEmail,
    'identity' => t.errIdentity,
    'tooBig' => t.errDocTooBig,
    _ => t.authRequiredField,
  };
}

Widget _submitBar(BuildContext context,
    {required bool busy, required VoidCallback onSubmit, String? label}) {
  final t = AppLocalizations.of(context);
  return Padding(
    padding: EdgeInsets.fromLTRB(0, context.rs(18), 0, context.rs(24)),
    child: FilledButton(
      onPressed: busy ? null : onSubmit,
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4))
          : Text(label ?? t.formSend),
    ),
  );
}

Widget _serverError(BuildContext context, String? error) {
  if (error == null) return const SizedBox.shrink();
  final t = AppLocalizations.of(context);
  final text = error == 'failed' || error == 'network' ? t.authGenericError : error;
  return Container(
    margin: EdgeInsets.only(top: context.rs(12)),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFE5484D).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text,
        style: const TextStyle(color: Color(0xFFE5484D), fontSize: 12.5)),
  );
}

/* ───────────────────────── Contact (callback) form ───────────────────────── */

final class ContactForm extends StatelessWidget {
  const ContactForm({super.key, this.onSuccess});

  /// Host override for the success handling — when null (hosted inside the
  /// car sheet) the sheet's success page shows; model-sheet hosts pass
  /// their own close+snackbar.
  final void Function(String? reference)? onSuccess;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ContactFormCubit>();
    final state = context.watch<ContactFormCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;

    Future<void> submit() async {
      final res = await cubit.submit();
      if (res == null || !context.mounted) return;
      if (onSuccess != null) {
        onSuccess!(res.reference);
      } else {
        context.read<CarSheetCubit>().showSuccess(res.reference);
      }
    }

    // No "Order details" panel here — a callback request carries no payment
    // yet, so the form goes straight to the applicant fields.
    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
      children: [
        // Absher autofill — website's "Autofill your details" strip.
        AbsherAutofillButton(onFilled: cubit.applyAbsher),
        PickerField<CustGroup>(
          label: t.formApplicant,
          value: cubit.custGroup,
          items: cubit.settings.custGroups,
          labelOf: (g) => g.name(lang),
          onChanged: (g) => cubit.setCustGroup(g.id ?? 'G4'),
        ),
        FieldLabel(t.formName),
        FormInput(controller: cubit.name, error: _errText(context, state.errors['name'])),
        FieldLabel(t.formPhone),
        PhoneInput(controller: cubit.phone, error: _errText(context, state.errors['phone'])),
        FieldLabel(t.formEmail),
        FormInput(
            controller: cubit.email,
            error: _errText(context, state.errors['email']),
            keyboardType: TextInputType.emailAddress,
            ltr: true),
        PickerField<City>(
          label: t.formCity,
          value: cubit.settings.cities
              .where((c) => c.id == state.cityId)
              .firstOrNull,
          items: cubit.settings.cities,
          labelOf: (c) => c.name(lang),
          onChanged: (c) => cubit.setCity(c.id),
          error: _errText(context, state.errors['city']),
        ),
        FieldLabel(cubit.needIdentity ? t.formIdentity : t.formCN),
        FormInput(
            controller: cubit.identity,
            error: _errText(context, state.errors['identity']),
            keyboardType: TextInputType.number,
            digitsOnly: true,
            maxLength: 10,
            ltr: true),
        FieldLabel(t.formQuantity),
        Row(
          children: [
            IconButton.outlined(
              onPressed: () => cubit.setQuantity(state.quantity - 1),
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
              child: Text('${state.quantity}',
                  style: TextStyle(
                      fontSize: context.rf(16), fontWeight: FontWeight.w800)),
            ),
            IconButton.outlined(
              onPressed: () => cubit.setQuantity(state.quantity + 1),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
        FieldLabel(t.formNote),
        FormInput(controller: cubit.note),
        _serverError(context, state.serverError),
        _submitBar(context, busy: state.busy, onSubmit: submit),
      ],
    ).animate().fadeIn(duration: 220.ms);
  }
}

/* ───────────────────────── Quick reservation form ───────────────────────── */

final class ReserveForm extends StatelessWidget {
  const ReserveForm({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ReserveFormCubit>();
    final state = context.watch<ReserveFormCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final sheet = context.read<CarSheetCubit>();
    final scheme = Theme.of(context).colorScheme;

    Future<void> submit() async {
      // Stock car with SN → the old store's BUY: pay the down payment
      // through the gateway (Site_Reservation_Car_Payment), exactly like
      // the website. No SN → plain reservation request (CRM follow-up).
      if ((cubit.sn ?? '').isEmpty) {
        final res = await cubit.submit();
        if (res != null && context.mounted) sheet.showSuccess(res.reference);
        return;
      }
      final res = await cubit.payAndReserve();
      if (res == null || !context.mounted) return;
      final url = '${res['urlPayment'] ?? ''}';
      final sadad = '${res['sadadNumber'] ?? ''}';
      final orderId = '${res['orderId'] ?? ''}';
      final draftGuid = '${res['orderGuid'] ?? ''}';

      // Opens the post-deposit "complete purchase" continuation (the
      // website's /car/complete/{orderGuid}) over the sheet and remembers it
      // so the flow stays reachable after the app is closed.
      Future<void> openComplete(String guid) async {
        await sl<LocalStore>().setPendingCarPurchase(
            guid: guid, carName: cubit.vehicle.name(lang));
        if (context.mounted) await PurchaseCompleteScreen.open(context, guid);
      }

      // TEST-MODE parity with the website: cars in the 'test' product group
      // skip the deposit gateway — the draft exists, go straight to the
      // purchase continuation.
      final isTest =
          '${cubit.vehicle.groupEn ?? ''} ${cubit.vehicle.shortDescriptionEn ?? ''}'
              .toLowerCase()
              .contains('test');
      if (isTest && draftGuid.isNotEmpty && draftGuid != 'null') {
        sheet.showSuccess(orderId == 'null' ? '' : orderId,
            orderGuid: draftGuid);
        await openComplete(draftGuid);
        return;
      }

      if (url.isNotEmpty && url != 'null') {
        final gate = await Navigator.of(context, rootNavigator: true)
            .push<(bool, String?)>(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _OnlineGatewayPage(url: url),
        ));
        if (!context.mounted) return;
        if (gate != null && gate.$1) {
          final guid = (gate.$2 ?? '').trim();
          sheet.showSuccess(guid.isNotEmpty ? guid : (orderId == 'null' ? '' : orderId),
              orderGuid: guid.isEmpty ? null : guid);
          // Paid → continue the purchase (protection & shading + next steps),
          // exactly where the website redirects after the gateway.
          if (guid.isNotEmpty) await openComplete(guid);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t.pcPayFailed),
              behavior: SnackBarBehavior.floating));
        }
        return;
      }
      if (sadad.isNotEmpty && sadad != 'null') {
        await showDialog<void>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text(t.pcSadadTitle),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              SelectableText(sadad,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(t.pcSadadHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 1.5)),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dCtx).pop(),
                  child: Text(t.commonDone)),
            ],
          ),
        );
        if (context.mounted) {
          sheet.showSuccess(orderId == 'null' || orderId.isEmpty ? sadad : orderId);
        }
        return;
      }
      sheet.showSuccess(orderId == 'null' ? '' : orderId);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
      children: [
        // The website's "Order details" panel — car + colours + total, down
        // payment, amount required and the "How you pay" platforms strip.
        OrderSummaryCard(
          vehicle: cubit.vehicle,
          color: sheet.state.color,
          downPayment: cubit.downPayment,
          showPlatforms: true,
          initiallyExpanded: true,
        ),
        PickerField<CustGroup>(
          label: t.formApplicant,
          value: cubit.settings.custGroups
              .where((g) => g.id == state.custGroupId)
              .firstOrNull,
          items: cubit.settings.custGroups,
          labelOf: (g) => g.name(lang),
          onChanged: (g) => cubit.setCustGroup(g.id ?? 'G4'),
        ),
        FieldLabel(t.formName),
        FormInput(controller: cubit.name, error: _errText(context, state.errors['name'])),
        FieldLabel(t.formPhone),
        PhoneInput(controller: cubit.phone, error: _errText(context, state.errors['phone'])),
        FieldLabel(t.formEmail),
        FormInput(
            controller: cubit.email,
            keyboardType: TextInputType.emailAddress,
            ltr: true),
        PickerField<City>(
          label: t.formCity,
          value: cubit.settings.cities
              .where((c) => c.id == state.cityId)
              .firstOrNull,
          items: cubit.settings.cities,
          labelOf: (c) => c.name(lang),
          onChanged: (c) => cubit.setCity(c.id),
          error: _errText(context, state.errors['city']),
        ),
        FieldLabel(cubit.needIdentity ? t.formIdentity : t.formCN),
        FormInput(
            controller: cubit.identity,
            error: _errText(context, state.errors['identity']),
            keyboardType: TextInputType.number,
            digitsOnly: true,
            maxLength: 10,
            ltr: true),
        _serverError(context, state.serverError),
        // "You will pay <amount> (Refundable)" — website ReserveForm footer.
        Padding(
          padding: EdgeInsets.only(top: context.rs(14)),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: context.rf(11.5),
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              children: [
                TextSpan(text: '${t.reserveWillPay} '),
                TextSpan(children: [
                  riyalSpan(
                      fontSize: context.rf(12), color: scheme.onSurface),
                  TextSpan(
                      text: formatPrice(cubit.downPayment),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurface)),
                ]),
                TextSpan(text: ' (${t.methodRefundable})'),
              ],
            ),
          ),
        ),
        _submitBar(context,
            busy: state.busy, onSubmit: submit, label: t.formPayConfirm),
      ],
    ).animate().fadeIn(duration: 220.ms);
  }
}

/* ───────────────────────── Finance form (3 steps) ───────────────────────── */

final class FinanceForm extends StatelessWidget {
  const FinanceForm({super.key, required this.banks});

  final List<BankOffer> banks;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<FinanceFormCubit>();
    final state = context.watch<FinanceFormCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    final steps = [t.stepPersonal, t.stepWork, t.stepDocuments];

    return Column(
      children: [
        // Step indicator (tap back to earlier steps).
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.rs(20), vertical: context.rs(6)),
          child: Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => cubit.goToStep(i),
                    child: Column(
                      children: [
                        Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: context.rf(11),
                            fontWeight:
                                i == state.step ? FontWeight.w800 : FontWeight.w600,
                            color: i <= state.step
                                ? scheme.primary
                                : scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        SizedBox(height: context.rs(6)),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: i <= state.step
                                ? scheme.primary
                                : scheme.outline.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < steps.length - 1) SizedBox(width: context.rs(6)),
              ],
            ],
          ),
        ),
        // "What are the financing requirements & required documents?" —
        // the website's Learn-more entry, visible on every step.
        Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(8), context.rs(20), 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => showFinanceRequirementsSheet(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(12), vertical: context.rs(10)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 16, color: scheme.primary),
                  SizedBox(width: context.rs(8)),
                  Expanded(
                    child: Text(
                      t.finReqLearnTitle,
                      style: TextStyle(
                          fontSize: context.rf(11.5),
                          fontWeight: FontWeight.w700,
                          color: scheme.primary),
                    ),
                  ),
                  Text(
                    t.finReqLearnMore,
                    style: TextStyle(
                      fontSize: context.rf(10.5),
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.primary,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (state.step) {
              0 => _FinancePersonal(key: const ValueKey(0)),
              1 => _FinanceWork(key: const ValueKey(1)),
              _ => _FinanceDocs(key: const ValueKey(2), banks: banks),
            },
          ),
        ),
      ],
    );
  }
}

/// Financing requirements & required documents — the website's
/// FinanceRequirementsDialog (Saudi / Resident tabs) as a bottom sheet.
void showFinanceRequirementsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _FinanceRequirementsSheet(),
  );
}

final class _FinanceRequirementsSheet extends StatefulWidget {
  const _FinanceRequirementsSheet();

  @override
  State<_FinanceRequirementsSheet> createState() =>
      _FinanceRequirementsSheetState();
}

final class _FinanceRequirementsSheetState
    extends State<_FinanceRequirementsSheet> {
  int _tab = 0; // 0 Saudi | 1 Resident

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final requirements = [
      t.finReqAge,
      t.finReqWorkDuration,
      _tab == 0 ? t.finReqSalarySaudi : t.finReqSalaryResident,
    ];
    final documents = [
      t.finReqDoc1,
      t.finReqDoc2,
      t.finReqDoc3,
      t.finReqDoc4,
      t.finReqDoc5,
    ];

    Widget bullet(IconData icon, String text) => Padding(
          padding: EdgeInsets.only(bottom: context.rs(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: scheme.primary),
              SizedBox(width: context.rs(8)),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: context.rf(12),
                        height: 1.5,
                        color: scheme.onSurface.withValues(alpha: 0.75))),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(12), context.rs(20), context.rs(26)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: SheetHandle()),
          SizedBox(height: context.rs(10)),
          Text(t.finReqLearnTitle,
              style: TextStyle(
                  fontSize: context.rf(15), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(12)),
          Segmented(
            options: [t.finReqSaudi, t.finReqResident],
            selectedIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          SizedBox(height: context.rs(16)),
          Text(t.finReqDialogReqs,
              style: TextStyle(
                  fontSize: context.rf(13), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(8)),
          for (final r in requirements) bullet(Icons.check_rounded, r),
          SizedBox(height: context.rs(10)),
          Text(t.finReqDialogDocs,
              style: TextStyle(
                  fontSize: context.rf(13), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(8)),
          for (final d in documents) bullet(Icons.description_outlined, d),
          SizedBox(height: context.rs(14)),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: Text(t.commonDone),
          ),
        ],
      ),
    );
  }
}

final class _FinancePersonal extends StatelessWidget {
  const _FinancePersonal({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<FinanceFormCubit>();
    final state = context.watch<FinanceFormCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final sheet = context.read<CarSheetCubit>();

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
      children: [
        // Compact collapsible order summary — the website's "Order details".
        OrderSummaryCard(
          vehicle: cubit.vehicle,
          color: sheet.state.color,
          downPayment: sheet.downPayment,
        ),
        SizedBox(height: context.rs(4)),
        // "Autofill from Absher" — website AbsherAutofill on the personal step.
        AbsherAutofillButton(onFilled: cubit.applyAbsher),
        PickerField<CustGroup>(
          label: t.formApplicant,
          value: cubit.settings.custGroups
              .where((g) => g.id == state.custGroupId)
              .firstOrNull,
          items: cubit.settings.custGroups,
          labelOf: (g) => g.name(lang),
          onChanged: (g) => cubit.setCustGroup(g.id ?? 'G4'),
        ),
        FieldLabel(t.formNameAr),
        FormInput(
            controller: cubit.fullNameAr,
            error: _errText(context, state.errors['fullName'])),
        FieldLabel(t.formNameEn),
        FormInput(
            controller: cubit.fullNameEn,
            error: _errText(context, state.errors['fullName']),
            ltr: true),
        FieldLabel(t.formPhone),
        PhoneInput(controller: cubit.phone, error: _errText(context, state.errors['phone'])),
        FieldLabel(t.formEmail),
        FormInput(
            controller: cubit.email,
            keyboardType: TextInputType.emailAddress,
            ltr: true),
        PickerField<City>(
          label: t.formCity,
          value: cubit.settings.cities
              .where((c) => c.id == state.cityId)
              .firstOrNull,
          items: cubit.settings.cities,
          labelOf: (c) => c.name(lang),
          onChanged: (c) => cubit.setCity(c.id),
          error: _errText(context, state.errors['city']),
        ),
        FieldLabel(cubit.needIdentity ? t.formIdentity : t.formCN),
        FormInput(
            controller: cubit.identity,
            error: _errText(context, state.errors['identity']),
            keyboardType: TextInputType.number,
            digitsOnly: true,
            maxLength: 10,
            ltr: true),
        FieldLabel(t.formGender),
        Segmented(
          options: [t.genderMale, t.genderFemale],
          selectedIndex: state.gender - 1,
          onSelected: (i) => cubit.setGender(i + 1),
        ),
        SizedBox(height: context.rs(12)),
        SwitchListTile(
          value: state.whatsapp,
          onChanged: cubit.setWhatsapp,
          contentPadding: EdgeInsets.zero,
          title: Text(t.formWhatsapp, style: TextStyle(fontSize: context.rf(13))),
        ),
        _submitBar(context, busy: false, onSubmit: cubit.next, label: t.formNext),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }
}

final class _FinanceWork extends StatelessWidget {
  const _FinanceWork({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<FinanceFormCubit>();
    final state = context.watch<FinanceFormCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final sheet = context.read<CarSheetCubit>();

    Widget yesNo(String question, int value, ValueChanged<int> onChanged) {
      return Padding(
        padding: EdgeInsets.only(top: context.rs(12)),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(question, style: TextStyle(fontSize: context.rf(12.5)))),
            SizedBox(
              width: context.rs(140),
              child: Segmented(
                options: [t.answerYes, t.answerNo],
                selectedIndex: value == 1 ? 0 : (value == 0 ? 1 : -1),
                onSelected: (i) => onChanged(i == 0 ? 1 : 0),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
      children: [
        FieldLabel(t.formJob),
        FormInput(controller: cubit.job, error: _errText(context, state.errors['job'])),
        FieldLabel(t.formIncome),
        FormInput(
            controller: cubit.income,
            error: _errText(context, state.errors['income']),
            keyboardType: TextInputType.number,
            digitsOnly: true,
            ltr: true),
        FieldLabel(t.formFirstPayment),
        FormInput(
            controller: cubit.firstPayment,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            ltr: true),
        FieldLabel(t.formMonthlyAmount),
        FormInput(
            controller: cubit.monthlyAmount,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            ltr: true),
        FieldLabel(t.formPeriod),
        FormInput(
            controller: cubit.period,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            maxLength: 2,
            ltr: true),
        FieldLabel(t.formWorkType),
        Segmented(
          options: [t.workPrivate, t.workGovernmental],
          selectedIndex: switch (state.workType) {
            'private' => 0,
            'governmental' => 1,
            _ => -1,
          },
          onSelected: (i) => cubit.setWorkType(i == 0 ? 'private' : 'governmental'),
        ),
        if (state.errors['workType'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(t.authRequiredField,
                style: const TextStyle(color: Color(0xFFE5484D), fontSize: 11.5)),
          ),
        PickerField<BankOffer>(
          label: t.formSalaryBank,
          value: sheet.state.banks
              .where((b) => b.bankId == state.salaryBankId)
              .firstOrNull,
          items: sheet.state.banks,
          labelOf: (b) => b.name(lang),
          onChanged: (b) => cubit.setSalaryBank(b.bankId),
          error: _errText(context, state.errors['salaryBank']),
        ),
        yesNo(t.financeQ1, state.q1, (v) => cubit.setQuestion(1, v)),
        yesNo(t.financeQ2, state.q2, (v) => cubit.setQuestion(2, v)),
        if (state.q2 == 1) ...[
          FieldLabel(t.formViolationsAmount),
          FormInput(
              controller: cubit.violations,
              keyboardType: TextInputType.number,
              digitsOnly: true,
              ltr: true),
        ],
        yesNo(t.financeQ3, state.q3, (v) => cubit.setQuestion(3, v)),
        yesNo(t.financeQ4, state.q4, (v) => cubit.setQuestion(4, v)),
        if (state.q4 == 1) ...[
          FieldLabel(t.formObligationsAmount),
          FormInput(
              controller: cubit.obligations,
              keyboardType: TextInputType.number,
              digitsOnly: true,
              ltr: true),
        ],
        if (state.errors['questions'] != null)
          Padding(
            padding: EdgeInsets.only(top: context.rs(8)),
            child: Text(t.errAnswerAll,
                style: const TextStyle(color: Color(0xFFE5484D), fontSize: 11.5)),
          ),
        _submitBar(context, busy: false, onSubmit: cubit.next, label: t.formNext),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }
}

final class _FinanceDocs extends StatelessWidget {
  const _FinanceDocs({super.key, required this.banks});

  final List<BankOffer> banks;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<FinanceFormCubit>();
    final state = context.watch<FinanceFormCubit>().state;
    final sheet = context.read<CarSheetCubit>();

    Future<void> submit() async {
      final res = await cubit.submit();
      if (res != null && context.mounted) sheet.showSuccess(res.reference);
    }

    final docLabels = {
      'identityImage': t.docIdentity,
      'license': t.docLicense,
      'insurance': t.docInsurance,
      'accountStatement': t.docAccount,
      'salaryDefinitionLetter': t.docSalary,
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
      children: [
        // Financing entity — the "Pick a bank" cards, not a dropdown.
        // Optional, like the website (bankID may be omitted).
        FieldLabel(t.formFinanceBank),
        BankCardList(
          banks: banks,
          selectedBankId: state.financeBankId,
          onSelect: cubit.setFinanceBank,
        ),
        SizedBox(height: context.rs(6)),
        for (final key in cubit.requiredDocKeys) ...[
          FieldLabel(docLabels[key] ?? key),
          _DocTile(
            uploaded: state.docs.containsKey(key),
            error: _errText(context, state.errors[key]),
            onPick: () => cubit.pickDoc(key),
            onRemove: () => cubit.removeDoc(key),
          ),
        ],
        FieldLabel(t.formNote),
        FormInput(controller: cubit.message),
        _serverError(context, state.serverError),
        _submitBar(context, busy: state.busy, onSubmit: submit),
        SizedBox(height: context.rs(10)),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }
}

final class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.uploaded,
    required this.onPick,
    required this.onRemove,
    this.error,
  });

  final bool uploaded;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: Icon(
                  uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  size: 18,
                  color: uploaded ? const Color(0xFF18A957) : null,
                ),
                label: Text(uploaded ? t.docReplace : t.docUpload),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(context.rs(46)),
                  side: BorderSide(
                    color: uploaded
                        ? const Color(0xFF18A957)
                        : scheme.outline.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            if (uploaded)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error!,
                style: const TextStyle(color: Color(0xFFE5484D), fontSize: 11.5)),
          ),
      ],
    );
  }
}

/* ─────────────────────────── Success page ─────────────────────────── */

final class SheetSuccess extends StatelessWidget {
  const SheetSuccess({super.key, required this.vehicle});

  final OnlineVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<CarSheetCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    final message = switch (state.method) {
      PurchaseMethod.reserve => t.successReserve,
      PurchaseMethod.finance => t.successFinance,
      PurchaseMethod.contact => t.successContact,
    };

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
          Text(t.successTitle,
              style:
                  TextStyle(fontSize: context.rf(20), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(8)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.rf(13),
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          if (state.reference != null) ...[
            SizedBox(height: context.rs(14)),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(16), vertical: context.rs(8)),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${t.successRef}: ${state.reference}',
                style: TextStyle(
                    fontSize: context.rf(13),
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ],
          SizedBox(height: context.rs(26)),
          // Deposit paid → continue the purchase steps (website's
          // /car/complete/{orderGuid} continuation).
          if ((state.orderGuid ?? '').isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () =>
                  PurchaseCompleteScreen.open(context, state.orderGuid!),
              style:
                  FilledButton.styleFrom(minimumSize: Size(context.rs(220), 50)),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(t.cpcCompletePurchase),
            ),
            SizedBox(height: context.rs(10)),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                  minimumSize: Size(context.rs(220), 48)),
              child: Text(t.successClose),
            ),
          ] else
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style:
                  FilledButton.styleFrom(minimumSize: Size(context.rs(180), 50)),
              child: Text(t.successClose),
            ),
        ],
      ),
    );
  }
}


/// MyFatoorah gateway for the car down-payment — intercepts the app
/// callback; the reservation SP already captured the payment, so a return
/// with OrderGUID / PaymentType=full IS success (same recognition as the
/// website's /payment/callback).
final class _OnlineGatewayPage extends StatefulWidget {
  const _OnlineGatewayPage({required this.url});

  final String url;

  @override
  State<_OnlineGatewayPage> createState() => _OnlineGatewayPageState();
}

final class _OnlineGatewayPageState extends State<_OnlineGatewayPage> {
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
            final guid = params['OrderGUID'] ?? params['orderGUID'];
            final full =
                (params['PaymentType'] ?? '').toLowerCase() == 'full';
            Navigator.of(context).pop(((guid ?? '').isNotEmpty || full, guid));
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
              onPressed: () => Navigator.of(context).pop((false, null)),
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
