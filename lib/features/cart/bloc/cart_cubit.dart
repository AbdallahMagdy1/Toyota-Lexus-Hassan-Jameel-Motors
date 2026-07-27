import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../domain/cart_item.dart';

/// The website's cart model, verbatim: the LOCAL cart is the display source
/// of truth (guest and signed-in alike); when a user is signed in every
/// add/remove/clear also syncs the account copy (WebUserCart procs), and on
/// sign-in the local items merge into the account (merge-on-login).
final class CartCubit extends Cubit<List<CartItem>> {
  CartCubit(this._store, this._api, this._authBloc)
      : super(_read(_store)) {
    _authSub = _authBloc.stream.listen((auth) {
      final userId = auth.user?.userId;
      if (userId != null && userId != _lastMergedUser) {
        _lastMergedUser = userId;
        _mergeToServer(userId);
      }
    });
  }

  final LocalStore _store;
  final ApiClient _api;
  final AuthBloc _authBloc;
  late final StreamSubscription<AuthState> _authSub;
  int? _lastMergedUser;

  static List<CartItem> _read(LocalStore store) => store.cart
      .map((s) {
        try {
          return CartItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      })
      .whereType<CartItem>()
      .toList();

  int? get _userId => _authBloc.state.user?.userId;

  bool contains(String slug) => state.any((i) => i.slug == slug);

  Future<void> add(CartItem item) async {
    if (contains(item.slug)) return;
    final next = [...state, item];
    _persist(next);
    emit(next);
    final uid = _userId;
    if (uid != null) {
      _post('/api/app/cart/add', {
        'webUserId': uid,
        'productId': item.productId,
        'colorId': item.colorId,
        'modelTypeId': item.modelTypeId,
        'year': item.year,
        'qty': 1,
      });
    }
  }

  Future<void> remove(CartItem item) async {
    final next = state.where((i) => i.slug != item.slug).toList();
    _persist(next);
    emit(next);
    final uid = _userId;
    if (uid != null) {
      _post('/api/app/cart/remove', {
        'webUserId': uid,
        'productId': item.productId,
        'colorId': item.colorId,
      });
    }
  }

  Future<void> clear() async {
    _persist(const []);
    emit(const []);
    final uid = _userId;
    if (uid != null) _post('/api/app/cart/clear', {'webUserId': uid});
  }

  /// Merge-on-login: push every local item into the account copy.
  Future<void> _mergeToServer(int userId) async {
    for (final item in state) {
      await _post('/api/app/cart/add', {
        'webUserId': userId,
        'productId': item.productId,
        'colorId': item.colorId,
        'modelTypeId': item.modelTypeId,
        'year': item.year,
        'qty': 1,
      });
    }
  }

  void _persist(List<CartItem> items) =>
      _store.setCart(items.map((i) => jsonEncode(i.toJson())).toList());

  Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>(path, body: body);
    } on DioException {
      // Server sync is best-effort — the local cart stays authoritative,
      // exactly like the website's localStorage cart.
    }
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
