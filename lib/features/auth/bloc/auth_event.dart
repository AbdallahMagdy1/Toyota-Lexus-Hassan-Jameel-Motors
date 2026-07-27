part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// A flow cubit persisted a user via AuthRepository — re-read the session.
final class AuthSessionRefreshed extends AuthEvent {
  const AuthSessionRefreshed();
}

final class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
