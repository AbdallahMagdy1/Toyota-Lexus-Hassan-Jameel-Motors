import 'dart:convert' show base64Decode;
import 'dart:typed_data' show Uint8List;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';

/// The signed-in user's photo, app-wide.
///
/// The profile screen owns its own copy through ProfileCubit, but the side
/// menu and the home app bar render long before that screen is ever opened —
/// so the photo lives here once and every surface reads it. Web_Users.Logo is
/// a blob, not a URL, so it cannot be handed to Image.network and has to be
/// fetched and decoded once rather than per widget.
///
/// State is the decoded bytes, or null for "no photo / not loaded".
final class AvatarCubit extends Cubit<Uint8List?> {
  AvatarCubit(this._api) : super(null);

  final ApiClient _api;

  /// The guid the current state belongs to — guards against refetching on
  /// every rebuild, and against showing the previous user's face after a
  /// sign-out/sign-in.
  String? _guid;
  bool _busy = false;

  /// Idempotent: safe to call from every build of every avatar widget.
  Future<void> ensure(String? guid) async {
    final g = (guid ?? '').trim();
    if (g.isEmpty) {
      // Signed out — drop the photo so the next account starts clean.
      if (_guid != null || state != null) {
        _guid = null;
        if (!isClosed) emit(null);
      }
      return;
    }
    if (g == _guid || _busy) return;
    _busy = true;
    try {
      final res = await _api.get<Map<String, dynamic>>('${ApiPaths.userImage}/$g');
      final b64 = res.data?['logo'] as String?;
      if (isClosed) return;
      emit(b64 == null || b64.isEmpty ? null : base64Decode(b64));
      // Only mark it settled once it actually succeeded — otherwise a single
      // offline moment at launch would keep the photo hidden for the whole
      // session, since every later call would see the guid as already done.
      _guid = g;
    } on DioException {
      // Offline or the endpoint is down — keep the initial-letter fallback
      // and let the next avatar that mounts try again.
    } on FormatException {
      // Corrupt/legacy value in the column — do not retry that forever.
      _guid = g;
    } finally {
      _busy = false;
    }
  }

  /// Called after a successful upload so every surface updates at once,
  /// without a round trip.
  void set(Uint8List? bytes) {
    if (!isClosed) emit(bytes);
  }

  /// Force the next [ensure] to refetch (e.g. after the photo is cleared).
  void invalidate() => _guid = null;
}
