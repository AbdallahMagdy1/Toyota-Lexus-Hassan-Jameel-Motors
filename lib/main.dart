import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injector.dart';
import 'features/notifications/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInjector();
  // FCM — same Firebase project + Web_Users.Token cycle as the old app.
  // Never blocks startup; silently disabled on unsupported setups.
  PushService.init();
  runApp(const HjApp());
}
