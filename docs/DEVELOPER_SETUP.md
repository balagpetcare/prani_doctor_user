# Developer Setup — pranidoctor_user

Enterprise-oriented setup for **PraniDoctor** end-user (**farmer/customer**) Flutter app.

---

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| **Flutter SDK** | Match **environment.sdk** in pubspec.yaml (Dart **^3.11.5** channel as declared). Install from [Flutter install](https://docs.flutter.dev/get-started/install). |
| **lutter doctor** | Run until **Android toolchain** / **Xcode** (macOS only) reported without blocking issues for your targets. |
| **Android Studio / Xcode** | For emulators/devices and native Firebase/OAuth wiring. |
| **Git** | Repository clone only; no mandatory global git hooks for this doc. |

**Optional:** **dart** / **lutter** on PATH; VS Code **Dart** + **Flutter** extensions.

---

## Repository bootstrap

### **lutter create note**

This project is already a Flutter application. Use **lutter create .** **only** if you are scaffolding a fresh folder with the same **pubspec name/options** (e.g. regenerating platforms after intentional deletion); it can overwrite **ndroid/** / **ios/** — **avoid** blindly on existing customized native projects.

Typical onboarding:

`powershell
cd D:\PraniDoctor\pranidoctor_user
flutter pub get
`

---

## Dependencies

`powershell
flutter pub get
`

Resolves **pubspec.yaml** dependencies and triggers **code generation for l10n** when **generate: true** is set.

---

## Localization (gen-l10n)

- **l10n.yaml** points **rb-dir** to **lib/l10n** with template **pp_en.arb**.
- After editing ARBs:

`powershell
flutter gen-l10n
`

Or rely on **lutter pub get** / IDE build paths that regenerate **pp_localizations.dart** as configured.

---

## Code generation (uild_runner)

**Freezed** / **JSON** outputs (*.freezed.dart, *.g.dart) are committed for this scaffold where present; regenerate after model changes:

`powershell
dart run build_runner build --delete-conflicting-outputs
`

For watch mode during active DTO work:

`powershell
dart run build_runner watch --delete-conflicting-outputs
`

---

## Compile-time defines (dart-define)

**AppEnv** reads:

| Define | Purpose | Example |
|--------|---------|---------|
| **API_BASE_URL** | **Dio aseUrl** | https://staging.example.com |
| **LOG_NETWORK** | ool diagnostics | 	rue |
| **ENABLE_PUSH** | Gate FCM init | alse |

**Run (single define):**

`powershell
flutter run --dart-define=API_BASE_URL=https://api.mycompany.test
`

**Multiple defines:**

`powershell
flutter run --dart-define=API_BASE_URL=https://api.mycompany.test --dart-define=LOG_NETWORK=true --dart-define=ENABLE_PUSH=true
`

**Release build:**

`powershell
flutter build apk --dart-define=API_BASE_URL=https://api.production.example --dart-define=ENABLE_PUSH=true
`

Do **not** pass client secrets via **dart-define**; use OAuth/plist tooling and CI secrets instead.

---

## Firebase & FlutterFire

1. Create a Firebase project; add **Android** / **iOS** apps per package **com...** (ndroid/app).  
2. Download **google-services.json** → **ndroid/app/**. Download **GoogleService-Info.plist** → **ios/Runner/**.  
3. Install **Firebase CLI** and **FlutterFire CLI** ([FlutterFire docs](https://firebase.flutter.dev/)).  

`powershell
dart pub global activate flutterfire_cli
flutterfire configure
`

This generates **lib/firebase_options.dart** (when using the standard flow); update **Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)** in **ootstrap.dart** if you introduce options—the current bootstrap calls **Firebase.initializeApp()** without arguments until wired.

4. **Android:** Apply **Google Services** Gradle plugin per FlutterFire/Android setup (classpath + apply plugin).  
5. **iOS:** open **Runner.xcworkspace**; add plist to target; enable **Push** capability when using FCM.

Until Firebase is configured, **ootstrap** catches init errors and continues so local UI work is unblocked.

---

## OAuth (Google) — Android **SHA-1** note

For **Google Sign-In** on Android, register the app’s **SHA-1** (debug and release keystores separately) in the **Google Cloud / Firebase OAuth client** configuration. Obtain debug SHA-1:

`powershell
cd android
.\gradlew signingReport
`

Use the **Variant: debug** **SHA1** for local development. **Release** must use your **release keystore** fingerprints. Omitting SHA-1 registration causes **sign_in_failed** / **10:** style errors unrelated to Dart code quality.

Facebook login requires **Facebook Developer** dashboard configuration (bundle ID / hash keys per platform)—see **lutter_facebook_auth** README.

---

## Static analysis

`powershell
cd D:\PraniDoctor\pranidoctor_user
dart analyze
`

Or:

`powershell
flutter analyze
`

Fix all **errors** before merge; treat **warnings** per team policy (see **nalysis_options.yaml** / **lutter_lints**).

---

## Quick verification checklist

- [ ] **lutter pub get** succeeds.  
- [ ] **lutter analyze** clean (or agreed exceptions).  
- [ ] **dart run build_runner build** succeeds after Freezed/JSON edits.  
- [ ] **lutter run** with **--dart-define=API_BASE_URL=...** hits your **pranidoctor-web** deployment.  
- [ ] Firebase + OAuth credentials added per platform before enabling push/production sign-in.
