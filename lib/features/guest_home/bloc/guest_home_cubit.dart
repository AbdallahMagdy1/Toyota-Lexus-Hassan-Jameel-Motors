import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../domain/guest_home_models.dart';

enum GuestHomeStatus { loading, ready, error }

final class GuestHomeState extends Equatable {
  const GuestHomeState({
    this.status = GuestHomeStatus.loading,
    this.data = const GuestHome(),
  });

  final GuestHomeStatus status;
  final GuestHome data;

  @override
  List<Object?> get props => [status, data];
}

/// Loads the guest home aggregate (hero + categories + offers) for the
/// active brand in one round-trip.
final class GuestHomeCubit extends Cubit<GuestHomeState> {
  GuestHomeCubit(this._api, {required String brandKey})
      : _brandKey = brandKey,
        super(const GuestHomeState()) {
    load();
  }

  final ApiClient _api;
  final String _brandKey;

  Future<void> load() async {
    emit(const GuestHomeState(status: GuestHomeStatus.loading));
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/api/app/guest-home',
        query: {'brand': _brandKey},
      );
      if (isClosed) return;
      if (res.statusCode == 200 && res.data != null) {
        emit(GuestHomeState(
          status: GuestHomeStatus.ready,
          data: GuestHome.fromJson(res.data!),
        ));
      } else {
        emit(const GuestHomeState(status: GuestHomeStatus.error));
      }
    } on DioException {
      if (!isClosed) emit(const GuestHomeState(status: GuestHomeStatus.error));
    }
  }
}
