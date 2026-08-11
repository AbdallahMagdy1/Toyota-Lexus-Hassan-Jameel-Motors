import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injector.dart';
import 'features/notifications/notifications.dart';

/// ── THE APP'S BRAND ──
/// 'toyota' or 'lexus'. The whole app (theme colors, logos, catalog
/// filtering, offers, store…) is fixed to this brand — there is no in-app
/// brand switching. Each store build uses its own entry point:
///   Toyota: flutter build ipa -t lib/main_toyota.dart
///   Lexus:  flutter build ipa -t lib/main_lexus.dart
/// Running plain `flutter run` (this file) defaults to Toyota.
const String brandTheme =
    String.fromEnvironment('BRAND', defaultValue: 'toyota');

Future<void> main() => runBrandedApp(brandTheme);

/// Shared bootstrap used by every brand entry point.
Future<void> runBrandedApp(String brand) async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInjector(brand: brand);
  // FCM — same Firebase project + Web_Users.Token cycle as the old app.
  // Never blocks startup; silently disabled on unsupported setups.
  PushService.init();
  runApp(const HjApp());
}
