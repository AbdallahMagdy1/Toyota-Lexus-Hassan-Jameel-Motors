import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/local_store.dart';

/// App language. Arabic is the default, matching the website (hj_lang).
final class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._store) : super(Locale(_store.lang ?? 'ar'));

  final LocalStore _store;

  void toggle() => set(state.languageCode == 'ar' ? 'en' : 'ar');

  void set(String code) {
    if (code == state.languageCode) return;
    _store.setLang(code);
    emit(Locale(code));
  }
}
