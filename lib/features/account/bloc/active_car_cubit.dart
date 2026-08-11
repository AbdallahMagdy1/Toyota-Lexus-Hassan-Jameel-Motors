import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/account_models.dart';

/// The user's SELECTED garage car — tapping a card in "My garage" makes that
/// car the one offers and protection packages resolve against. Persisted by
/// VIN so the choice survives restarts.
final class ActiveCarCubit extends Cubit<String?> {
  ActiveCarCubit(this._prefs) : super(_prefs.getString(_key));

  static const _key = 'hj_active_car_vin';
  final SharedPreferences _prefs;

  void select(String? vin) {
    if (vin == null || vin.isEmpty) return;
    _prefs.setString(_key, vin);
    emit(vin);
  }
}

/// Garage scoped to the active brand theme (Lexus theme → Lexus cars only).
/// Falls back to the full garage when the brand has no cars, so the section
/// never goes empty just because of the switch.
List<GarageCar> garageForBrand(List<GarageCar> garage, String brandKey) {
  final needle = brandKey.toLowerCase() == 'lexus' ? 'lexus' : 'toyota';
  final scoped = garage
      .where((c) => '${c.brandEn ?? ''} ${c.brandAr ?? ''}'
          .toLowerCase()
          .contains(needle))
      .toList();
  return scoped.isEmpty ? garage : scoped;
}

/// The car everything personalized resolves to: the selected VIN when it is
/// in the brand-scoped garage, else the first brand car.
GarageCar? resolveActiveCar(
    List<GarageCar> garage, String brandKey, String? vin) {
  final scoped = garageForBrand(garage, brandKey);
  if (scoped.isEmpty) return null;
  for (final c in scoped) {
    if (c.vin != null && c.vin == vin) return c;
  }
  return scoped.first;
}
