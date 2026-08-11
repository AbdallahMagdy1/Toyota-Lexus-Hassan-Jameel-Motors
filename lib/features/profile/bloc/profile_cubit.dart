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
  });

  final ProfileStatus status;

  /// Full record from GET /api/user/{guid} — null for guests or while the
  /// network fetch is pending/failed (the UI falls back to the session user).
  final ProfileUser? user;
  final ProfileSettings? settings;
  final List<AccountType>? accountTypes;
  final bool lookupsBusy;
  final bool lookupsFailed;

  bool get lookupsReady => settings != null && accountTypes != null;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileUser? user,
    ProfileSettings? settings,
    List<AccountType>? accountTypes,
    bool? lookupsBusy,
    bool? lookupsFailed,
  }) =>
      ProfileState(
        status: status ?? this.status,
        user: user ?? this.user,
        settings: settings ?? this.settings,
        accountTypes: accountTypes ?? this.accountTypes,
        lookupsBusy: lookupsBusy ?? this.lookupsBusy,
        lookupsFailed: lookupsFailed ?? this.lookupsFailed,
      );

  @override
  List<Object?> get props =>
      [status, user, settings, accountTypes, lookupsBusy, lookupsFailed];
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
    final user = await _repo.fetchUser(guid);
    if (isClosed) return;
    emit(state.copyWith(status: ProfileStatus.ready, user: user));
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
