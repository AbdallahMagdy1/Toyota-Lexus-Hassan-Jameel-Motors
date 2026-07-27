part of 'auth_bloc.dart';

enum AuthStatus { unauthenticated, authenticated, guest }

final class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unauthenticated, this.user});

  final AuthStatus status;
  final AppUser? user;

  bool get isSignedIn =>
      status == AuthStatus.authenticated || status == AuthStatus.guest;

  @override
  List<Object?> get props => [status, user];
}
