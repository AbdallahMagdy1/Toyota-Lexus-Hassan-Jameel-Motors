import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/local_store.dart';
import '../domain/parts_cart_models.dart';

/// The dedicated spare-parts cart — separate from the vehicles cart, exactly
/// like the website's /parts/cart. Local storage is the source of truth; the
/// backend only sees the cart at checkout (Site_SpareParts_Payment).
final class PartsCartCubit extends Cubit<List<PartsCartItem>> {
  PartsCartCubit(this._store) : super(_read(_store));

  final LocalStore _store;

  static List<PartsCartItem> _read(LocalStore store) => store.partsCart
      .map((s) {
        try {
          return PartsCartItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      })
      .whereType<PartsCartItem>()
      .toList();

  int get count => state.fold(0, (s, i) => s + i.qty);

  double get subtotal => state.fold(0, (s, i) => s + i.lineTotal);

  bool contains(String guid) => state.any((i) => i.guid == guid);

  void add(PartsCartItem item) {
    final existing = state.indexWhere((i) => i.guid == item.guid);
    final next = [...state];
    if (existing >= 0) {
      next[existing] =
          next[existing].copyWith(qty: next[existing].qty + item.qty);
    } else {
      next.add(item);
    }
    _emit(next);
  }

  void setQty(String guid, int qty) {
    if (qty < 1) return;
    _emit([
      for (final i in state) i.guid == guid ? i.copyWith(qty: qty) : i,
    ]);
  }

  void remove(String guid) =>
      _emit(state.where((i) => i.guid != guid).toList());

  void clear() => _emit(const []);

  void _emit(List<PartsCartItem> next) {
    _store.setPartsCart(next.map((i) => jsonEncode(i.toJson())).toList());
    emit(next);
  }
}
