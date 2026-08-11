import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stale-while-revalidate cache for catalog GETs (the "redux-style" store):
///
///  1. First fetch → network → response cached on disk.
///  2. Later fetches → the CACHED payload is returned instantly (no network
///     wait), and the real request runs in the BACKGROUND.
///  3. The background response is diffed against the cache — when different,
///     the cache is replaced, so the next visit paints the fresh data.
///
/// Only read-only catalog endpoints are cached (allowlist below) — per-user
/// state (tracking, account, cart, complaints…) always hits the network.
/// Pass `options: Options(extra: {'fresh': true})` on a Dio call (or use
/// pull-to-refresh flows that already refetch) to bypass the stale serve.
final class SwrCacheInterceptor extends Interceptor {
  SwrCacheInterceptor(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  static const _keyPrefix = 'hj_swr:';
  static const _indexKey = 'hj_swr_index';
  static const _maxEntries = 140;
  static const _hardTtl = Duration(days: 7);

  /// Catalog endpoints that benefit from instant paint. Everything else is
  /// untouched.
  static const _allow = [
    '/api/app/vehicles/',
    '/api/app/online/vehicles',
    '/api/app/online/banks',
    '/api/app/home',
    '/api/app/offers',
    '/api/app/finance/',
    '/api/app/content',
    '/api/app/parts',
    '/api/app/protection',
    '/api/app/maintenance/periodic',
    '/api/app/maintenance/testimonials',
    '/api/app/used-cars/list',
    '/api/app/themes',
    '/api/user/settings',
    '/api/user/account-types',
  ];

  /// In-flight background revalidations, so one screen rebuilding fast
  /// doesn't stampede the API.
  final _revalidating = <String>{};

  static bool _cacheable(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' &&
      o.extra['swr-bypass'] != true &&
      _allow.any(o.path.startsWith);

  static String _key(RequestOptions o) {
    final q = o.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final qs = q.map((e) => '${e.key}=${e.value}').join('&');
    return '$_keyPrefix${o.path}?$qs';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_cacheable(options) || options.extra['fresh'] == true) {
      handler.next(options);
      return;
    }
    final key = _key(options);
    final raw = _prefs.getString(key);
    if (raw == null) {
      handler.next(options);
      return;
    }
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt =
          DateTime.tryParse('${envelope['at']}') ?? DateTime(2000);
      if (DateTime.now().difference(savedAt) > _hardTtl) {
        _prefs.remove(key);
        handler.next(options);
        return;
      }
      // Serve the stale payload instantly…
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: envelope['data'],
          extra: const {'swr': true},
        ),
        true,
      );
      // …and revalidate in the background.
      _revalidate(options, key, raw);
    } catch (_) {
      _prefs.remove(key);
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    if (_cacheable(o) &&
        response.statusCode == 200 &&
        response.extra['swr'] != true &&
        response.data != null) {
      _store(_key(o), response.data);
    }
    handler.next(response);
  }

  Future<void> _revalidate(
      RequestOptions options, String key, String currentRaw) async {
    if (!_revalidating.add(key)) return;
    try {
      final res = await _dio.fetch<dynamic>(
        options.copyWith(extra: {...options.extra, 'swr-bypass': true}),
      );
      if (res.statusCode == 200 && res.data != null) {
        final fresh = jsonEncode(res.data);
        final current = jsonEncode(
            (jsonDecode(currentRaw) as Map<String, dynamic>)['data']);
        if (fresh != current) _store(key, res.data, encoded: fresh);
      }
    } catch (_) {
      // Offline / transient — the stale payload already served the screen.
    } finally {
      _revalidating.remove(key);
    }
  }

  void _store(String key, dynamic data, {String? encoded}) {
    try {
      _prefs.setString(
        key,
        jsonEncode({
          'at': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );
      _touchIndex(key);
    } catch (_) {
      // Payload not JSON-encodable or storage full — skip caching it.
    }
  }

  /// Bounded LRU-ish index: evict the oldest entries past [_maxEntries].
  void _touchIndex(String key) {
    final index = (_prefs.getStringList(_indexKey) ?? <String>[])
      ..remove(key)
      ..add(key);
    while (index.length > _maxEntries) {
      _prefs.remove(index.removeAt(0));
    }
    _prefs.setStringList(_indexKey, index);
  }

  /// Wipe everything (e.g. on sign-out or language issues).
  static Future<void> clear(SharedPreferences prefs) async {
    for (final k in prefs.getStringList(_indexKey) ?? <String>[]) {
      await prefs.remove(k);
    }
    await prefs.remove(_indexKey);
  }
}
