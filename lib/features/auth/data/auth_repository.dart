import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/utils/crypto.dart';
import '../domain/app_user.dart';

/// Access-type detection — a 1:1 port of the website AuthPopup's
/// detectAccessType: email → password flow, 10-digit 1x/2x → IdentityNo,
/// everything else normalized to +966 phone → OTP flow.
typedef DetectedAccess = ({String type, String normalized});

DetectedAccess? detectAccessType(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return null;
  if (RegExp(r'[a-zA-Z@]').hasMatch(v)) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return null;
    return (type: 'Email', normalized: v.toLowerCase());
  }
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10 && (digits.startsWith('1') || digits.startsWith('2'))) {
    return (type: 'IdentityNo', normalized: digits);
  }
  if (v.startsWith('+')) {
    return (type: 'PhoneNumber', normalized: v.replaceAll(RegExp(r'\s'), ''));
  }
  if (digits.length == 9) return (type: 'PhoneNumber', normalized: '+966$digits');
  if (digits.length == 10 && digits.startsWith('05')) {
    return (type: 'PhoneNumber', normalized: '+966${digits.substring(1)}');
  }
  if (digits.length == 12 && digits.startsWith('966')) {
    return (type: 'PhoneNumber', normalized: '+$digits');
  }
  return null;
}

final class OtpSent {
  const OtpSent({required this.ok, this.maskedPhone, this.devOtp});
  final bool ok;
  final String? maskedPhone;
  final String? devOtp; // echoed by the backend in Development only
}

final class AbsherResult {
  const AbsherResult({required this.ok, this.guid, this.error});
  final bool ok;
  final String? guid;
  final String? error;
}

/// The website's auth cycle, verbatim:
///  - email + MD5 password → Site_User_SignInWithPassword
///  - phone/identity → Site_User_RequestOtp / Site_User_VerifyOtp
///  - sign-up → Absher 2-step (usp_AbsherCreateUserPrequisite_Master)
///  - forgot → phone OTP → Site_User_ResetPassword
final class AuthRepository {
  AuthRepository(this._api, this._store);

  final ApiClient _api;
  final LocalStore _store;

  AppUser? get currentUser {
    final json = _store.user;
    return json == null ? null : AppUser.fromJson(json);
  }

  Future<AppUser?> signInWithPassword({
    required String accessType,
    required String access,
    required String password,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.signIn,
        body: {
          'accessType': accessType,
          'access': access,
          'passwordMd5': md5Hex(password),
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final user = AppUser.fromJson(res.data!);
        await _store.setUser(user.toJson());
        return user;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<OtpSent> requestOtp({required String accessType, required String access}) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.otpRequest,
        body: {'accessType': accessType, 'access': access},
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return OtpSent(
          ok: data['ok'] == true,
          maskedPhone: data['phone'] as String?,
          devOtp: data['devOtp'] as String?,
        );
      }
      return const OtpSent(ok: false);
    } on DioException {
      return const OtpSent(ok: false);
    }
  }

  Future<AppUser?> verifyOtp({
    required String accessType,
    required String access,
    required String otp,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.otpVerify,
        body: {'accessType': accessType, 'access': access, 'otp': otp},
      );
      if (res.statusCode == 200 && res.data != null) {
        final user = AppUser.fromJson(res.data!);
        await _store.setUser(user.toJson());
        return user;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Absher step 1 (ActionType 3): identity + 9-digit mobile + YYYY-MM birth
  /// date → Absher sends the OTP, returns the prerequisite GUID.
  Future<AbsherResult> absherStart({
    required int identity,
    required String mobile,
    required String birthDate,
    required String lang,
  }) =>
      _absher({
        'actionType': 3,
        'insertIdentity': identity,
        'insertMobile': mobile,
        'insertDateOfBirth': birthDate,
        'insertLanguage': lang,
        'insertCreatedUser': 'MobileApp',
      });

  /// Absher step 2 (ActionType 2): confirm the OTP → account created.
  Future<AbsherResult> absherConfirm({required String guid, required int otp}) =>
      _absher({'actionType': 2, 'updateGuid': guid, 'updateAbsherOtp': otp});

  Future<AbsherResult> _absher(Map<String, dynamic> body) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(ApiPaths.absher, body: body);
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return AbsherResult(
          ok: data['ok'] == true,
          guid: data['guid'] as String?,
          error: data['error'] as String?,
        );
      }
      return const AbsherResult(ok: false);
    } on DioException {
      return const AbsherResult(ok: false, error: 'network');
    }
  }

  Future<bool> resetPassword({
    required String accessType,
    required String access,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.resetPassword,
        body: {
          'accessType': accessType,
          'access': access,
          'otp': otp,
          'newPasswordMd5': md5Hex(newPassword),
        },
      );
      return res.statusCode == 200 && res.data?['ok'] == true;
    } on DioException {
      return false;
    }
  }

  Future<void> signOut() => _store.clearUser();
}
