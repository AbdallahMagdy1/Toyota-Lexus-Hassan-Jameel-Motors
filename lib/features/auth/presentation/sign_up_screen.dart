import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/sign_up_flow_cubit.dart';
import 'widgets/auth_bits.dart';
import 'widgets/auth_scaffold.dart';

/// Absher registration — the website's SignUpPanel on the reference layout:
/// dashboard-controlled banner + wave-topped surface panel.
///   Step 1 (ActionType 3): Language + Identity + Mobile + Birth date → OTP.
///   Step 2 (ActionType 2): Confirm the Absher OTP → account created.
final class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key, this.prefillMobile, this.notFound = false});

  final String? prefillMobile;
  final bool notFound;

  @override
  Widget build(BuildContext context) {
    final uiLang = context.read<LocaleCubit>().state.languageCode;
    return BlocProvider(
      create: (_) =>
          SignUpFlowCubit(sl(), uiLang: uiLang, prefillMobile: prefillMobile),
      child: _SignUpView(notFound: notFound),
    );
  }
}

final class _SignUpView extends StatelessWidget {
  const _SignUpView({required this.notFound});

  final bool notFound;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return BlocListener<SignUpFlowCubit, SignUpFlowState>(
      listenWhen: (prev, next) =>
          prev.registeredMobile != next.registeredMobile,
      listener: (context, state) {
        if (state.registeredMobile != null) {
          // Website behavior: switch to sign-in with the registered mobile
          // prefilled + a success notice.
          context.go(
              '${Routes.signIn}?mobile=${state.registeredMobile}&notice=registered');
        }
      },
      child: BlocBuilder<SignUpFlowCubit, SignUpFlowState>(
        builder: (context, state) {
          final cubit = context.read<SignUpFlowCubit>();
          final scheme = Theme.of(context).colorScheme;
          return AuthScaffold(
            placement: 'sign_up',
            title: t.absherTitle,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.step == SignUpStep.register
                        ? t.absherStep1
                        : t.absherStep2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontSize: context.rf(12)),
                  ),
                  SizedBox(height: context.rs(12)),
                  if (notFound) ...[
                    NoticeBanner(text: t.authNotFoundNotice, color: scheme.primary),
                    SizedBox(height: context.rs(12)),
                  ],
                  StepProgress(
                      step: state.step == SignUpStep.register ? 1 : 2,
                      color: scheme.primary),
                  SizedBox(height: context.rs(16)),
                  ..._buildStep(context, cubit, state, t),
                  SizedBox(height: context.rs(24)),
                ],
              )
                  .animate(key: ValueKey(state.step))
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(
                      begin: 0.03,
                      end: 0,
                      duration: 300.ms,
                      curve: Curves.easeOutCubic),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildStep(
    BuildContext context,
    SignUpFlowCubit cubit,
    SignUpFlowState state,
    AppLocalizations t,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    // Prefer the SP's verbatim message (the website surfaces it as-is).
    String? errorText() {
      if (state.serverError != null &&
          state.serverError!.isNotEmpty &&
          state.serverError != 'network' &&
          state.serverError != 'absher_send_failed') {
        return state.serverError;
      }
      return switch (state.error) {
        SignUpError.invalidIdentity => t.absherInvalidIdentity,
        SignUpError.invalidMobile => t.absherInvalidMobile,
        SignUpError.invalidBirthdate => t.absherInvalidBirthdate,
        SignUpError.failed => t.absherFailed,
        SignUpError.invalidOtp => t.absherOtpInvalid,
        SignUpError.session => t.absherSessionExpired,
        null => null,
      };
    }

    Widget primaryButton(
            {required VoidCallback onPressed, required String label}) =>
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: const StadiumBorder(),
          ),
          onPressed: state.busy ? null : onPressed,
          child: state.busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4))
              : Text(label),
        );

    final error = errorText();

    if (state.step == SignUpStep.register) {
      return [
        // Language — the Absher record language, like the website's select.
        AppDropdown<String>(
          label: t.absherLanguage,
          value: state.lang,
          items: [
            AppDropdownItem(value: 'ar', label: t.absherArabic),
            AppDropdownItem(value: 'en', label: t.absherEnglish),
          ],
          onChanged: (v) => cubit.setLang(v),
        ),
        SizedBox(height: context.rs(14)),
        AuthTextField(
          label: t.absherIdentity,
          hint: '1xxxxxxxxx',
          controller: cubit.identity,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.badge_outlined,
          textDirection: TextDirection.ltr,
        ),
        SizedBox(height: context.rs(14)),
        // Mobile with the fixed +966 prefix, exactly like the website.
        Text(t.absherMobile.toUpperCase(),
            style: TextStyle(
                fontSize: context.rf(11),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: muted)),
        SizedBox(height: context.rs(6)),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Container(
                height: context.rs(50),
                padding: EdgeInsets.symmetric(horizontal: context.rs(14)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.7)),
                ),
                child: Text('+966',
                    style: TextStyle(
                        color: muted,
                        fontSize: context.rf(14),
                        fontWeight: FontWeight.w700)),
              ),
              SizedBox(width: context.rs(8)),
              Expanded(
                child: TextField(
                  controller: cubit.mobile,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(hintText: '5xxxxxxxx'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(14)),
        AuthTextField(
          label: t.absherBirthdate,
          hint: t.absherBirthdateHint,
          controller: cubit.birthdate,
          keyboardType: TextInputType.datetime,
          prefixIcon: Icons.cake_outlined,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
        ),
        SizedBox(height: context.rs(10)),
        if (error != null) ...[
          ErrorBanner(text: error),
          SizedBox(height: context.rs(10))
        ],
        primaryButton(onPressed: cubit.register, label: t.absherRegister),
        TextButton(
          onPressed: () => context.go(Routes.signIn),
          child: Text(t.absherHaveAccount),
        ),
      ];
    }

    // OTP step.
    return [
      Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.rs(14), vertical: context.rs(10)),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user_outlined, size: 16, color: scheme.primary),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: Text(t.absherOtpSent,
                  style: TextStyle(fontSize: context.rf(12))),
            ),
          ],
        ),
      ),
      SizedBox(height: context.rs(16)),
      OtpField(
        controller: cubit.otp,
        focusColor: scheme.primary,
        onSubmitted: (_) => cubit.confirm(),
      ),
      SizedBox(height: context.rs(10)),
      if (error != null) ...[
        ErrorBanner(text: error),
        SizedBox(height: context.rs(10))
      ],
      primaryButton(onPressed: cubit.confirm, label: t.absherConfirm),
      TextButton(onPressed: cubit.back, child: Text(t.authBack)),
    ];
  }
}
