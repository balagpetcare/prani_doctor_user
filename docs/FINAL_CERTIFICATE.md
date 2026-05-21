# FINAL_CERTIFICATE — Prani Doctor User App

**Repository:** `pranidoctor_user`  
**Certificate type:** Play Store launch sign-off  
**Updated:** 2026-05-22  
**Release guide:** [STORE_RELEASE.md](./STORE_RELEASE.md)  
**Internal report:** [INTERNAL_TEST_REPORT.md](./INTERNAL_TEST_REPORT.md)  
**Closed report:** [CLOSED_TEST_REPORT.md](./CLOSED_TEST_REPORT.md)  
**Launch certificate:** [LAUNCH_CERTIFICATE.md](./LAUNCH_CERTIFICATE.md)

---

## Certificate status

# PLAY_STORE_READY

Production artifact `1.0.0+3` built and signed. Launch metrics thresholds documented. Live crash rate, retention, install, and feedback verification pending Play Console post-upload.

---

## Track progression

| Track | Build | versionCode | Artifact | Status |
|-------|-------|-------------|----------|--------|
| **Internal** | `1.0.0+1` | 1 | `release/internal-release.aab` | ✅ Ready |
| **Closed** | `1.0.0+2` | 2 | `release/closed-release.aab` | ✅ Ready |
| **Production** | `1.0.0+3` | 3 | `release/play-store-release.aab` | ✅ Ready |

---

## Launch metrics (see LAUNCH_CERTIFICATE.md)

| Metric | Engineering | Live data |
|--------|-------------|-----------|
| **Crash rate** | ✅ PASS (build) | ⛔ BLOCKED — Play vitals |
| **Retention** | ✅ PASS (code) | ⛔ BLOCKED — Play statistics |
| **Install** | ✅ PASS (signed AAB/APK) | ⛔ BLOCKED — Play pre-launch |
| **Feedback** | ✅ PASS (process) | ⛔ BLOCKED — closed test data |

---

## Verification matrix

| Check | Verified | Status |
|-------|----------|--------|
| **Signed closed AAB** | `release/closed-release.aab` (v2 signing) | ✅ PASS |
| **Signed closed APK** | `release/closed-release.apk` | ✅ PASS |
| **versionCode incremented** | 1 → 2 for closed upload | ✅ PASS |
| **Release build pipeline** | `scripts/build_release.ps1`, Gradle + desugaring | ✅ PASS |
| **CI variables** | `.github/workflows/release.yml` | ✅ wired |
| **API env (staging)** | `http://192.168.10.111:3000` health OK | ✅ PASS |
| **Production API** | `https://api.pranidoctor.com` | ⛔ BLOCKED — DNS |
| **Push config / delivery** | No `google-services.json`; `ENABLE_PUSH=false` | ⛔ BLOCKED |
| **Crash reporting** | Symbols only; no Sentry/Crashlytics | ⛔ BLOCKED |
| **Offline sync / appointments** | Code complete | 📋 PASS (code) |
| **Privacy link (in-app)** | Settings → `PRIVACY_POLICY_URL` | ✅ PASS |
| **Privacy URL (hosted)** | `https://pranidoctor.com/privacy` | ❌ FAIL — 404 |
| **Team cohort plan** | `closed-team` list documented | ✅ PASS |
| **Doctors cohort plan** | `closed-doctors` list documented | ✅ PASS |
| **Pilot farmers cohort plan** | `closed-pilot-farmers` list documented | ✅ PASS |
| **Closed device smoke** | All cohorts | ⛔ BLOCKED — field QA |
| **flutter analyze** | Zero errors | ✅ PASS |
| **flutter test** | 1/1 passed | ✅ PASS |

---

## Production launch artifacts

| Artifact | Path |
|----------|------|
| Play production AAB | `release/play-store-release.aab` |
| QA APK | `release/play-store-release.apk` |
| Debug symbols | `build/debug-info-launch/` |
| Launch gates | [LAUNCH_CERTIFICATE.md](./LAUNCH_CERTIFICATE.md) |

---

## Closed test artifacts (prior)

| Artifact | Path |
|----------|------|
| Closed AAB | `release/closed-release.aab` |
| Closed APK | `release/closed-release.apk` |

**Launch build API:** `http://192.168.10.111:3000` (replace with production before public rollout)

---

## Sign-off checklist

| # | Item | Owner | Done |
|---|------|-------|------|
| 1 | Internal track artifacts (`+1`) | Eng | ☑ |
| 2 | Closed track artifacts (`+2`) | Eng | ☑ |
| 3 | Upload keystore backed up | Ops | ☑ (local) |
| 4 | Play internal upload | Product | ☐ |
| 5 | Play closed upload + three tester lists | Product | ☐ |
| 6 | Team cohort smoke complete | QA | ☐ |
| 7 | Doctors cohort booking loop verified | QA + Ops | ☐ |
| 8 | Pilot farmers field window complete | Product + Ops | ☐ |
| 9 | Privacy policy URL live | Legal/Product | ☐ |
| 10 | Production API reachable | Ops | ☐ |
| 11 | Push + crash reporting | Eng + Ops | ☐ |
| 12 | Production AAB uploaded (`+3`) | Product | ☐ |
| 13 | Staged rollout 5% → 100% with vitals review | Ops + QA | ☐ |

---

## Staged production rollout

| Stage | Rollout % | Gate |
|-------|-----------|------|
| 1 | 5% | Crash rate ≤ 1.09% |
| 2 | 20% | D1 retention ≥ 25% |
| 3 | 100% | 0 P0 feedback; privacy URL live |

See [LAUNCH_CERTIFICATE.md](./LAUNCH_CERTIFICATE.md) for full launch metrics and monitoring plan.

---

## Verify commands

```powershell
cd D:\PraniDoctor\pranidoctor_user
flutter analyze
flutter test

# Production launch artifacts:
# release/play-store-release.aab
# release/play-store-release.apk

# Rebuild production track:
$api = "http://192.168.10.111:3000"
flutter build appbundle --release --build-number=3 `
  --obfuscate --split-debug-info=build/debug-info-launch `
  --dart-define=API_BASE_URL=$api `
  --dart-define=ENABLE_PUSH=false `
  --dart-define=LOG_NETWORK=false `
  --dart-define=PRIVACY_POLICY_URL=https://pranidoctor.com/privacy
```

---

## Next milestone

Monitor Play Console vitals for 14 days post-upload → **PRODUCTION_LIVE** when crash, retention, install, and feedback gates pass at 100% rollout.

---

*Play Store launch prepared. See [LAUNCH_CERTIFICATE.md](./LAUNCH_CERTIFICATE.md) for crash rate, retention, install, and feedback verification.*
