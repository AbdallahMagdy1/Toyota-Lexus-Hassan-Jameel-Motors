import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../onboarding/domain/onboarding_slide.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/sign_in_flow_cubit.dart';
import 'widgets/auth_bits.dart';
import 'widgets/auth_scaffold.dart';

/// Sign-in — the website AuthPopup's state machine on the reference layout:
/// dashboard-controlled banner (image/video) + wave-topped surface panel.
final class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.prefillMobile, this.notice});

  final String? prefillMobile;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignInFlowCubit(
        sl(),
        prefillAccess: prefillMobile == null || prefillMobile!.isEmpty
            ? null
            : '0$prefillMobile',
      ),
      child: _SignInView(notice: notice),
    );
  }
}

final class _SignInView extends StatelessWidget {
  const _SignInView({this.notice});

  final String? notice;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = context.watch<ThemeCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    final brandColor = scheme.primary;

    return BlocListener<SignInFlowCubit, SignInFlowState>(
      listenWhen: (prev, next) =>
          prev.signedIn != next.signedIn || prev.goSignUpMobile != next.goSignUpMobile,
      listener: (context, state) {
        if (state.signedIn) {
          context.read<AuthBloc>().add(const AuthSessionRefreshed());
        } else if (state.goSignUpMobile != null) {
          context.go('${Routes.signUp}?mobile=${state.goSignUpMobile}&notFound=1');
        }
      },
      child: BlocBuilder<SignInFlowCubit, SignInFlowState>(
        builder: (context, state) {
          return AuthScaffold(
            placement: 'sign_in',
            title: state.step == SignInStep.otp ? t.authOtpTitle : t.authSignIn,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notice == 'registered') ...[
                    NoticeBanner(text: t.authRegisteredNotice, color: brandColor),
                    SizedBox(height: context.rs(14)),
                  ] else if (notice == 'reset') ...[
                    NoticeBanner(text: t.forgotDoneNotice, color: brandColor),
                    SizedBox(height: context.rs(14)),
                  ],
                  if (state.step == SignInStep.otp) ...[
                    Text(
                      '${t.authOtpSentTo} ${state.maskedPhone ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.rf(12.5),
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: context.rs(14)),
                  ],
                  ..._step(context, state, t, theme.brandKey),
                  SizedBox(height: context.rs(24)),
                ],
              )
                  .animate(key: ValueKey(state.step))
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.03, end: 0, duration: 300.ms),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _step(BuildContext context, SignInFlowState state,
      AppLocalizations t, String brandKey) {
    final cubit = context.read<SignInFlowCubit>();
    final scheme = Theme.of(context).colorScheme;

    String? fieldError(String? key) => switch (key) {
          'required' => t.authRequiredField,
          'invalidEmail' => t.authInvalidEmail,
          'invalidPhone' => t.authInvalidPhone,
          _ => null,
        };
    String? errorText() => switch (state.error) {
          SignInError.invalidAccess => t.authInvalidAccess,
          SignInError.invalidCredentials => t.authInvalidCredentials,
          SignInError.invalidOtp => t.authOtpInvalid,
          SignInError.network => t.authNetworkError,
          null => null,
        };

    Widget primaryButton({required VoidCallback onPressed, required String label}) =>
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

    switch (state.step) {
      case SignInStep.input:
        return [
          AuthTextField(
            label: t.authEmailOrPhone,
            hint: t.authEmailOrPhoneHint,
            controller: cubit.identifier,
            errorText: fieldError(state.error == SignInError.invalidAccess
                ? 'required'
                : null),
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: context.rs(10)),
          if (error != null) ...[ErrorBanner(text: error), SizedBox(height: context.rs(10))],
          primaryButton(onPressed: cubit.continueFromInput, label: t.authContinue),
          SizedBox(height: context.rs(12)),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
              side: BorderSide(color: scheme.primary),
              foregroundColor: scheme.primary,
            ),
            onPressed: state.busy
                ? null
                : () => context.read<AuthBloc>().add(const AuthGuestRequested()),
            child: Text(t.authContinueAsGuest),
          ),
          SizedBox(height: context.rs(18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.authNoAccount,
                  style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: context.rf(12.5))),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.go(Routes.signUp),
                child: Text(t.authSignUp,
                    style: TextStyle(
                        color: scheme.primary,
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ];

      case SignInStep.password:
        return [
          AuthTextField(
            label: t.authPassword,
            hint: '••••••••',
            controller: cubit.password,
            errorText: fieldError(state.error == null ? null : null),
            obscure: true,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline_rounded,
            textDirection: TextDirection.ltr,
            trailingLabel: GestureDetector(
              onTap: () => context.go(Routes.forgot),
              child: Text(
                t.authForgotPassword,
                style: TextStyle(
                    fontSize: context.rf(11.5),
                    fontWeight: FontWeight.w700,
                    color: scheme.primary),
              ),
            ),
          ),
          SizedBox(height: context.rs(10)),
          if (error != null) ...[ErrorBanner(text: error), SizedBox(height: context.rs(10))],
          primaryButton(onPressed: cubit.submitPassword, label: t.authSignIn),
          TextButton(onPressed: cubit.back, child: Text(t.authBack)),
        ];

      case SignInStep.otp:
        return [
          // Dashboard-controlled OTP slide (placement 'otp').
          FutureBuilder<List<OnboardingSlide>>(
            future: sl<OnboardingRepository>()
                .fetch(sl<ThemeCubit>().state.brandKey, placement: 'otp'),
            builder: (context, snap) => OtpSlidePanel(
              slides: snap.data ?? const [],
              lang: sl<LocaleCubit>().state.languageCode,
              brandKey: sl<ThemeCubit>().state.brandKey,
            ),
          ),
          OtpField(
            controller: cubit.otp,
            focusColor: scheme.primary,
            onSubmitted: (_) => cubit.submitOtp(),
          ),
          if (state.devOtp != null) ...[
            SizedBox(height: context.rs(6)),
            Text(
              t.authDevOtpHint(state.devOtp!),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  fontSize: context.rf(11)),
            ),
          ],
          SizedBox(height: context.rs(10)),
          if (error != null) ...[ErrorBanner(text: error), SizedBox(height: context.rs(10))],
          primaryButton(onPressed: cubit.submitOtp, label: t.authSignIn),
          TextButton(
            onPressed: state.busy ? null : cubit.resendOtp,
            child: Text(t.authOtpResend),
          ),
          TextButton(onPressed: cubit.back, child: Text(t.authBack)),
        ];
    }
  }
}