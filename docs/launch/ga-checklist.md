# GA Launch Checklist — Prani Doctor

**Document ID:** `GA_LAUNCH_CHECKLIST`  
**Version:** 1.0  
**Date:** 2026-06-01  
**Companion:** [general-availability-launch-plan.md](./general-availability-launch-plan.md)

Track GA readiness in admin **Launch Operations** (`/admin/launch-ops` → GA panel) via `launch.ga.config` gate checklist.

**APIs:** `GET/PATCH /api/admin/launch/ga-config` · `GET /api/admin/launch/ga-readiness` · `POST /api/admin/launch/ga-readiness` (gate review)

---

## Pre-GA platform (P0)

| ID | Item | Owner | Status | Evidence |
|----|------|-------|--------|----------|
| H1 | Production VPS + TLS | DevOps | ☐ | `curl https://api.<host>/ready` |
| H2 | Backup cron + offsite copy | DevOps | ☐ | File < 24h |
| H3 | Restore drill logged | DevOps | ☐ | Drill log |
| H4 | Deploy E2E + rollback tag | DevOps | ☐ | CI + tag |
| H5 | External uptime `/ready` + BFF | SRE | ☐ | Monitor green |
| H6 | Sentry + webhook live | SRE | ☐ | Test event |
| H7 | Load test 20 RPS pass | SRE | ☐ | k6 report |
| H8 | Migration validation ≥ 85 | DBA | ☐ | Validation report |

## Mobile & store (P0)

| ID | Item | Owner | Status | Evidence |
|----|------|-------|--------|----------|
| I1 | Firebase + FCM production | Mobile | ☐ | `ENABLE_PUSH=true` |
| I2 | Play production track | Mobile | ☐ | Play Console |
| I3 | Play Data Safety complete | Legal | ☐ | Console screenshot |
| I6 | Staged rollout configured | Mobile | ☐ | 10% initial |

## Compliance (P0)

| ID | Item | Owner | Status | Evidence |
|----|------|-------|--------|----------|
| J1 | Legal GA counsel sign-off | Legal | ☐ | External record |
| J2 | Live privacy/terms/refund 200 | Legal | ☐ | curl output |
| J3 | AI + emergency CMS EN+BN | Legal | ☐ | Admin screenshot |
| J5 | Marketing copy legal review | Legal | ☐ | Sign-off |

## Ecosystems (P0)

| ID | Item | Owner | Status | Evidence |
|----|------|-------|--------|----------|
| K1 | ≥ 15 doctors soft launch | Clinical ops | ☐ | Admin list |
| K4 | AI kill switch drill | AI ops | ☐ | Drill log |
| K6 | Emergency workflow E2E | QA | ☐ | Smoke report |
| L1 | 24/7 on-call roster | Launch lead | ☐ | Wiki |
| L4 | War room dry-run | Launch lead | ☐ | Tabletop notes |

## Beta exit (P0)

| ID | Item | Owner | Status | Evidence |
|----|------|-------|--------|----------|
| M1 | Beta SC-01–SC-10 met | Product | ☐ | [beta-success-metrics.md](./beta-success-metrics.md) |
| M2 | Closed beta disabled | Product | ☐ | `closedBeta.enabled=false` |
| M3 | Ops audit ≥ 85% | Auditor | ☐ | Re-audit report |
| M4 | Board GO vote | Board | ☐ | Minutes |

## P1 (soft launch waivers)

| ID | Item | Owner | Status |
|----|------|-------|--------|
| I4 | App Links | Mobile | ☐ |
| I5 | BN critical screens | Mobile | ☐ |
| L2 | Tiered SLA published | Support | ☐ |
| L3 | Payment reconciliation SOP | Product ops | ☐ |

---

## Go / No-Go

**GO** when all P0 pass + composite readiness ≥ **85%** + board sign-off.

| Role | Name | Date | Decision |
|------|------|------|----------|
| Launch lead | | | |
| SRE director | | | |
| Product ops | | | |
| Legal | | | |
| Board | | | |
