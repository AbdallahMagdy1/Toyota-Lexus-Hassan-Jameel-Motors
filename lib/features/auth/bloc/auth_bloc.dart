import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Session owner. The step-by-step sign-in / Absher sign-up logic lives in
/// the flow cubits; they persist the user via AuthRepository and then raise
/// [AuthSessionRefreshed] so the router redirects.
final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo)
      : super(_repo.currentUser == null
            ? const AuthState()
            : AuthState(status: AuthStatus.authenticated, user: _repo.currentUser)) {
    on<AuthSessionRefreshed>(_onRefreshed);
    on<AuthGuestRequested>(_onGuest);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repo;

  void _onRefreshed(AuthSessionRefreshed e, Emitter<AuthState> emit) {
    final user = _repo.currentUser;
    emit(user == null
        ? const AuthState()
        : AuthState(status: AuthStatus.authenticated, user: user));
  }

  void _onGuest(AuthGuestRequested e, Emitter<AuthState> emit) =>
      emit(const AuthState(status: AuthStatus.guest));

  Future<void> _onSignOut(AuthSignOutRequested e, Emitter<AuthState> emit) async {
    await _repo.signOut();
    emit(const AuthState());
  }
}
