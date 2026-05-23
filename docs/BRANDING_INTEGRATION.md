# Branding Integration

## Asset tree

```
assets/
  brand/
    app_icons/prani_doctor_app_icon.png
    logos/prani_doctor_primary_logo.png
    illustrations/splash_farm_livestock.png
  images/
    onboarding/
      onboarding_01_service_overview_bd.png
      onboarding_02_farmer_vet_consultation_bd.png
      onboarding_03_ai_field_support_bd.png
      onboarding_04_get_started_bd.png
    home/
      hero_farm_vet.png
      emergency_vet.png
      promo_vaccination.png
      empty_nearby_doctors.png
```

Replace placeholder PNGs with final design exports (same filenames).

## Generated configs (`pubspec.yaml`)

**flutter_native_splash**
- Background: `#FFFFFF`
- Image: `assets/brand/logos/prani_doctor_primary_logo.png`
- Android: fullscreen, center gravity
- iOS: `scaleAspectFit` (when iOS project is added)

**flutter_launcher_icons**
- Source: `assets/brand/app_icons/prani_doctor_app_icon.png`
- Android adaptive icon, white background
- iOS disabled (no `ios/` folder in repo)

Regenerate after asset swap:
```powershell
dart run flutter_native_splash:create
dart run flutter_launcher_icons
```

## Flow

1. Native splash (logo on white)
2. `SplashPage` — logo fade → farm illustration → **প্রাণী ডাক্তার** + boot status
3. Boot controller (config, session, refresh, profile)
4. Navigate: authed → home; unauthed → onboarding → login

## Screenshots paths (after run on device)

Capture from emulator/device:
- Native splash: cold start frame
- `SplashPage`: mid-animation
- Onboarding slides 1–4
- Home hero / emergency / promo cards
- Services empty doctors state
