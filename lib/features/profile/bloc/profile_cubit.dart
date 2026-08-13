import 'dart:convert' show base64Decode;
import 'dart:typed_data' show Uint8List;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

enum ProfileStatus { loading, ready }

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.user,
    this.settings,
    this.accountTypes,
    this.lookupsBusy = false,
    this.lookupsFailed = false,
    this.avatar,
    this.avatarBusy = false,
  });

  final ProfileStatus status;

  /// Full record from GET /api/user/{guid} — null for guests or while the
  /// network fetch is pending/failed (the UI falls back to the session user).
  final ProfileUser? user;
  final ProfileSettings? settings;
  final List<AccountType>? accountTypes;
  final bool lookupsBusy;
  final bool lookupsFailed;

  /// Decoded profile photo (Web_Users.Logo, base64 → bytes decoded ONCE
  /// here so the UI never re-decodes per frame). Null = no photo.
  final Uint8List? avatar;

  /// True while a new photo is uploading.
  final bool avatarBusy;

  bool get lookupsReady => settings != null && accountTypes != null;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileUser? user,
    ProfileSettings? settings,
    List<AccountType>? accountTypes,
    bool? lookupsBusy,
    bool? lookupsFailed,
    Uint8List? avatar,
    bool? avatarBusy,
  }) =>
      ProfileState(
        status: status ?? this.status,
        user: user ?? this.user,
        settings: settings ?? this.settings,
        accountTypes: accountTypes ?? this.accountTypes,
        lookupsBusy: lookupsBusy ?? this.lookupsBusy,
        lookupsFailed: lookupsFailed ?? this.lookupsFailed,
        avatar: avatar ?? this.avatar,
        avatarBusy: avatarBusy ?? this.avatarBusy,
      );

  @override
  List<Object?> get props => [
        status,
        user,
        settings,
        accountTypes,
        lookupsBusy,
        lookupsFailed,
        avatar,
        avatarBusy,
      ];
}

/// Owns the profile-hub data: the full user record plus the "my data"
/// lookups. Saves live in the sheets; after every successful save they call
/// [refreshUser] which re-fetches, re-persists the session, and pokes
/// AuthBloc so the rest of the app re-reads it.
final class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repo, this._auth) : super(const ProfileState());

  final ProfileRepository _repo;
  final AuthBloc _auth;

  /// The sheets run their own save calls against the same repository.
  ProfileRepository get repo => _repo;

  String? get _guid {
    final g = _auth.state.user?.guid;
    return (g == null || g.isEmpty) ? null : g;
  }

  Future<void> load() async {
    final guid = _guid;
    if (guid == null) {
      emit(state.copyWith(status: ProfileStatus.ready));
      return;
    }
    loadImage(); // avatar fetch runs in parallel with the record fetch
    final user = await _repo.fetchUser(guid);
    if (isClosed) return;
    emit(state.copyWith(status: ProfileStatus.ready, user: user));
  }

  /// The website GetUserImage cycle: Web_Users.Logo base64 → bytes.
  Future<void> loadImage() async {
    final guid = _guid;
    if (guid == null) return;
    final b64 = await _repo.fetchImage(guid);
    if (isClosed || b64 == null) return;
    try {
      emit(state.copyWith(avatar: base64Decode(b64)));
    } on FormatException {
      // Corrupt/legacy value — keep the initial-letter avatar.
    }
  }

  /// Upload a newly picked photo (already base64, no data-url prefix) —
  /// the website's UpdateWeb_users(Logo). Optimistically shows the new
  /// photo once the server confirms.
  Future<bool> changeImage(String base64) async {
    final guid = _guid;
    if (guid == null || state.avatarBusy) return false;
    emit(state.copyWith(avatarBusy: true));
    final result = await _repo.updateImage(guid: guid, logoBase64: base64);
    if (isClosed) return result.ok;
    emit(state.copyWith(
      avatarBusy: false,
      avatar: result.ok ? base64Decode(base64) : null,
    ));
    return result.ok;
  }

  /// Countries/cities/genders + account types for the "my data" form.
  Future<void> ensureLookups() async {
    if (state.lookupsReady || state.lookupsBusy) return;
    emit(state.copyWith(lookupsBusy: true, lookupsFailed: false));
    final results =
        await Future.wait([_repo.settings(), _repo.accountTypes()]);
    if (isClosed) return;
    final settings = results[0] as ProfileSettings?;
    final types = results[1] as List<AccountType>?;
    emit(state.copyWith(
      settings: settings,
      accountTypes: types,
      lookupsBusy: false,
      lookupsFailed: settings == null || types == null,
    ));
  }

  /// Re-fetch after a successful save; the repository re-persists the
  /// session JSON, then [AuthSessionRefreshed] makes AuthBloc re-read it.
  Future<void> refreshUser() async {
    final guid = _guid;
    if (guid == null) return;
    final user = await _repo.fetchUser(guid);
    if (user != null) _auth.add(const AuthSessionRefreshed());
    if (isClosed) return;
    if (user != null) emit(state.copyWith(user: user));
  }
}
