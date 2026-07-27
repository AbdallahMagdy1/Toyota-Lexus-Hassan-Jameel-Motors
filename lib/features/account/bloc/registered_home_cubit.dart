import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/app_user.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';

enum RegisteredHomeStatus { loading, ready, error }

final class RegisteredHomeState extends Equatable {
  const RegisteredHomeState({
    this.status = RegisteredHomeStatus.loading,
    this.home = const HomeState(),
    this.allServicesOpen = false,
  });

  final RegisteredHomeStatus status;
  final HomeState home;
  final bool allServicesOpen;

  RegisteredHomeState copyWith({
    RegisteredHomeStatus? status,
    HomeState? home,
    bool? allServicesOpen,
  }) =>
      RegisteredHomeState(
        status: status ?? this.status,
        home: home ?? this.home,
        allServicesOpen: allServicesOpen ?? this.allServicesOpen,
      );

  @override
  List<Object?> get props => [status, home, allServicesOpen];
}

/// Loads the registered home in one round-trip — the backend resolves the
/// dynamic card + journeys priority; this cubit only holds the result.
final class RegisteredHomeCubit extends Cubit<RegisteredHomeState> {
  RegisteredHomeCubit(this._repo, {required AppUser? user})
      : _user = user,
        super(const RegisteredHomeState()) {
    load();
  }

  final AccountRepository _repo;
  final AppUser? _user;

  Future<void> load({bool fresh = false}) async {
    final user = _user;
    if (user == null) {
      emit(state.copyWith(status: RegisteredHomeStatus.error));
      return;
    }
    // Paint the last-known home instantly (memory, then disk on a cold
    // app start); the network refresh continues behind it.
    final cached = _repo.cachedHome(user.userId) ??
        await _repo.cachedHomeDisk(user.userId);
    if (isClosed) return;
    if (cached != null && state.status != RegisteredHomeStatus.ready) {
      emit(state.copyWith(status: RegisteredHomeStatus.ready, home: cached));
    } else if (cached == null) {
      emit(state.copyWith(status: RegisteredHomeStatus.loading));
    }
    final home = await _repo.homeState(
      userId: user.userId,
      custId: user.custId,
      phone: user.phone,
      fresh: fresh,
    );
    if (isClosed) return;
    if (home == null) {
      if (cached == null) {
        emit(state.copyWith(status: RegisteredHomeStatus.error));
      }
    } else {
      emit(state.copyWith(status: RegisteredHomeStatus.ready, home: home));
    }
  }

  Future<void> refresh() => load(fresh: true);

  void toggleAllServices() =>
      emit(state.copyWith(allServicesOpen: !state.allServicesOpen));
}
