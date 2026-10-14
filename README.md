# Toyota & Lexus — Hassan Jameel Motors

Hassan Jameel Motors official mobile app — a Flutter app for **Toyota** and **Lexus** in Saudi Arabia. One codebase, two branded store apps: vehicle catalog, online store, special offers, finance requests, spare parts, maintenance booking & service tracking, job-card payment, and push notifications — fully bilingual (Arabic RTL / English).

| | Toyota | Lexus |
|---|---|---|
| App name | Toyota HJ | Lexus HJ |
| Entry point | `lib/main_toyota.dart` | `lib/main_lexus.dart` |
| Android applicationId | `com.hassanjameel.toyota` | `com.hassanjameel.lexus` |
| iOS bundle ID | `com.hassanjameel.toyotamotors` | `com.hassanjameel.lexus` |
| Icon config | `icons-toyota.yaml` | `icons-lexus.yaml` |
| Brand color | `#EB0A1E` | `#111212` |

> ⚠️ Note the asymmetry: the **iOS** Toyota app was registered on the App Store as
> `com.hassanjameel.toyotamotors`, while Google Play uses `com.hassanjameel.toyota`.
> `tool/set_brand.dart` handles this automatically.

---

## Project structure

```
lib/
├── main.dart                 # Shared bootstrap: runBrandedApp(brand) — Firebase,
│                             #   DI, PushService; plain `flutter run` = Toyota
├── main_toyota.dart          # Store entry point → runBrandedApp('toyota')
├── main_lexus.dart           # Store entry point → runBrandedApp('lexus')
│
├── app/                      # App shell & navigation
│   ├── app.dart              #   MaterialApp.router + theme/locale wiring
│   ├── app_router.dart       #   go_router: ShellRoute (one Scaffold), slide
│   │                         #   page transitions, auth redirects, NavHistory
│   └── routes.dart           #   Route path constants
│
├── core/                     # Cross-cutting infrastructure (no UI)
│   ├── constants/            #   api_paths.dart — EVERY backend endpoint lives here
│   ├── di/                   #   injector.dart — get_it singletons; `appBrand`
│   │                         #   global ('toyota'|'lexus') set once at bootstrap
│   ├── network/              #   ApiClient (Dio) — sends the X-Brand header on
│   │                         #   every request + SWR disk cache for catalog GETs
│   ├── storage/              #   LocalStore (SharedPreferences wrapper)
│   ├── theme/                #   theme_factory.dart — builds light/dark ThemeData
│   │                         #   from the dashboard-managed SiteThemes palette;
│   │                         #   FLAT design: no shadows anywhere
│   └── utils/                #   responsive.dart (rs/rf scaling), phone_mask, …
│
├── features/                 # One folder per feature (see pattern below)
│   ├── auth/                 #   Sign-in (password + OTP), sign-up (Absher KYC),
│   │                         #   forgot-password — mirrors the website AuthPopup
│   ├── home/                 #   Catalog home feed (aggregate /api/app/home)
│   ├── guest_home/           #   Browse-first home for guests
│   ├── account/              #   Registered home "Your Car, Your Journey":
│   │                         #   garage (brand-filtered), dynamic card, journeys,
│   │                         #   bookings (reschedule/cancel), service tracking
│   ├── vehicles/             #   "Meet the models" catalog + model sheet
│   │                         #   (Overview/Gallery/Specs/Features/Comparison)
│   ├── online_store/         #   Buy-online cycle: reservation, finance request,
│   │                         #   payment (MyFatoorah/Sadad), contract signing
│   ├── offers/               #   Offers by type with live countdowns
│   ├── parts/                #   Spare-parts catalog + cart + checkout
│   ├── protection/           #   Protection & shading packages + booking + pay
│   ├── maintenance_hub/      #   Maintenance services & booking sheet
│   ├── jobcard/              #   Job-card details + payment sheet (website
│   │                         #   /JobCard parity; gateways: full/Tabby/Tamara/
│   │                         #   Sadad/Apple Pay)
│   ├── used_cars/            #   Certified used cars + sell-your-car wizard
│   ├── finance/              #   Finance calculator + lead sheet
│   ├── notifications/        #   PushService (FCM) + local inbox + server feed
│   ├── cart/ favorites/      #   Vehicle cart & favorites
│   ├── coupons/              #   Coupon banners & validation
│   ├── complaints/           #   Submit & track complaints
│   ├── content/              #   News, contact-us, branches
│   ├── onboarding/ welcome/  #   Dashboard-managed onboarding slides, welcome
│   ├── profile/              #   Profile hub sheets (data, password, photo, …)
│   ├── settings/             #   ThemeCubit / LocaleCubit / StoreLinksCubit
│   └── store/                #   المتجر tab — storefront hub (bottom-nav)
│
├── shared/                   # Reusable UI, feature-agnostic
│   ├── navigation/           #   bottom nav pill, side menu, sheet routes
│   │                         #   (showHeroBottomSheet / showAppModalSheet with
│   │                         #   Instagram-style drag-to-dismiss), back FAB
│   └── widgets/              #   AppHeader, FilterChipsRow, TabSwipe,
│                             #   TabSlideSwitcher, PriceText, skeletons, …
│
└── l10n/                     # ARB files + generated AppLocalizations (ar/en)

tool/set_brand.dart           # THE brand switcher (see below)
android/ ios/                 # ONE platform folder each — set_brand rewrites ids
dist/                         # Signed store artifacts (AABs)
```

### Feature-module pattern

Every folder under `features/` follows the same layering:

```
features/<name>/
├── data/          # Repository: raw HTTP via ApiClient → typed models
├── domain/        # Immutable models (Equatable), pure Dart
├── bloc/          # Cubit/Bloc holding the screen state
└── presentation/  # Screens, sheets, widgets (read state, dispatch to cubit)
```

State management is **flutter_bloc** (mostly Cubits) with **get_it** (`sl`) for
app-lifetime singletons (ApiClient, AuthBloc, ThemeCubit, carts, …) — registered
in `core/di/injector.dart`. Screen-scoped cubits are created in `BlocProvider`s.

---

## The dual-brand system

The brand is **fixed at build time** — there is no in-app switching.

1. **Dart side** — each store build uses its own entry point
   (`main_toyota.dart` / `main_lexus.dart` → `runBrandedApp(brand)`), which sets
   the global `appBrand`. That drives theming, catalog filtering (the Lexus app
   never shows Toyota cars — garage, online store, offers), the `X-Brand` header
   sent on every API call, FCM topic subscription, and OTP SMS sender selection.

2. **Platform side** — `dart run tool/set_brand.dart <toyota|lexus>` rewrites in
   one shot:
   - iOS `Info.plist` display name + `project.pbxproj` bundle identifier
   - Android manifest label + Gradle `applicationId`
   - copies the brand's `ios/firebase/GoogleService-Info-<brand>.plist` into
     `ios/Runner/`
   - regenerates launcher icons from `icons-<brand>.yaml`

The repo is checked in in the **Toyota** state.

---

## Backend

The app talks to **HJ.Mobile.Api** (`fluttermobile.hassanjameelapp.com`) — a .NET
API sharing the same HJ_Live database and stored procedures as the website.
Every endpoint path is a constant in `core/constants/api_paths.dart`; no URL is
built inline. Repositories degrade gracefully (empty lists / nulls) on network
errors, and the home feeds keep a disk copy for instant cold-start paint.

## Push notifications

- FCM, one Firebase project (`hassan-jameel`) with per-brand apps.
- On start the app subscribes to topics `all` + its brand (`toyota`/`lexus`) and
  unsubscribes from the other brand; device tokens register with
  `{userId, token, brand, platform}` so the server routes brand-specific pushes.
- Android: `high_importance_channel` (created in `PushService.init`).
- iOS: `Runner.entitlements` (`aps-environment`) + `remote-notification`
  background mode are committed in the shared Runner target — both apps get them.
- Foreground messages show a local notification; background arrivals are stored
  into the in-app inbox when opened.

---

## Setup (after cloning)

```bash
flutter pub get
cd ios && pod install && cd ..   # macOS only
```

## Building

```bash
# Toyota (repo default)
dart run tool/set_brand.dart toyota
flutter build appbundle -t lib/main_toyota.dart   # Android (Play)
flutter build ipa -t lib/main_toyota.dart          # iOS

# Lexus
dart run tool/set_brand.dart lexus
flutter build appbundle -t lib/main_lexus.dart
flutter build ipa -t lib/main_lexus.dart
```

- Plain `flutter run` uses `lib/main.dart` (defaults to Toyota;
  `--dart-define=BRAND=lexus` overrides). Run `set_brand` first so the installed
  app's name/icon/id match the brand you're testing.
- Both Android apps are signed with ONE upload keystore (Play App Signing holds
  the per-app signing keys). `key.properties` / `*.jks` are intentionally
  git-ignored — transfer them privately, never through the repo.
