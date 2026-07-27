import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/local_store.dart';

/// Favorited car slugs — the website's heart button, persisted locally.
final class FavoritesCubit extends Cubit<Set<String>> {
  FavoritesCubit(this._store) : super(_store.favorites.toSet());

  final LocalStore _store;

  void toggle(String slug) {
    final next = Set<String>.from(state);
    next.contains(slug) ? next.remove(slug) : next.add(slug);
    _store.setFavorites(next.toList());
    emit(next);
  }
}
