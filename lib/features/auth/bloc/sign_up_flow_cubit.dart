import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

/// Absher registration — the website's 2-step prerequisite flow, verbatim:
///   Step 1 (ActionType 3): Language + Identity + Mobile + Birth date → OTP.
///   Step 2 (ActionType 2): Confirm the Absher OTP → account created.
/// On success the screen returns to sign-in with the mobile prefilled.
enum SignUpStep { register, otp }

enum SignUpError { invalidIdentity, invalidMobile, invalidBirthdate, failed, invalidOtp, session }

final class SignUpFlowState extends Equatable {
  const SignUpFlowState({
    this.step = SignUpStep.register,
    this.busy = false,
    this.lang = 'ar',
    this.guid,
    this.cleanMobile = '',
    this.error,
    this.serverError,
    this.registeredMobile,
  });

  final SignUpStep step;
  final bool busy;
  final String lang; // Absher record language
  final String? guid;
  final String cleanMobile; // 9 digits
  final SignUpError? error;

  /// Verbatim SP error message (the website surfaces it as-is when present).
  final String? serverError;

  /// Set on success — screen navigates to sign-in with this mobile prefilled.
  final String? registeredMobile;

  SignUpFlowState copyWith({
    SignUpStep? step,
    bool? busy,
    String? lang,
    String? guid,
    String? cleanMobile,
    SignUpError? error,
    String? serverError,
    String? registeredMobile,
    bool clearError = false,
  }) =>
      SignUpFlowState(
        step: step ?? this.step,
        busy: busy ?? this.busy,
        lang: lang ?? this.lang,
        guid: guid ?? this.guid,
        cleanMobile: cleanMobile ?? this.cleanMobile,
        error: clearError ? null : (error ?? this.error),
        serverError: clearError ? null : (serverError ?? this.serverError),
        registeredMobile: registeredMobile ?? this.registeredMobile,
      );

  @override
  List<Object?> get props =>
      [step, busy, lang, guid, cleanMobile, error, serverError, registeredMobile];
}

final class SignUpFlowCubit extends Cubit<SignUpFlowState> {
  SignUpFlowCubit(this._repo, {required String uiLang, String? prefillMobile})
      : super(SignUpFlowState(lang: uiLang == 'en' ? 'en' : 'ar')) {
    if (prefillMobile != null && prefillMobile.isNotEmpty) {
      mobile.text = prefillMobile;
    }
  }

  final AuthRepository _repo;

  final identity = TextEditingController();
  final mobile = TextEditingController(); // 9 digits, 5xxxxxxxx
  final birthdate = TextEditingController(); // YYYY-MM
  final otp = TextEditingController();

  void setLang(String lang) => emit(state.copyWith(lang: lang));

  /// Step 1 — validations identical to the website's handleRegister.
  Future<void> register() async {
    final id = identity.text.trim();
    if (!RegExp(r'^\d+$').hasMatch(id)) {
      emit(state.copyWith(error: SignUpError.invalidIdentity));
      return;
    }
    var m = mobile.text.trim().replaceAll(RegExp(r'\s'), '');
    if (m.startsWith('0')) m = m.substring(1);
    if (!RegExp(r'^\d{9}$').hasMatch(m)) {
      emit(state.copyWith(error: SignUpError.invalidMobile));
      return;
    }
    final birth = birthdate.text.trim();
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(birth)) {
      emit(state.copyWith(error: SignUpError.invalidBirthdate));
      return;
    }

    emit(state.copyWith(busy: true, clearError: true));
    final res = await _repo.absherStart(
      identity: int.parse(id),
      mobile: m,
      birthDate: birth,
      lang: state.lang,
    );
    if (isClosed) return;
    if (res.ok && res.guid != null) {
      otp.clear();
      emit(state.copyWith(busy: false, step: SignUpStep.otp, guid: res.guid, cleanMobile: m));
    } else {
      emit(state.copyWith(busy: false, error: SignUpError.failed, serverError: res.error));
    }
  }

  /// Step 2 — confirm the Absher OTP; on success hand the mobile back.
  Future<void> confirm() async {
    final code = otp.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(code)) {
      emit(state.copyWith(error: SignUpError.invalidOtp));
      return;
    }
    final guid = state.guid;
    if (guid == null) {
      emit(state.copyWith(step: SignUpStep.register, error: SignUpError.session));
      return;
    }

    emit(state.copyWith(busy: true, clearError: true));
    final res = await _repo.absherConfirm(guid: guid, otp: int.parse(code));
    if (isClosed) return;
    if (res.ok) {
      emit(state.copyWith(busy: false, registeredMobile: state.cleanMobile));
    } else {
      emit(state.copyWith(busy: false, error: SignUpError.invalidOtp, serverError: res.error));
    }
  }

  void back() => emit(state.copyWith(step: SignUpStep.register, clearError: true));

  @override
  Future<void> close() {
    for (final c in [identity, mobile, birthdate, otp]) {
      c.dispose();
    }
    return super.close();
  }
}
