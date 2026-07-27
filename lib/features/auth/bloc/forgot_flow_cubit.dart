import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

/// Forgot password — the website's ForgotPanel: phone → OTP → new password
/// (Site_User_RequestOtp → Site_User_ResetPassword).
enum ForgotStep { phone, otp, password }

enum ForgotError { invalidPhone, otpSendFailed, invalidOtp, passwordTooShort, mismatch, failed }

final class ForgotFlowState extends Equatable {
  const ForgotFlowState({
    this.step = ForgotStep.phone,
    this.busy = false,
    this.access = '',
    this.maskedPhone,
    this.devOtp,
    this.error,
    this.done = false,
  });

  final ForgotStep step;
  final bool busy;
  final String access; // normalized +966 phone
  final String? maskedPhone;
  final String? devOtp;
  final ForgotError? error;
  final bool done;

  ForgotFlowState copyWith({
    ForgotStep? step,
    bool? busy,
    String? access,
    String? maskedPhone,
    String? devOtp,
    ForgotError? error,
    bool? done,
    bool clearError = false,
  }) =>
      ForgotFlowState(
        step: step ?? this.step,
        busy: busy ?? this.busy,
        access: access ?? this.access,
        maskedPhone: maskedPhone ?? this.maskedPhone,
        devOtp: devOtp ?? this.devOtp,
        error: clearError ? null : (error ?? this.error),
        done: done ?? this.done,
      );

  @override
  List<Object?> get props => [step, busy, access, maskedPhone, devOtp, error, done];
}

final class ForgotFlowCubit extends Cubit<ForgotFlowState> {
  ForgotFlowCubit(this._repo) : super(const ForgotFlowState());

  final AuthRepository _repo;

  final phone = TextEditingController();
  final otp = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  Future<void> sendOtp() async {
    final detected = detectAccessType(phone.text);
    if (detected == null || detected.type != 'PhoneNumber') {
      emit(state.copyWith(error: ForgotError.invalidPhone));
      return;
    }
    emit(state.copyWith(busy: true, access: detected.normalized, clearError: true));
    final res = await _repo.requestOtp(accessType: 'PhoneNumber', access: detected.normalized);
    if (isClosed) return;
    if (!res.ok) {
      emit(state.copyWith(busy: false, error: ForgotError.otpSendFailed));
      return;
    }
    otp.clear();
    emit(state.copyWith(
      busy: false,
      step: ForgotStep.otp,
      maskedPhone: res.maskedPhone,
      devOtp: res.devOtp,
    ));
  }

  void submitOtp() {
    if (otp.text.trim().length < 4) {
      emit(state.copyWith(error: ForgotError.invalidOtp));
      return;
    }
    emit(state.copyWith(step: ForgotStep.password, clearError: true));
  }

  Future<void> savePassword() async {
    if (password.text.length < 6) {
      emit(state.copyWith(error: ForgotError.passwordTooShort));
      return;
    }
    if (password.text != confirm.text) {
      emit(state.copyWith(error: ForgotError.mismatch));
      return;
    }
    emit(state.copyWith(busy: true, clearError: true));
    final ok = await _repo.resetPassword(
      accessType: 'PhoneNumber',
      access: state.access,
      otp: otp.text.trim(),
      newPassword: password.text,
    );
    if (isClosed) return;
    emit(ok
        ? state.copyWith(busy: false, done: true)
        : state.copyWith(busy: false, error: ForgotError.failed));
  }

  void back() {
    emit(state.copyWith(
      step: state.step == ForgotStep.password ? ForgotStep.otp : ForgotStep.phone,
      clearError: true,
    ));
  }

  @override
  Future<void> close() {
    for (final c in [phone, otp, password, confirm]) {
      c.dispose();
    }
    return super.close();
  }
}
