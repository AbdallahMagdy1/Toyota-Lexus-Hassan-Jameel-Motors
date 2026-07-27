import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/brand_backdrop.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/forgot_flow_cubit.dart';
import 'widgets/auth_bits.dart';

/// Forgot password — the website's ForgotPanel: phone → OTP → new password.
final class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotFlowCubit(sl()),
      child: const _ForgotView(),
    );
  }
}

final class _ForgotView extends StatelessWidget {
  const _ForgotView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = context.watch<ThemeCubit>().state;
    final brandColor = theme.brand.colorFor(Brightness.dark);

    return BlocListener<ForgotFlowCubit, ForgotFlowState>(
      listenWhen: (prev, next) => prev.done != next.done,
      listener: (context, state) {
        if (state.done) context.go('${Routes.signIn}?notice=reset');
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          BrandBackdrop(brand: theme.brand),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: context.pagePadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: BlocBuilder<ForgotFlowCubit, ForgotFlowState>(
                    builder: (context, state) {
                      final cubit = context.read<ForgotFlowCubit>();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BrandLogo(height: context.rs(38), forceDark: true),
                          SizedBox(height: context.rs(16)),
                          Text(
                            t.forgotTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: context.rf(22),
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.step == ForgotStep.otp
                                ? '${t.authOtpSentTo} ${state.maskedPhone ?? ''}'
                                : t.forgotSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          StepProgress(
                            step: switch (state.step) {
                              ForgotStep.phone => 1,
                              ForgotStep.otp => 2,
                              ForgotStep.password => 3,
                            },
                            total: 3,
                            color: brandColor,
                          ),
                          const SizedBox(height: 22),
                          ..._buildStep(context, cubit, state, t, theme, brandColor),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go(Routes.signIn),
                            style: TextButton.styleFrom(foregroundColor: Colors.white70),
                            child: Text(t.authBack),
                          ),
                        ],
                      )
                          .animate(key: ValueKey(state.step))
                          .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                          .slideY(
                              begin: 0.03,
                              end: 0,
                              duration: 350.ms,
                              curve: Curves.easeOutCubic);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStep(
    BuildContext context,
    ForgotFlowCubit cubit,
    ForgotFlowState state,
    AppLocalizations t,
    dynamic theme,
    Color brandColor,
  ) {
    final onBrand = theme.brand.foregroundFor(Brightness.dark) as Color;

    String? errorText() => switch (state.error) {
          ForgotError.invalidPhone => t.authInvalidPhone,
          ForgotError.otpSendFailed => t.forgotSendFailed,
          ForgotError.invalidOtp => t.authOtpInvalid,
          ForgotError.passwordTooShort => t.authPasswordTooShort,
          ForgotError.mismatch => t.authPasswordsDontMatch,
          ForgotError.failed => t.forgotFailed,
          null => null,
        };

    Widget primaryButton({required VoidCallback onPressed, required String label}) =>
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: brandColor, foregroundColor: onBrand),
          onPressed: state.busy ? null : onPressed,
          child: state.busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Text(label),
        );

    final error = errorText();

    switch (state.step) {
      case ForgotStep.phone:
        return [
          AuthTextField(
            label: t.forgotPhone,
            hint: '05xxxxxxxx',
            controller: cubit.phone,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_iphone_rounded,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          if (error != null) ...[ErrorBanner(text: error), const SizedBox(height: 12)],
          primaryButton(onPressed: cubit.sendOtp, label: t.forgotSendCode),
        ];

      case ForgotStep.otp:
        return [
          OtpField(
            controller: cubit.otp,
            focusColor: brandColor,
            onSubmitted: (_) => cubit.submitOtp(),
          ),
          if (state.devOtp != null) ...[
            const SizedBox(height: 8),
            Text(
              t.authDevOtpHint(state.devOtp!),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 12),
          if (error != null) ...[ErrorBanner(text: error), const SizedBox(height: 12)],
          primaryButton(onPressed: cubit.submitOtp, label: t.authContinue),
        ];

      case ForgotStep.password:
        return [
          AuthTextField(
            label: t.forgotNewPassword,
            hint: '••••••••',
            controller: cubit.password,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 18),
          AuthTextField(
            label: t.forgotConfirmPassword,
            hint: '••••••••',
            controller: cubit.confirm,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          if (error != null) ...[ErrorBanner(text: error), const SizedBox(height: 12)],
          primaryButton(onPressed: cubit.savePassword, label: t.forgotSave),
        ];
    }
  }
}
