import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/store_links_repository.dart';

/// Holds the cross-brand app-store links for the side-menu "download the other
/// app" row. `null` until loaded (or when unconfigured/offline) — the drawer
/// hides the section in that case. Loads once at app start.
final class StoreLinksCubit extends Cubit<StoreLinks?> {
  StoreLinksCubit(this._repo) : super(null) {
    load();
  }

  final StoreLinksRepository _repo;

  Future<void> load() async {
    final links = await _repo.fetch();
    if (!isClosed && links != null) emit(links);
  }
}
