# OFFLINE_COMPLETE

**Project:** Prani Doctor User App (`pranidoctor_user`)  
**Status:** Gaps identified — run Composer command below to close  
**Audited:** 2026-05-22  
**Audit reference:** [OFFLINE_AUDIT.md](./OFFLINE_AUDIT.md)

---

## Completion checklist

| # | Concern | Status | Done |
|---|---------|--------|------|
| 1 | Cache (profile + list + area) | Shipped | ☑ |
| 2 | Cache (detail + discovery fallback) | Gap | ☐ |
| 3 | Retry (local backoff + server retry API) | Shipped | ☑ |
| 4 | Retry (per-item + dead-item cleanup) | Gap | ☐ |
| 5 | Sync (coordinator + dual queue drain) | Shipped | ☑ |
| 6 | Sync (versions + PROFILE via `/api/sync`) | Gap | ☐ |
| 7 | Offline queue (local UI) | Shipped | ☑ |
| 8 | Offline queue (server + conflicts UI) | Gap | ☐ |
| 9 | Reconnect (connectivity + login + timer) | Shipped | ☑ |
| 10 | Reconnect (manual offline + app resume) | Gap | ☐ |
| 11 | Conflict resolution (backend) | Shipped (backend) | ☑ |
| 12 | Conflict resolution (mobile UX) | Gap | ☐ |

---

## Gap implementation spec (gaps only — reuse existing code)

### G1 — Server queue + conflict visibility

**Reuse:** `OfflineRepository.getOfflineQueue()`, `OfflineQueueDto`, `OfflineQueuePanel`.

- Add `serverOfflineQueueProvider` fetching `GET /api/offline/queue`.
- Extend `OfflineQueuePanel` with sections: **On device** (local outbox) + **On server** (queued / failed / conflict).
- Show `conflictCount` from `getSyncStatus()`; add l10n for conflict state.
- Tap conflict row → bottom sheet with `resolution` / error + actions: **Retry**, **Discard** (call `retrySync` with key or document server-wins).

### G2 — Conflict versions + PROFILE sync path

**Reuse:** `SyncItemInput`, `SyncCoordinator`, `ProfileRepository`.

- On profile patch enqueue: include `clientVersion` (e.g. profile `updatedAt` or hash).
- Route `OutboxKind.profilePatch` through `POST /api/sync` with `entityType: PROFILE` instead of direct PATCH (or add versions to PATCH if backend supports).
- On `MERGE_REQUIRED` / `CONFLICT`: surface merge UI (server payload vs local) — minimal: show server wins message + reload profile.
- Pass `Idempotency-Key` header on outbox POST/PATCH matching `idempotencyKey`.

### G3 — Cache completeness

**Reuse:** `LocalCacheService`, `LocalCacheContract`.

- `getRequest(id)`: cache per-id key `service_requests:detail:{id}`; stale fallback like list.
- Optional: cache `serviceCategories` / doctor list with short TTL (reuse area pattern).
- Wire `auth_snapshot` write on session restore (non-sensitive fields only).

### G4 — Offline lead + entity alignment

**Reuse:** `OutboxKind.offlineLead`, `_syncOfflineLeadItem`.

- If product needs standalone lead capture: enqueue from planned offline lead form OR document as N/A.
- Otherwise remove dead `offlineLead` kind from UI labels until wired (avoid confusion).
- Do **not** implement `case_draft` / `voice_draft` unless phase docs require — mark deferred in audit.

### G5 — Reconnect hardening

**Reuse:** `ConnectivityService.setManualOverride`, `OfflineCoordinator`.

- Settings toggle: “Work offline” → `setManualOverride(true)`; show banner when manual offline.
- `WidgetsBindingObserver` in `OfflineCoordinator`: on `resumed` → `syncNow(background: true)`.

### G6 — Retry UX polish

**Reuse:** `outbox_service`, `retryDead`.

- “Retry” per local outbox row (reset `attemptCount`, clear `nextRetryAt`).
- Remove or archive dead items after max attempts (with confirm).
- Align local `offlineMaxAttempts` with backend `OFFLINE_MAX_RETRY_ATTEMPTS` (single constant source in comment or shared doc).

---

## Verification steps

1. **Cache:** Airplane mode → open Inbox (see cached list) → open appointment detail (cached after G3).
2. **Retry:** Force failed sync (invalid payload) → see backoff → Retry failed → item retries.
3. **Sync:** Book offline → Settings shows 1 pending → Sync now → inbox shows new request.
4. **Queue:** Server-side failed item (seed via API) → Settings shows server queue section.
5. **Reconnect:** Offline → online → sync runs without opening Settings.
6. **Conflict:** Simulate PROFILE version mismatch → conflict row + resolution message (not silent fail).

---

## ONE Cursor Composer command

Copy everything inside the block into **Cursor Composer** (one run).

```
@pranidoctor_user @pranidoctor-backend

Prani Doctor User App — Complete offline architecture (gaps only).

READ FIRST:
- docs/OFFLINE_AUDIT.md
- docs/OFFLINE_COMPLETE.md
- docs/PHASE_OFFLINE_COMPLETE.md (baseline already shipped)

RULES:
- Reuse existing Hive CacheStore, OutboxService, SyncCoordinator, OfflineCoordinator, OfflineRepository, DTOs.
- Do NOT introduce SQLite/Drift/Isar or a second sync framework.
- Verify code before changing; implement ONLY gaps G1–G6 in OFFLINE_COMPLETE.md.
- Match Riverpod patterns, l10n (app_en.arb), ApiResult, AppException, offlineQueuedCode UX.
- Backend changes only if required for mobile PROFILE/version or queue visibility; keep /api/sync contract stable.
- Minimal diffs; no unrelated feature work.

VERIFY (read code, confirm audit accurate):
- cache, retry, sync, offline queue, reconnect, conflict resolution

TASKS (in order):

1) AUDIT VERIFY — Update OFFLINE_AUDIT.md if drift found.

2) G1 — Server queue + conflicts in OfflineQueuePanel (merge local + GET /api/offline/queue; show conflictCount).

3) G2 — clientVersion/serverVersion on sync items; profile outbox via /api/sync PROFILE or versioned PATCH; Idempotency-Key header on drain.

4) G3 — Detail (and optional categories) cache fallback via LocalCacheService.

5) G4 — Either wire offline_lead enqueue from existing flow OR remove misleading offline lead label until wired (document choice).

6) G5 — Manual offline toggle in Settings; app resume sync in OfflineCoordinator.

7) G6 — Per-item retry + dead item dismiss on local outbox.

8) DOCS — Update OFFLINE_AUDIT.md status columns; mark checklist ☑ in OFFLINE_COMPLETE.md; add Shipped files table; set Status COMPLETE if all P0 done.

9) SMOKE — flutter analyze on touched files; note manual steps run.

OUTPUT (reply with exactly this structure):

## OFFLINE_COMPLETE

### Shipped
- bullets per G1–G6 with file paths

### Checklist
- table with Done ☑

### Verify
- manual steps performed

### Remaining
- None or blocked items
```

---

## Shipped files (populate after Composer run)

| Gap | Files |
|-----|-------|
| G1 | _pending_ |
| G2 | _pending_ |
| G3 | _pending_ |
| G4 | _pending_ |
| G5 | _pending_ |
| G6 | _pending_ |

---

## Reuse index (do not reimplement)

| Component | Path |
|-----------|------|
| Hive bootstrap | `lib/core/cache/hive_bootstrap.dart` |
| Outbox | `lib/features/offline/data/outbox_service.dart` |
| Sync | `lib/features/offline/data/sync_coordinator.dart` |
| Reconnect | `lib/features/offline/offline_coordinator.dart` |
| Transient + backoff | `lib/core/offline/network_errors.dart` |
| DTOs | `lib/core/offline/offline_dto.dart` |
| Backend conflict | `pranidoctor-backend/src/modules/offline-architecture/conflict/conflict-resolver.ts` |

---

*Run the Composer command above to reach full OFFLINE_COMPLETE status.*
