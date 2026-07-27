# HJ Mobile App (MobileAppFlutter-next)

Flutter app for Hassan Jameel (Toyota & Lexus KSA) — the mobile mirror of the
website cycle: dashboard-managed brand themes + onboarding content, website's
Site_User_* auth, Arabic-first bilingual UI.

## Architecture

- **Clean architecture per feature** — `features/<x>/{domain,data,bloc,presentation}`.
- **BLoC everywhere** (`flutter_bloc`): `ThemeCubit` (brand + light/dark + live
  dashboard palettes), `LocaleCubit` (ar default), `AuthBloc`,
  `OnboardingCubit`, form cubits that own `TextEditingController`s —
  **zero StatefulWidgets** in the app.
- **One Scaffold for the whole app** (`_AppShell` in
  `lib/app/router/app_router.dart`); go_router swaps plain widgets inside it
  with an Apple-style fade/drift/scale transition.
- **DI**: get_it (`lib/core/di/injector.dart`). **Network**: dio. **Storage**:
  shared_preferences with the website's key names (`hj_lang`, `hj_theme`, ...).

## The brand-theme cycle (same as the website)

1. `kFallbackBrands` in `lib/core/theme/app_brand.dart` = byte-identical
   palettes to the website's `src/lib/brands.ts` (first paint, offline).
2. `ThemeCubit` emits the cached palette synchronously, then fetches
   `GET /api/app/themes` (dashboard **Site Themes** tab → `SiteThemes` table)
   and re-emits — dashboard recolors go live in seconds, light + dark.
3. `ThemeFactory` maps the palette into `ThemeData` (the globals.css
   equivalent). Brand switch (Toyota ⇄ Lexus) is the in-app substitute for the
   website's per-domain resolution.

## Onboarding cycle

`GET /api/app/onboarding?brand=` → `dbo.App_Onboarding_Slides`
(dashboard-managed like Home Hero). Bundled bilingual slides render until the
table has rows / when offline.

## Auth cycle (identical to the website)

MD5(password) client-side → `POST /api/user/sign-in|register` →
`Site_User_*` procs → `UserDto` persisted in shared_preferences (no token —
same model as the website). Error codes (`phone_exists`, ...) map to localized
messages.

## Run

```bash
# backend first (MobileAppBackEnd-next):
#   dotnet run --launch-profile http     → 0.0.0.0:5080
flutter run                              # Android emulator (10.0.2.2:5080)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5080   # real device
```
