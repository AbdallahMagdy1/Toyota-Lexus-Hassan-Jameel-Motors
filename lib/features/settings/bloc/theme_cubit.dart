import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_brand.dart';
import '../data/branding_repository.dart';

part 'theme_state.dart';

/// Owns brand selection (Toyota / Lexus), light/dark mode, and the live
/// dashboard palettes. Emits synchronously from cache on construction so the
/// first frame is already branded, then refreshes from the API — the same
/// server-paint-then-live-refresh flow the website uses.
final class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._repo, this._store)
      : super(ThemeState(
          brandKey: _store.brand ?? 'toyota',
          themes: _repo.cached(),
          mode: switch (_store.themeMode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
        )) {
    refresh();
  }

  final BrandingRepository _repo;
  final LocalStore _store;

  /// Re-pull palettes from the dashboard-managed API.
  Future<void> refresh() async {
    final live = await _repo.fetch();
    if (live != null && !isClosed) emit(state.copyWith(themes: live));
  }

  void setBrand(String key) {
    if (key == state.brandKey) return;
    _store.setBrand(key);
    emit(state.copyWith(brandKey: key));
  }

  void setMode(ThemeMode mode) {
    _store.setThemeMode(switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    emit(state.copyWith(mode: mode));
  }
}
