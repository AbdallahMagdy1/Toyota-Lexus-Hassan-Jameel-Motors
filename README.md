# Toyota & Lexus — Hassan Jameel Motors

Hassan Jameel Motors official mobile app — a Flutter app for **Toyota** and **Lexus** in Saudi Arabia. One codebase, two branded store apps: vehicle catalog, online store, special offers, finance requests, spare parts, maintenance booking & service tracking, with Arabic/English support.

| | Toyota | Lexus |
|---|---|---|
| App name | Toyota HJ | Lexus HJ |
| Entry point | `lib/main_toyota.dart` | `lib/main_lexus.dart` |
| Bundle ID / App ID | `com.hassanjameel.toyota` | `com.hassanjameel.lexus` |
| Icon config | `icons-toyota.yaml` | `icons-lexus.yaml` |
| Brand color | `#EB0A1E` | `#111212` |

## Setup (after cloning)

```bash
flutter pub get
cd ios && pod install && cd ..   # macOS only
```

## Building the Toyota app (repo default)

The repo is checked in with the Toyota name, icons, and bundle ID, so:

```bash
flutter build ipa -t lib/main_toyota.dart
```

## Building the Lexus app

One command flips the app name (Lexus HJ), the iOS bundle identifier, the Android label, and the launcher icons:

```bash
dart run tool/set_brand.dart lexus
flutter build ipa -t lib/main_lexus.dart
```

To return to Toyota:

```bash
dart run tool/set_brand.dart toyota
```

## Notes

- Plain `flutter run` uses `lib/main.dart`, which defaults to the Toyota brand (`--dart-define=BRAND=lexus` overrides it).
- Push notifications (FCM): Android config is `android/app/google-services.json`. For iOS, each bundle ID must be registered in the same Firebase project and its `GoogleService-Info.plist` added to `ios/Runner/`.
- The Android release keystore (`key.properties`, `*.jks`) is intentionally git-ignored — transfer it privately, never through the repo.
