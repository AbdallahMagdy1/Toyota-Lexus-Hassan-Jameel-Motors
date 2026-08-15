import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/local_store.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Session owner. The step-by-step sign-in / Absher sign-up logic lives in
/// the flow cubits; they persist the user via AuthRepository and then raise
/// [AuthSessionRefreshed] so the router redirects.
final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo, this._store)
      : super(_repo.currentUser != null
            ? AuthState(
                status: AuthStatus.authenticated, user: _repo.currentUser)
            // Guest entry persists — a returning guest goes straight into
            // the app instead of seeing the welcome screen again.
            : _store.guestMode
                ? const AuthState(status: AuthStatus.guest)
                : const AuthState()) {
    on<AuthSessionRefreshed>(_onRefreshed);
    on<AuthGuestRequested>(_onGuest);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repo;
  final LocalStore _store;

  void _onRefreshed(AuthSessionRefreshed e, Emitter<AuthState> emit) {
    final user = _repo.currentUser;
    emit(user == null
        ? const AuthState()
        : AuthState(status: AuthStatus.authenticated, user: user));
  }

  void _onGuest(AuthGuestRequested e, Emitter<AuthState> emit) {
    _store.setGuestMode(true);
    emit(const AuthState(status: AuthStatus.guest));
  }

  Future<void> _onSignOut(AuthSignOutRequested e, Emitter<AuthState> emit) async {
    await _repo.signOut();
    // Explicit sign-out returns to the entry flow (welcome shows again).
    await _store.setGuestMode(false);
    emit(const AuthState());
  }
}
