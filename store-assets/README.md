# Play Store assets — Prani Doctor User App

Assets listed here are uploaded in **Google Play Console**, not bundled in the AAB (except launcher icon).

## In-repo (Android app)

| Asset | Location | Status |
|-------|----------|--------|
| App display name | `android/app/src/main/res/values/strings.xml` → **Prani Doctor** | Committed |
| Launcher icon | `android/app/src/main/res/drawable/ic_launcher*.xml` | Committed (vector) |
| Feature graphic | — | Upload to Play Console |
| Screenshots | — | Upload to Play Console |

## Play Console required uploads

| Asset | Specification |
|-------|----------------|
| Hi-res icon | 512×512 PNG (can export from vector source) |
| Feature graphic | 1024×500 PNG or JPG |
| Phone screenshots | Minimum 2; 16:9 or 9:16 |
| Short description | ≤ 80 characters |
| Full description | ≤ 4000 characters |
| Privacy policy URL | Must match `PRIVACY_POLICY_URL` dart-define / hosted policy |

## Optional branding upgrades

- Replace vector launcher with branded PNG mipmaps (`flutter_launcher_icons`)
- Branded splash via `flutter_native_splash`
- Tablet screenshots for large-screen listing

## Related docs

- [STORE_RELEASE.md](../docs/STORE_RELEASE.md)
- [docs/legal/PRIVACY_POLICY.md](../docs/legal/PRIVACY_POLICY.md)
