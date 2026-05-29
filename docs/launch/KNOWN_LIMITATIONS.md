# Known Limitations — Prani Doctor Launch

**Effective date:** 2026-05-29  
**Applies to:** Initial launch (pilot / closed beta / first production cutover)  
**Status context:** See [PRODUCTION_READINESS_REPORT.md](./PRODUCTION_READINESS_REPORT.md) — **NOT_READY_FOR_PRODUCTION** for public launch

This document lists **accepted and unresolved limitations** at verification time. Items marked **Launch blocker** must be resolved or waived before the corresponding launch tier.

---

## 1. Platform and infrastructure

| ID | Limitation | Impact | Launch tier | Mitigation |
|----|------------|--------|-------------|------------|
| L-01 | No production VPS/TLS verified in this audit | Users cannot reach HTTPS API/admin publicly | Public prod — **blocker** | Deploy nginx + Let's Encrypt per `docs/deployment/DEPLOY_RUNBOOK.md` |
| L-02 | Backup cron not installed on live host | Data loss risk on DB failure | Public prod — **blocker** | Run `install-backup-cron.sh`; drill restore |
| L-03 | Deploy pipeline not E2E tested with secrets | Manual deploy error risk | Public prod — **blocker** | Run staging deploy with `deploy_remote=true` |
| L-04 | API edge uses Next.js BFF interim ADR | Extra hop latency; dual route surface | All tiers | Monitor p95; plan Express cutover Phase 8 |
| L-05 | Legacy routes run via `tsx` in Docker | Larger runtime surface vs compiled bundle | Public prod — risk | Compile legacy pipeline (Phase 7 P1-13 deferred) |
| L-06 | No CDN for media | Slower image load outside Dhaka | Pilot OK | MinIO/S3 direct; add CDN at scale |
| L-07 | Single-VPS architecture | No HA during host failure | Pilot OK | Document RTO; plan second node at 500+ concurrent users |

---

## 2. Mobile app (Flutter)

| ID | Limitation | Impact | Launch tier | Mitigation |
|----|------------|--------|-------------|------------|
| L-10 | **Android only** — no iOS project | iPhone users excluded | All tiers | Product scope: Android-first; iOS Phase 8 |
| L-11 | Firebase not configured (`google-services.json` absent) | No FCM push in release unless disabled | Push-required launch — **blocker** | Add Firebase or ship `ENABLE_PUSH=false` |
| L-12 | ~430 Bengali keys still English in `bn.json` | Mixed-language UI on secondary screens | Pilot OK | Prioritize auth/home/service request BN copy |
| L-13 | 11 failing tests (mostly golden pixel diffs) | CI noise; possible undetected UI drift | Public prod — risk | Update goldens or waive with QA visual sign-off |
| L-14 | ~244 force-unwraps in presentation layer | Potential runtime crashes on bad API data | All tiers | Crash webhook + staged rollout; harden hot paths |
| L-15 | No certificate pinning | MITM possible on compromised devices | Pilot OK | Threat-model decision deferred |
| L-16 | Hive offline cache without TTL | Storage growth on long-running installs | Pilot OK | Document cache clear in support FAQ |
| L-17 | Deep links / App Links not verified on device | Marketing links may not open app | Marketing launch — risk | Add `assetlinks.json` + intent filter QA |

---

## 3. Backend API

| ID | Limitation | Impact | Launch tier | Mitigation |
|----|------------|--------|-------------|------------|
| L-20 | No payment gateway integration | Manual payment reconciliation | Marketplace launch | Ops SOP; admin billing status updates |
| L-21 | No virus scan on uploads | Malware upload risk | Public prod — risk | ClamAV sidecar or cloud AV (P1-12 deferred) |
| L-22 | Archived foundation test suite broken | CI noise | Dev only | Exclude or fix import path |
| L-23 | Dual JWT signing paths (legacy + foundation) | Rotation complexity | All tiers | Document rotation in security runbook |
| L-24 | Worker/BullMQ not split in prod compose | Heavy jobs share API CPU | Scale event — risk | Split worker container when queue depth grows |
| L-25 | No formal API `/v1` versioning | Breaking changes affect all clients | All tiers | Use `MINIMUM_APP_VERSION` force upgrade |

---

## 4. Admin and doctor panels

| ID | Limitation | Impact | Launch tier | Mitigation |
|----|------------|--------|-------------|------------|
| L-30 | No real-time doctor monitoring dashboard | Admin cannot see live doctor status grid | Pilot OK | Manual phone contact; Phase 3 gap deferred |
| L-31 | Technician HTML dashboard absent | Technicians use mobile/API only | Pilot OK | Scope: doctor + admin web for v1 |
| L-32 | Automated assignment rules not built | Admin must manually assign requests | Pilot OK | Train ops on assign-doctor flow |
| L-33 | Analytics: no PDF/Excel export | Ops exports CSV only | Pilot OK | Phase 05.1 backlog |
| L-34 | Analytics: no materialized snapshots | Heavy queries hit primary DB | Scale event | Read replica + cron when traffic grows |
| L-35 | Refund processing manual | Delayed farmer refunds | Paid consultations | Billing SOP + admin status updates |

---

## 5. Notifications and messaging

| ID | Limitation | Impact | Launch tier | Mitigation |
|----|------------|--------|-------------|------------|
| L-40 | Live SMS OTP not verified on prod provider | OTP may fail for real users | Public prod — **blocker** | Test `OTP_MODE=live` on staging with real numbers |
| L-41 | Push notifications require Firebase | No background alerts if FCM off | Engagement launch | In-app notifications still work |
| L-42 | No Statuspage integration | Manual status comms during outage | Public prod — risk | Email/WhatsApp stakeholder list |

---

## 6. Security and compliance

| ID | Limitation | Impact | Launch tier | Mitigation |
|----|------------|--------|-------------|------------|
| L-50 | Secrets in `.env` files only (no Vault) | Leak risk if host compromised | All tiers | Restrict SSH; rotate on incident |
| L-51 | No WAF at edge | Bot/abuse exposure | Public prod — risk | nginx rate limits + Redis fail-closed |
| L-52 | Legal pages on admin app host, not marketing domain | Play policy URL must match deployed host | Play launch | Point `PRIVACY_POLICY_URL` to live `/privacy` URL |
| L-53 | GDPR-style data export/delete not fully audited | Regulatory question for EU users | BD-only pilot OK | Privacy policy describes support-ticket deletion |
| L-54 | AI/veterinary disclaimers in-app but not legal-reviewed | Liability exposure | Public prod — risk | Legal review of `/legal/disclaimer` before marketing |

---

## 7. Monitoring and operations

| ID | Limitation | Impact | Launch tier | Mitigation |
|----|------------|--------|-------------|------------|
| L-60 | Sentry/webhook not confirmed live | Blind to prod crashes | Public prod — **blocker** | Send test exception after deploy |
| L-61 | No on-call roster in repo | Slow incident response | Public prod — **blocker** | Name primary + backup in team wiki |
| L-62 | No central log aggregator | Harder post-mortems | Pilot OK | SSH + `docker compose logs` initially |
| L-63 | Prometheus alerts defined but not scraped | No automated paging | Public prod — risk | Uptime Kuma on `/ready` minimum |

---

## 8. Product scope exclusions (v1)

The following are **intentionally out of scope** for first launch:

- iOS App Store release  
- In-app payment gateway (bKash/Nagad/card)  
- Enterprise panel marketing launch  
- AI technician full self-service marketplace at national scale  
- Real-time WebSocket admin doctor grid  
- Automated smart routing of service requests  

---

## Waiver process

To launch with an open limitation:

1. Product owner documents waiver ID, business reason, and expiry date.  
2. Engineering lead confirms monitoring/compensating control.  
3. Store waiver outside git (ops wiki or signed PDF).  
4. Revisit at 30-day post-launch review.

---

*Cross-reference: [GO_LIVE_CHECKLIST.md](./GO_LIVE_CHECKLIST.md) · [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md)*
