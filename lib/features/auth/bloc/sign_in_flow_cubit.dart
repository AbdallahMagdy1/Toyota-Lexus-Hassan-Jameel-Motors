import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

/// Mirrors the website AuthPopup's SignInPanel state machine:
///   input → (Email)    → password → signInWithPassword
///         → (Phone/Id) → requestOtp → otp → verifyOtp
/// requestOtp failing with user-not-found redirects to Absher sign-up with
/// the mobile prefilled (the website's onNotFound behavior).
enum SignInStep { input, password, otp }

enum SignInError { invalidAccess, invalidCredentials, invalidOtp, network }

final class SignInFlowState extends Equatable {
  const SignInFlowState({
    this.step = SignInStep.input,
    this.busy = false,
    this.accessType = 'PhoneNumber',
    this.access = '',
    this.maskedPhone,
    this.devOtp,
    this.error,
    this.goSignUpMobile,
    this.signedIn = false,
  });

  final SignInStep step;
  final bool busy;
  final String accessType;
  final String access; // normalized (+966…, lowercase email, identity digits)
  final String? maskedPhone;
  final String? devOtp;
  final SignInError? error;

  /// Set when no account exists for the phone/identity → the screen
  /// navigates to sign-up with this mobile (9 digits) prefilled.
  final String? goSignUpMobile;

  /// Set after a successful sign-in — screen raises AuthSessionRefreshed.
  final bool signedIn;

  SignInFlowState copyWith({
    SignInStep? step,
    bool? busy,
    String? accessType,
    String? access,
    String? maskedPhone,
    String? devOtp,
    SignInError? error,
    String? goSignUpMobile,
    bool? signedIn,
    bool clearError = false,
  }) =>
      SignInFlowState(
        step: step ?? this.step,
        busy: busy ?? this.busy,
        accessType: accessType ?? this.accessType,
        access: access ?? this.access,
        maskedPhone: maskedPhone ?? this.maskedPhone,
        devOtp: devOtp ?? this.devOtp,
        error: clearError ? null : (error ?? this.error),
        goSignUpMobile: goSignUpMobile ?? this.goSignUpMobile,
        signedIn: signedIn ?? this.signedIn,
      );

  @override
  List<Object?> get props =>
      [step, busy, accessType, access, maskedPhone, devOtp, error, goSignUpMobile, signedIn];
}

final class SignInFlowCubit extends Cubit<SignInFlowState> {
  SignInFlowCubit(this._repo, {String? prefillAccess}) : super(const SignInFlowState()) {
    if (prefillAccess != null && prefillAccess.isNotEmpty) {
      identifier.text = prefillAccess;
    }
  }

  final AuthRepository _repo;

  final identifier = TextEditingController();
  final password = TextEditingController();
  final otp = TextEditingController();

  /// Step 1 — detect the access type; email goes to the password step,
  /// phone/identity requests an OTP.
  Future<void> continueFromInput() async {
    final detected = detectAccessType(identifier.text);
    if (detected == null) {
      emit(state.copyWith(error: SignInError.invalidAccess));
      return;
    }
    if (detected.type == 'Email') {
      emit(state.copyWith(
        step: SignInStep.password,
        accessType: detected.type,
        access: detected.normalized,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(busy: true, accessType: detected.type, access: detected.normalized, clearError: true));
    final res = await _repo.requestOtp(accessType: detected.type, access: detected.normalized);
    if (isClosed) return;
    if (!res.ok) {
      // No account for this phone / identity → sign-up, prefilled (website behavior).
      final mobile = detected.type == 'PhoneNumber'
          ? detected.normalized.replaceFirst('+966', '')
          : '';
      emit(state.copyWith(busy: false, goSignUpMobile: mobile));
      return;
    }
    otp.clear();
    emit(state.copyWith(
      busy: false,
      step: SignInStep.otp,
      maskedPhone: res.maskedPhone,
      devOtp: res.devOtp,
    ));
  }

  Future<void> submitPassword() async {
    if (password.text.isEmpty) return;
    emit(state.copyWith(busy: true, clearError: true));
    final user = await _repo.signInWithPassword(
      accessType: state.accessType,
      access: state.access,
      password: password.text,
    );
    if (isClosed) return;
    emit(user == null
        ? state.copyWith(busy: false, error: SignInError.invalidCredentials)
        : state.copyWith(busy: false, signedIn: true));
  }

  Future<void> submitOtp() async {
    final code = otp.text.trim();
    if (code.length < 4) return;
    emit(state.copyWith(busy: true, clearError: true));
    final user = await _repo.verifyOtp(
      accessType: state.accessType,
      access: state.access,
      otp: code,
    );
    if (isClosed) return;
    emit(user == null
        ? state.copyWith(busy: false, error: SignInError.invalidOtp)
        : state.copyWith(busy: false, signedIn: true));
  }

  Future<void> resendOtp() async {
    emit(state.copyWith(busy: true, clearError: true));
    final res = await _repo.requestOtp(accessType: state.accessType, access: state.access);
    if (isClosed) return;
    emit(state.copyWith(busy: false, maskedPhone: res.maskedPhone, devOtp: res.devOtp));
  }

  void back() => emit(state.copyWith(step: SignInStep.input, clearError: true));

  @override
  Future<void> close() {
    identifier.dispose();
    password.dispose();
    otp.dispose();
    return super.close();
  }
}
