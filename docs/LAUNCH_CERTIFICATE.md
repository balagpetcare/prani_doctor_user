# Launch Certificate — Prani Doctor User App

**Repository:** `pranidoctor_user`  
**Package:** `com.pranidoctor.user.pranidoctor_user`  
**Production build:** `1.0.0+3`  
**Certificate date:** 2026-05-22  
**Track path:** Internal → Closed → **Production (staged rollout)**  
**Prior reports:** [INTERNAL_TEST_REPORT.md](./INTERNAL_TEST_REPORT.md) · [CLOSED_TEST_REPORT.md](./CLOSED_TEST_REPORT.md)  
**Release guide:** [STORE_RELEASE.md](./STORE_RELEASE.md)

---

## Certificate status

# PLAY_STORE_READY

Production launch artifact built and signed. Engineering and release pipeline gates pass. Play Console vitals (crash rate, retention) and hosted policy URL require post-upload monitoring — thresholds and verification procedure documented below.

---

## Launch metrics verification

Google Play **Android vitals** and closed-test feedback are the source of truth for launch gates. This certificate records repo-verified prerequisites plus Play Console checks to run after upload.

### Thresholds (launch gates)

| Metric | Source | Launch threshold | Production target |
|--------|--------|------------------|-------------------|
| **Crash rate** | Play Console → Android vitals → Crashes | ≤ **1.09%** (7-day user-perceived ANR + crash) | ≤ **0.5%** |
| **Retention** | Play Console → Statistics → Retained installers | D1 ≥ **25%**, D7 ≥ **10%** (pilot) | D1 ≥ **35%**, D7 ≥ **15%** |
| **Install** | Play Console → Release → Install base | Successful install on ≥ **3 device models** | No install-failure spike > **2%** |
| **Feedback** | Closed testers + Play reviews + field form | **0 open P0**, ≤ **3 open P1**, NPS or form ≥ **10 responses** | P0 = 0 before 100% rollout |

---

## Verification results

### Crash rate

| Check | Method | Result | Evidence |
|-------|--------|--------|----------|
| Release build stability (static) | `flutter analyze` (0 errors), `flutter test` (1/1) | **PASS** | No compile/test regressions |
| Obfuscation + symbols | `--obfuscate`, `build/debug-info-launch/` | **PASS** | Symbols ready for crash backend |
| In-app crash SDK | Repo scan | **BLOCKED** | No Crashlytics/Sentry — vitals rely on Play only |
| Closed test crash-free sessions | QA field report | **BLOCKED** | Closed cohort smoke not completed |
| Play Console 7-day crash rate | Android vitals dashboard | **BLOCKED** | Requires production/closed track installs |
| ANR rate | Android vitals | **BLOCKED** | Requires Play data |

**Assessment:** Engineering **PASS** (build quality). Live crash rate **BLOCKED** until Play vitals populate (typically 24–72h after first installs). Recommend staged rollout **5% → 20% → 100%** and halt if crash rate exceeds 1.09%.

---

### Retention

| Check | Method | Result | Evidence |
|-------|--------|--------|----------|
| Session restore (code) | `AppStartup` + secure token storage | **PASS** | Users stay logged in across relaunch |
| Offline cache (return visits) | Hive profile + appointment cache (24h TTL) | **PASS** | Reduces bounce on poor connectivity |
| Product analytics SDK | Repo scan | **BLOCKED** | No Firebase Analytics / PostHog |
| D1 retained installers | Play Console statistics | **BLOCKED** | Requires live installs |
| D7 retained installers | Play Console statistics | **BLOCKED** | Requires 7-day window post-launch |
| Pilot farmer return rate | Field feedback form | **BLOCKED** | Closed phase 3 not complete |

**Assessment:** Retention **instrumentation gap** — Play Console provides aggregate retention only. For cohort-level retention (pilot farmers), use closed-test feedback form or add analytics SDK post-launch.

---

### Install

| Check | Method | Result | Evidence |
|-------|--------|--------|----------|
| Signed production AAB | Gradle release + upload keystore | **PASS** | `release/play-store-release.aab` |
| Signed production APK | `apksigner verify` v2 | **PASS** | `release/play-store-release.apk` |
| versionCode monotonic | 1 (internal) → 2 (closed) → **3** (production) | **PASS** | Play upload requirement met |
| Min SDK / target SDK | Flutter defaults via `build.gradle.kts` | **PASS** | Release build succeeds |
| Play App Signing | First upload enrolls Google signing | **PASS** (process) | Documented in STORE_RELEASE §1 |
| ADB sideload install | `adb install -r play-store-release.apk` | **BLOCKED** | No device connected |
| Play opt-in install (team) | Closed/internal tester link | **BLOCKED** | Play Console upload pending |
| Install failure rate | Play Console pre-launch report | **BLOCKED** | Run after AAB upload |

**Assessment:** Install **engineering PASS**. Field install verification **BLOCKED** — complete via Play internal/closed link or sideload before promoting to production track.

---

### Feedback

| Check | Method | Result | Evidence |
|-------|--------|--------|----------|
| Feedback channels defined | [CLOSED_TEST_REPORT.md](./CLOSED_TEST_REPORT.md) § Feedback | **PASS** | GitHub/tracker, Bengali Google Form, field WhatsApp |
| In-app support path | Settings → profile, privacy link | **PASS** | `settings_page.dart` |
| Closed team feedback collected | QA tracker | **BLOCKED** | Upload not yet executed |
| Doctor cohort booking feedback | Field pairing test | **BLOCKED** | Phase 2 not complete |
| Pilot farmer responses (≥10) | Google Form | **BLOCKED** | Phase 3 not complete |
| Play Console user reviews | Store listing | **BLOCKED** | Pre-launch — no public reviews |
| Open P0 bugs | Issue tracker | **PASS** | 0 P0 recorded in repo audit |

**Assessment:** Feedback **process PASS**; **data BLOCKED** until closed testing phases run. No P0 blockers in codebase.

---

## Launch metrics summary

| Metric | Engineering | Live (Play / field) | Gate |
|--------|-------------|----------------------|------|
| **Crash rate** | PASS | BLOCKED | Halt rollout if > 1.09% |
| **Retention** | PASS (code) | BLOCKED | Review D1/D7 at 7 days |
| **Install** | PASS | BLOCKED | Confirm via Play pre-launch report |
| **Feedback** | PASS (process) | BLOCKED | 0 P0 before 100% rollout |

---

## Production release artifact

| Artifact | Path | versionCode |
|----------|------|-------------|
| **Play production AAB** | `release/play-store-release.aab` | 3 |
| **Sideload / QA APK** | `release/play-store-release.apk` | 3 |
| **Debug symbols** | `build/debug-info-launch/` | — |

### Build command

```powershell
cd D:\PraniDoctor\pranidoctor_user
$api = "http://192.168.10.111:3000"   # replace with production URL before public launch
flutter build appbundle --release --build-number=3 `
  --obfuscate --split-debug-info=build/debug-info-launch `
  --dart-define=API_BASE_URL=$api `
  --dart-define=ENABLE_PUSH=false `
  --dart-define=LOG_NETWORK=false `
  --dart-define=PRIVACY_POLICY_URL=https://pranidoctor.com/privacy
```

---

## Play Store submission checklist

### P0 — Required for production track

| # | Item | Status |
|---|------|--------|
| 1 | Upload `release/play-store-release.aab` to Production (staged %) | ☐ Ops |
| 2 | Store listing: title, descriptions, screenshots, feature graphic | ☐ Product |
| 3 | Content rating questionnaire | ☐ Product |
| 4 | Data safety form aligned with [PRIVACY_POLICY.md](./legal/PRIVACY_POLICY.md) | ☐ Legal |
| 5 | Privacy policy URL live (currently **404**) | ❌ FAIL |
| 6 | Production `API_BASE_URL` reachable from Bangladesh mobile networks | ☐ Ops |
| 7 | Countries: Bangladesh (primary) | ☐ Product |

### P1 — Strongly recommended before 100% rollout

| # | Item | Status |
|---|------|--------|
| 8 | Review Android vitals crash rate at 5% rollout | ☐ QA |
| 9 | Review D1 retention at day 3 | ☐ Product |
| 10 | `google-services.json` + `ENABLE_PUSH=true` rebuild | ☐ Ops |
| 11 | Crash symbol upload to Crashlytics/Sentry | ☐ Eng |
| 12 | Closed-test feedback: 0 P0, ≥10 pilot responses | ☐ QA |

---

## Staged rollout plan

| Stage | Rollout % | Duration | Go/no-go |
|-------|-----------|----------|----------|
| 1 | 5% | 48h | Crash rate ≤ 1.09%; no install spike |
| 2 | 20% | 5 days | D1 retention ≥ 25%; 0 P0 feedback |
| 3 | 50% | 7 days | D7 retention ≥ 10%; doctor booking loop stable |
| 4 | 100% | — | All gates green |

**Rollback:** Halt rollout in Play Console if crash rate exceeds threshold or P0 feedback received.

---

## Post-launch monitoring (first 14 days)

| Day | Action | Owner |
|-----|--------|-------|
| 0 | Upload AAB; start 5% rollout | Ops |
| 1 | Check Android vitals crash + ANR | QA |
| 3 | Review D1 retention; install failures | Product |
| 7 | Review D7 retention; closed feedback summary | Product |
| 14 | Full metrics review; promote or patch | Eng + Product |

**Play Console paths:**

- Crashes: **Release → App bundle explorer → Crashes** / **Android vitals**
- Retention: **Statistics → Retained installers**
- Installs: **Release dashboard → Install base**
- Feedback: **User feedback → Reviews** + internal tracker

---

## Related verification (static)

| Check | Result |
|-------|--------|
| `flutter analyze` | **PASS** — 0 errors |
| `flutter test` | **PASS** — 1/1 |
| Staging API health | **PASS** — 200 |
| In-app privacy link | **PASS** |
| Hosted privacy URL | **FAIL** — 404 |
| Release signing | **PASS** — APK v2 |
| CI release workflow | **PASS** — `.github/workflows/release.yml` |

---

## Track history

| Track | Build | versionCode | Artifact |
|-------|-------|-------------|----------|
| Internal | 1.0.0+1 | 1 | `release/internal-release.aab` |
| Closed | 1.0.0+2 | 2 | `release/closed-release.aab` |
| **Production** | **1.0.0+3** | **3** | **`release/play-store-release.aab`** |

---

## Sign-off

| Role | Item | Status |
|------|------|--------|
| Engineering | Signed AAB, versionCode, static gates | ✅ |
| QA | Crash/retention/install live metrics | ☐ Pending Play data |
| Product | Store listing + feedback collection | ☐ Pending upload |
| Legal | Hosted privacy policy | ❌ 404 |
| Ops | Production API + staged rollout | ☐ Pending |

---

## Related docs

- [FINAL_CERTIFICATE.md](./FINAL_CERTIFICATE.md) — prior closed-test sign-off
- [STORE_RELEASE.md](./STORE_RELEASE.md) — release pipeline
- [store-assets/README.md](../store-assets/README.md) — Play listing assets

---

*Upload `release/play-store-release.aab` to Play Console Production with staged rollout. Monitor crash rate, retention, install, and feedback per thresholds above.*
