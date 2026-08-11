import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../domain/profile_models.dart';

/// `(ok, error)` of the account-update endpoints ('phone_exists', …).
typedef ProfileActionResult = ({bool ok, String? error});

const ProfileActionResult _failed = (ok: false, error: 'network');

/// The website's /profile cycle against HJ.Mobile.Api — full user record,
/// lookups, and the Site_User_Update* actions. Lookups are memoized for the
/// app lifetime (they're static ERP tables).
final class ProfileRepository {
  ProfileRepository(this._api, this._store);

  final ApiClient _api;
  final LocalStore _store;

  static ProfileSettings? _settingsMemo;
  static List<AccountType>? _typesMemo;

  /// GET /api/user/{guid} — also refreshes the persisted session JSON so
  /// AuthBloc's [AuthSessionRefreshed] re-reads the up-to-date user.
  Future<ProfileUser?> fetchUser(String guid) async {
    try {
      final res = await _api
          .get<Map<String, dynamic>>('${ApiPaths.userByGuid}/$guid');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final user = ProfileUser.fromJson(data);
        if (user.guid.isNotEmpty && user.userId > 0) {
          await _store.setUser(data);
        }
        return user;
      }
    } on DioException {
      // fall through
    }
    return null;
  }

  Future<ProfileSettings?> settings() async {
    if (_settingsMemo != null) return _settingsMemo;
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.userSettings);
      if (res.statusCode == 200 && res.data != null) {
        return _settingsMemo = ProfileSettings.fromJson(res.data!);
      }
    } on DioException {
      // fall through
    }
    return null;
  }

  Future<List<AccountType>?> accountTypes() async {
    if (_typesMemo != null) return _typesMemo;
    try {
      final res = await _api.get<List<dynamic>>(ApiPaths.userAccountTypes);
      if (res.statusCode == 200 && res.data != null) {
        return _typesMemo = res.data!
            .whereType<Map<String, dynamic>>()
            .map(AccountType.fromJson)
            .toList();
      }
    } on DioException {
      // fall through
    }
    return null;
  }

  Future<ProfileActionResult> updateProfile({
    required String guid,
    String? firstNameAr,
    String? middleNameAr,
    String? lastNameAr,
    String? firstNameEn,
    String? middleNameEn,
    String? lastNameEn,
    int? genderId,
    String? countryId,
    String? cityId,
    String? address,
  }) =>
      _action(ApiPaths.userUpdateProfile, {
        'guid': guid,
        'firstNameAr': firstNameAr,
        'middleNameAr': middleNameAr,
        'lastNameAr': lastNameAr,
        'firstNameEn': firstNameEn,
        'middleNameEn': middleNameEn,
        'lastNameEn': lastNameEn,
        'genderId': genderId,
        'countryId': countryId,
        'cityId': cityId,
        'address': address,
      });

  Future<ProfileActionResult> updateIdentity({
    required String guid,
    String? identity,
    String? cr,
    String? custGroupId,
    String? identityImage,
    String? crImage,
  }) =>
      _action(ApiPaths.userUpdateIdentity, {
        'guid': guid,
        'identity': identity,
        'cr': cr,
        'custGroupId': custGroupId,
        'identityImage': identityImage,
        'crImage': crImage,
      });

  Future<ProfileActionResult> updatePassword({
    required String guid,
    String? oldPasswordMd5,
    required String newPasswordMd5,
  }) =>
      _action(ApiPaths.userUpdatePassword, {
        'guid': guid,
        'oldPasswordMd5': oldPasswordMd5,
        'newPasswordMd5': newPasswordMd5,
      });

  Future<ProfileActionResult> updatePhone(
          {required String guid, required String phone}) =>
      _action(ApiPaths.userUpdatePhone, {'guid': guid, 'phone': phone});

  Future<ProfileActionResult> updateEmail(
          {required String guid, required String email}) =>
      _action(ApiPaths.userUpdateEmail, {'guid': guid, 'email': email});

  Future<bool> deleteAccount(String guid) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
          '${ApiPaths.userDeleteAccount}?guid=$guid');
      return res.statusCode == 200 && res.data?['ok'] == true;
    } on DioException {
      return false;
    }
  }

  /// Server notification history — Web_Notify rows for this user.
  Future<List<ServerNotification>?> notifications(String guid) async {
    try {
      final res = await _api
          .get<List<dynamic>>('${ApiPaths.accountNotifications}/$guid');
      if (res.statusCode == 200 && res.data != null) {
        return res.data!
            .whereType<Map<String, dynamic>>()
            .map(ServerNotification.fromJson)
            .toList();
      }
    } on DioException {
      // fall through
    }
    return null;
  }

  Future<ProfileActionResult> _action(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(path, body: body);
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return (ok: data['ok'] == true, error: data['error'] as String?);
      }
      return _failed;
    } on DioException {
      return _failed;
    }
  }
}
