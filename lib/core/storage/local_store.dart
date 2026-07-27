import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences facade. Mirrors the website's localStorage keys
/// (hj_lang, hj_theme, user) so the mental model stays identical.
final class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kLang = 'hj_lang';
  static const _kThemeMode = 'hj_theme'; // system | light | dark
  static const _kBrand = 'hj_brand'; // toyota | lexus
  static const _kThemesCache = 'hj_themes_cache'; // JSON list from /api/app/themes
  static const _kOnboardingDone = 'hj_onboarding_done';
  static const _kUser = 'hj_user'; // JSON UserDto, same as the website session

  String? get lang => _prefs.getString(_kLang);
  Future<void> setLang(String v) => _prefs.setString(_kLang, v);

  String? get themeMode => _prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String v) => _prefs.setString(_kThemeMode, v);

  String? get brand => _prefs.getString(_kBrand);
  Future<void> setBrand(String v) => _prefs.setString(_kBrand, v);

  List<dynamic>? get themesCache {
    final raw = _prefs.getString(_kThemesCache);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setThemesCache(List<dynamic> themes) =>
      _prefs.setString(_kThemesCache, jsonEncode(themes));

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  Map<String, dynamic>? get user {
    final raw = _prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setUser(Map<String, dynamic> u) =>
      _prefs.setString(_kUser, jsonEncode(u));

  Future<void> clearUser() async {
    await _prefs.remove(_kUser);
  }

  static const _kFavorites = 'hj_favorites'; // car slugs
  static const _kCart = 'hj_cart'; // car slugs

  List<String> get favorites => _prefs.getStringList(_kFavorites) ?? const [];
  Future<void> setFavorites(List<String> v) =>
      _prefs.setStringList(_kFavorites, v);

  List<String> get cart => _prefs.getStringList(_kCart) ?? const [];
  Future<void> setCart(List<String> v) => _prefs.setStringList(_kCart, v);

  static const _kPartsCart = 'hj_parts_cart'; // spare-part cart lines (json)

  List<String> get partsCart => _prefs.getStringList(_kPartsCart) ?? const [];
  Future<void> setPartsCart(List<String> v) =>
      _prefs.setStringList(_kPartsCart, v);
}
